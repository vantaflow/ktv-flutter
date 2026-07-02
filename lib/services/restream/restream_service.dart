import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/process/ffmpeg_locator.dart';
import '../../core/process/cloudflared_locator.dart';

enum RestreamStatus { idle, starting, live, error }

class RestreamState {
  final RestreamStatus status;
  final String name;
  final String? lanUrl;
  final String? localUrl; // relais local (127.0.0.1) pour la lecture locale partagée
  final String? publicUrl; // via cloudflared
  final String? error;
  const RestreamState({this.status = RestreamStatus.idle, this.name = '', this.lanUrl, this.localUrl, this.publicUrl, this.error});
  RestreamState copyWith({RestreamStatus? status, String? name, String? lanUrl, String? localUrl, String? publicUrl, String? error}) =>
      RestreamState(status: status ?? this.status, name: name ?? this.name, lanUrl: lanUrl ?? this.lanUrl, localUrl: localUrl ?? this.localUrl, publicUrl: publicUrl ?? this.publicUrl, error: error);
}

/// Re-diffuse le flux courant en HLS (ffmpeg) servi par un serveur HTTP local
/// (dart:io) sur le réseau local, avec tunnel Cloudflare optionnel (cloudflared).
class RestreamController extends Notifier<RestreamState> {
  Process? _ff;
  Process? _cf;
  HttpServer? _server;
  static const _port = 8709;

  @override
  RestreamState build() {
    ref.onDispose(_cleanup);
    return const RestreamState();
  }

  /// Résout cloudflared : binaire bundlé en priorité, sinon installation système.
  static Future<String?> _resolveCloudflared() async {
    final bundled = await CloudflaredLocator.path();
    if (bundled != null) return bundled;
    for (final p in ['/opt/homebrew/bin/cloudflared', '/usr/local/bin/cloudflared', '/usr/bin/cloudflared', 'C:/Program Files/cloudflared/cloudflared.exe']) {
      if (File(p).existsSync()) return p;
    }
    try {
      final r = Process.runSync(Platform.isWindows ? 'where' : 'which', ['cloudflared']);
      final out = (r.stdout as String).trim().split('\n').first.trim();
      if (out.isNotEmpty && File(out).existsSync()) return out;
    } catch (_) {}
    return null;
  }

  static Future<String?> _lanIp() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      // Préfère en0 / Wi-Fi, sinon la première non-loopback.
      for (final want in ['en0', 'wlan0', 'Wi-Fi', 'eth0']) {
        for (final i in ifaces) {
          if (i.name == want && i.addresses.isNotEmpty) return i.addresses.first.address;
        }
      }
      for (final i in ifaces) {
        for (final a in i.addresses) {
          if (!a.isLoopback) return a.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> start({required String name, required String url, bool tunnel = true}) async {
    await stop();
    final ff = await FfmpegLocator.path();
    if (ff == null) {
      state = state.copyWith(status: RestreamStatus.error, error: 'ffmpeg introuvable');
      return;
    }
    state = RestreamState(status: RestreamStatus.starting, name: name);
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/ktv_restream')..createSync(recursive: true);
      // vide l'ancien contenu
      for (final f in dir.listSync()) {
        try { f.deleteSync(); } catch (_) {}
      }

      _ff = await Process.start(ff, [
        '-hide_banner', '-loglevel', 'error', '-user_agent', 'KTV',
        '-i', url,
        '-c', 'copy', // PAS de aac_adtstoasc ici : c'est pour le MP4, ça casse le HLS/TS
        '-f', 'hls', '-hls_time', '4', '-hls_list_size', '6',
        '-hls_flags', 'delete_segments+append_list+omit_endlist',
        '-hls_segment_filename', '${dir.path}/seg%03d.ts',
        '${dir.path}/index.m3u8',
      ]);
      // Si ffmpeg s'arrête pendant la diffusion (souvent : limite de connexions du
      // fournisseur), on le signale au lieu de revenir silencieusement à l'état initial.
      _ff!.exitCode.then((code) {
        if (state.status == RestreamStatus.live || state.status == RestreamStatus.starting) {
          _cleanup();
          state = RestreamState(status: RestreamStatus.error, name: name, error: 'Flux interrompu (limite de connexions du fournisseur ?)');
        }
      });

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
      _server!.listen((req) => _serve(req, dir));

      // Attend que la playlist HLS soit réellement prête (≥ 1 segment) avant
      // d'annoncer « live » — sinon le player ouvrirait un flux vide.
      final ready = await _waitReady(dir);
      if (!ready) {
        if (state.status != RestreamStatus.error) {
          _cleanup();
          state = RestreamState(status: RestreamStatus.error, name: name, error: 'Le relais n\'a pas démarré à temps (connexion fournisseur ?)');
        }
        return;
      }

      final ip = await _lanIp();
      final lan = ip == null ? null : 'http://$ip:$_port/index.m3u8';
      state = RestreamState(status: RestreamStatus.live, name: name, lanUrl: lan, localUrl: 'http://127.0.0.1:$_port/index.m3u8');

      if (tunnel) _startTunnel();
    } catch (e) {
      state = RestreamState(status: RestreamStatus.error, name: name, error: '$e');
      await stop();
    }
  }

  Future<void> _startTunnel() async {
    final cf = await _resolveCloudflared();
    if (cf == null) return; // pas de cloudflared → LAN seulement
    Process.start(cf, ['tunnel', '--url', 'http://localhost:$_port', '--no-autoupdate']).then((p) {
      _cf = p;
      final re = RegExp(r'https://[a-z0-9-]+\.trycloudflare\.com');
      void scan(String s) {
        final m = re.firstMatch(s);
        if (m != null && state.status == RestreamStatus.live && state.publicUrl == null) {
          state = state.copyWith(publicUrl: '${m.group(0)}/index.m3u8');
        }
      }
      p.stdout.transform(const SystemEncoding().decoder).listen(scan);
      p.stderr.transform(const SystemEncoding().decoder).listen(scan);
    }).catchError((_) {});
  }

  /// Attend que la playlist référence ≥ 1 segment (~jusqu'à 15 s).
  Future<bool> _waitReady(Directory dir) async {
    final pl = File('${dir.path}/index.m3u8');
    for (var i = 0; i < 30; i++) {
      if (state.status == RestreamStatus.error) return false; // ffmpeg a échoué
      try {
        if (pl.existsSync() && pl.readAsStringSync().contains('.ts')) return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> _serve(HttpRequest req, Directory dir) async {
    try {
      final name = req.uri.pathSegments.isEmpty ? 'index.m3u8' : req.uri.pathSegments.last;
      final f = File('${dir.path}/$name');
      req.response.headers.set('Access-Control-Allow-Origin', '*');
      if (!f.existsSync()) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      req.response.headers.contentType = name.endsWith('.m3u8')
          ? ContentType('application', 'vnd.apple.mpegurl')
          : ContentType('video', 'mp2t');
      await req.response.addStream(f.openRead());
      await req.response.close();
    } catch (_) {
      try { await req.response.close(); } catch (_) {}
    }
  }

  Future<void> stop() async {
    _cleanup();
    state = const RestreamState();
  }

  void _cleanup() {
    try { _ff?.kill(); } catch (_) {}
    try { _cf?.kill(); } catch (_) {}
    try { _server?.close(force: true); } catch (_) {}
    _ff = null;
    _cf = null;
    _server = null;
  }
}

final restreamControllerProvider = NotifierProvider<RestreamController, RestreamState>(RestreamController.new);
