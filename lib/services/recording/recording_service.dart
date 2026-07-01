import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/process/ffmpeg_locator.dart';
import '../../core/providers.dart';
import '../../core/connection/connection_lock.dart';

enum RecStatus { scheduled, recording, done, error }

class Recording {
  final String id;
  final String name;
  final RecStatus status;
  final String? filePath;
  final int? startAt; // epoch ms — heure de début programmée
  const Recording({required this.id, required this.name, this.status = RecStatus.recording, this.filePath, this.startAt});
  Recording copyWith({RecStatus? status, String? filePath}) =>
      Recording(id: id, name: name, status: status ?? this.status, filePath: filePath ?? this.filePath, startAt: startAt);
}

/// Enregistrement d'un flux vers MP4 via ffmpeg (-c copy). Respecte le verrou de
/// connexion unique (préempte la lecture). App non sandboxée → Process autorisé.
class RecordingController extends Notifier<List<Recording>> {
  Process? _proc;
  int _seq = 0;
  final _timers = <String, Timer>{};

  @override
  List<Recording> build() => [];

  bool get isRecording => _proc != null;

  /// Programme un enregistrement à une heure future (arrêt auto après [durationSec]).
  void schedule({required String name, required String url, required DateTime at, int? durationSec}) {
    final id = 'sch${++_seq}';
    final delay = at.difference(DateTime.now());
    state = [...state, Recording(id: id, name: name, status: RecStatus.scheduled, startAt: at.millisecondsSinceEpoch)];
    _timers[id] = Timer(delay.isNegative ? Duration.zero : delay, () async {
      _timers.remove(id);
      state = [for (final r in state) if (r.id != id) r]; // retire la programmation
      await start(name: name, url: url, durationSec: durationSec);
    });
  }

  void cancelScheduled(String id) {
    _timers.remove(id)?.cancel();
    state = [for (final r in state) if (r.id != id) r];
  }

  Future<String?> start({required String name, required String url, int? durationSec}) async {
    if (_proc != null) return 'Un enregistrement est déjà en cours.';
    final ff = await FfmpegLocator.path();
    if (ff == null) return 'ffmpeg introuvable.';
    // Préempte la lecture (1 connexion) et prend le verrou.
    ref.read(connectionLockProvider).acquire(ConnUse.recording, onPreempt: () {});
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
        '-c', 'copy', '-bsf:a', 'aac_adtstoasc',
        '-movflags', '+faststart',
        if (durationSec != null && durationSec > 0) ...['-t', '$durationSec'],
        '-f', 'mp4', '-y', path,
      ]);
      state = [...state, Recording(id: id, name: safe, filePath: path)];
      _proc!.exitCode.then((code) {
        _finish(id, code == 0 ? RecStatus.done : (File(path).existsSync() && File(path).lengthSync() > 0 ? RecStatus.done : RecStatus.error));
      });
      return null;
    } catch (e) {
      _release();
      return 'Échec du démarrage : $e';
    }
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    try {
      p.stdin.write('q'); // arrêt propre
      await p.stdin.flush();
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 2));
    try {
      p.kill(ProcessSignal.sigint);
    } catch (_) {}
  }

  void _finish(String id, RecStatus status) {
    state = [for (final r in state) if (r.id == id) r.copyWith(status: status) else r];
    _release();
  }

  void _release() {
    _proc = null;
    ref.read(connectionLockProvider).release(ConnUse.recording);
  }
}

final recordingControllerProvider = NotifierProvider<RecordingController, List<Recording>>(RecordingController.new);
