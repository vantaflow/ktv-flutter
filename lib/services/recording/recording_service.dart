import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/process/ffmpeg_locator.dart';

enum RecStatus { scheduled, recording, done, error }

class Recording {
  final String id;
  final String name;
  final RecStatus status;
  final String? filePath;
  final int? startAt; // epoch ms — heure de début (programmée ou effective)
  const Recording({required this.id, required this.name, this.status = RecStatus.recording, this.filePath, this.startAt});
  Recording copyWith({RecStatus? status, String? filePath}) =>
      Recording(id: id, name: name, status: status ?? this.status, filePath: filePath ?? this.filePath, startAt: startAt);
}

/// Enregistrement d'un flux vers MP4 via ffmpeg. N'interfère PAS avec la lecture
/// (pas de verrou de connexion) → on peut regarder pendant qu'on enregistre.
/// `compress` = ré-encode 720p H264 (fichier bien plus léger) ; sinon copie brute.
/// App non sandboxée → Process autorisé.
class RecordingController extends Notifier<List<Recording>> {
  Process? _proc;
  String? _activeId;
  int _seq = 0;
  final _timers = <String, Timer>{};

  @override
  List<Recording> build() => [];

  bool get isRecording => _proc != null;
  int get activeCount => state.where((r) => r.status == RecStatus.recording).length;

  /// Programme un enregistrement à une heure future (arrêt auto après [durationSec]).
  void schedule({required String name, required String url, required DateTime at, int? durationSec, bool compress = true}) {
    final id = 'sch${++_seq}';
    final delay = at.difference(DateTime.now());
    state = [...state, Recording(id: id, name: name, status: RecStatus.scheduled, startAt: at.millisecondsSinceEpoch)];
    _timers[id] = Timer(delay.isNegative ? Duration.zero : delay, () async {
      _timers.remove(id);
      state = [for (final r in state) if (r.id != id) r]; // retire la programmation
      await start(name: name, url: url, durationSec: durationSec, compress: compress);
    });
  }

  void cancelScheduled(String id) {
    _timers.remove(id)?.cancel();
    state = [for (final r in state) if (r.id != id) r];
  }

  Future<String?> start({required String name, required String url, int? durationSec, bool compress = true}) async {
    if (_proc != null) return 'Un enregistrement est déjà en cours.';
    final ff = await FfmpegLocator.path();
    if (ff == null) return 'ffmpeg introuvable.';
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/KTV Enregistrements')..createSync(recursive: true);
    final safe = name.replaceAll(RegExp(r'[^\w\-. À-ÿ]'), '_').trim();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final path = '${folder.path}/${safe}_$stamp.mp4';
    final id = 'rec${++_seq}';
    try {
      _proc = await Process.start(ff, [
        '-hide_banner', '-loglevel', 'error',
        '-user_agent', 'KTV',
        '-i', url,
        // Compact = ré-encode 720p (léger) ; Original = copie brute (lourd mais rapide).
        if (compress) ...[
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '25', '-vf', "scale='min(1280,iw)':-2",
          '-c:a', 'aac', '-b:a', '128k',
        ] else ...[
          '-c', 'copy', '-bsf:a', 'aac_adtstoasc',
        ],
        '-movflags', '+faststart',
        if (durationSec != null && durationSec > 0) ...['-t', '$durationSec'],
        '-f', 'mp4', '-y', path,
      ]);
      _activeId = id;
      state = [...state, Recording(id: id, name: safe, status: RecStatus.recording, filePath: path, startAt: DateTime.now().millisecondsSinceEpoch)];
      _proc!.exitCode.then((code) {
        final ok = code == 0 || (File(path).existsSync() && File(path).lengthSync() > 1000);
        _finish(id, ok ? RecStatus.done : RecStatus.error);
      });
      return null;
    } catch (e) {
      _proc = null;
      _activeId = null;
      return 'Échec du démarrage : $e';
    }
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    // Libère l'état TOUT DE SUITE pour que l'UI/toggle se débloque (« déjà en cours »
    // sinon si le process met du temps à mourir). exitCode finalisera le statut.
    _proc = null;
    _activeId = null;
    try {
      p.stdin.write('q'); // arrêt propre ffmpeg
      await p.stdin.flush();
    } catch (_) {}
    // Filet de sécurité : si ffmpeg ne rend pas la main, on le tue.
    Future.delayed(const Duration(seconds: 2), () {
      try {
        p.kill(ProcessSignal.sigint);
      } catch (_) {}
    });
  }

  void _finish(String id, RecStatus status) {
    state = [for (final r in state) if (r.id == id) r.copyWith(status: status) else r];
    if (_activeId == id) {
      _proc = null;
      _activeId = null;
    }
  }
}

final recordingControllerProvider = NotifierProvider<RecordingController, List<Recording>>(RecordingController.new);
