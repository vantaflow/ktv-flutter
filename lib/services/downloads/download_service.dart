import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/providers.dart';
import '../../core/platform.dart';
import '../../core/process/ffmpeg_locator.dart';

enum DownloadStatus { queued, downloading, done, error, canceled }

class DownloadJob {
  final String id;
  final String name;
  final String url;
  final String ext;
  final DownloadStatus status;
  final double progress; // 0..1
  final String? filePath;
  final bool remux; // capture via ffmpeg (flux timeshift/live) → .mp4 propre
  final int? durationSec; // durée à capturer (remux)

  const DownloadJob({
    required this.id,
    required this.name,
    required this.url,
    required this.ext,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.filePath,
    this.remux = false,
    this.durationSec,
  });

  DownloadJob copyWith({DownloadStatus? status, double? progress, String? filePath}) => DownloadJob(
        id: id,
        name: name,
        url: url,
        ext: ext,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        filePath: filePath ?? this.filePath,
        remux: remux,
        durationSec: durationSec,
      );
}

/// File de téléchargements séquentielle (1 connexion fournisseur à la fois).
class DownloadController extends Notifier<List<DownloadJob>> {
  final _dio = Dio();
  CancelToken? _current;
  Process? _ffProc;
  bool _running = false;
  int _seq = 0;

  @override
  List<DownloadJob> build() => [];

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^\w\-. À-ÿ]'), '_').trim();

  void enqueue({required String name, required String url, required String ext}) {
    state = [...state, DownloadJob(id: 'dl${++_seq}', name: name, url: url, ext: ext)];
    _pump();
  }

  /// Téléchargement d'un flux à durée bornée (rediffusion/timeshift) : sur desktop
  /// on capture via ffmpeg (remux → .mp4 propre) ; sur mobile, repli HTTP (.ts).
  void enqueueStream({required String name, required String url, required int durationSec}) {
    final desktop = kDesktop;
    state = [
      ...state,
      DownloadJob(
        id: 'dl${++_seq}',
        name: name,
        url: url,
        ext: desktop ? 'mp4' : 'ts',
        remux: desktop,
        durationSec: durationSec,
      )
    ];
    _pump();
  }

  Future<Directory> _folder() async {
    final custom = ref.read(prefsProvider).settingStr('downloadsDir');
    return custom.isNotEmpty
        ? (Directory(custom)..createSync(recursive: true))
        : (Directory('${(await getApplicationDocumentsDirectory()).path}/KTV Téléchargements')..createSync(recursive: true));
  }

  Future<void> _pump() async {
    if (_running) return;
    final next = state.where((j) => j.status == DownloadStatus.queued).firstOrNull;
    if (next == null) return;
    _running = true;
    _update(next.id, status: DownloadStatus.downloading);
    try {
      final folder = await _folder();
      final path = '${folder.path}/${_sanitize(next.name)}.${next.ext}';
      if (next.remux) {
        await _captureFfmpeg(next, path);
      } else {
        _current = CancelToken();
        await _dio.download(next.url, path, cancelToken: _current, onReceiveProgress: (r, t) {
          if (t > 0) _update(next.id, progress: r / t);
        });
        _update(next.id, status: DownloadStatus.done, progress: 1, filePath: path);
      }
    } on DioException catch (e) {
      _update(next.id, status: e.type == DioExceptionType.cancel ? DownloadStatus.canceled : DownloadStatus.error);
    } catch (_) {
      _update(next.id, status: DownloadStatus.error);
    } finally {
      _running = false;
      _current = null;
      _ffProc = null;
      _pump(); // enchaîne le suivant
    }
  }

  /// Capture le flux via ffmpeg (copie des flux → mp4) sur la durée du programme.
  Future<void> _captureFfmpeg(DownloadJob job, String path) async {
    final ff = await FfmpegLocator.path();
    if (ff == null) {
      // Pas de ffmpeg (ne devrait arriver que hors desktop) → repli HTTP en .ts.
      final tsPath = path.replaceAll(RegExp(r'\.mp4$'), '.ts');
      _current = CancelToken();
      await _dio.download(job.url, tsPath, cancelToken: _current, onReceiveProgress: (r, t) {
        if (t > 0) _update(job.id, progress: r / t);
      });
      _update(job.id, status: DownloadStatus.done, progress: 1, filePath: tsPath);
      return;
    }
    final dur = (job.durationSec ?? 0).toDouble();
    final proc = await Process.start(ff, [
      '-hide_banner', '-loglevel', 'error', '-user_agent', 'KTV',
      '-i', job.url,
      '-c', 'copy', '-bsf:a', 'aac_adtstoasc', '-movflags', '+faststart',
      if (dur > 0) ...['-t', '${dur.round()}'],
      '-progress', 'pipe:1', '-f', 'mp4', '-y', path,
    ]);
    _ffProc = proc;
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (dur > 0 && line.startsWith('out_time_us=')) {
        final us = int.tryParse(line.substring(12).trim()) ?? 0;
        _update(job.id, progress: (us / 1e6 / dur).clamp(0.0, 0.99));
      }
    });
    final code = await proc.exitCode;
    final ok = (code == 0 || File(path).existsSync()) && File(path).existsSync() && File(path).lengthSync() > 100000;
    _update(job.id, status: ok ? DownloadStatus.done : DownloadStatus.error, progress: ok ? 1 : 0, filePath: ok ? path : null);
  }

  void cancelCurrent() {
    _current?.cancel();
    final p = _ffProc;
    if (p != null) {
      try {
        p.stdin.write('q');
      } catch (_) {}
      Future.delayed(const Duration(seconds: 1), () { try { p.kill(); } catch (_) {} });
    }
  }

  /// Retire une entrée de la liste (annule d'abord si c'est le téléchargement courant).
  void remove(String id) {
    final j = state.where((e) => e.id == id).firstOrNull;
    if (j != null && j.status == DownloadStatus.downloading) cancelCurrent();
    state = [for (final e in state) if (e.id != id) e];
  }

  /// Vide les entrées terminées / échouées / annulées.
  void clearFinished() {
    state = [
      for (final e in state)
        if (e.status == DownloadStatus.queued || e.status == DownloadStatus.downloading) e
    ];
  }

  void _update(String id, {DownloadStatus? status, double? progress, String? filePath}) {
    state = [
      for (final j in state)
        if (j.id == id) j.copyWith(status: status, progress: progress, filePath: filePath) else j
    ];
  }
}

final downloadControllerProvider = NotifierProvider<DownloadController, List<DownloadJob>>(DownloadController.new);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
