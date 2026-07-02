import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/version.dart';

/// Journalisation distante pour débogage (surtout Android TV, où on n'a pas la
/// console). Envoie les étapes de démarrage + erreurs au Worker ktv-sync `/log`,
/// lisibles en ligne : GET https://ktv-sync.khalilbenaz.workers.dev/log
class RemoteLog {
  static const _endpoint = 'https://ktv-sync.khalilbenaz.workers.dev/log';
  static final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));
  static late String _id;
  static late String _platform;
  static bool _sending = false;
  static final _pending = <String>[];

  static void init() {
    _id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    try {
      _platform = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      _platform = 'unknown';
    }
  }

  static void log(String msg) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    _pending.add('${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}  $msg');
    _flush();
  }

  static Future<void> _flush() async {
    if (_sending || _pending.isEmpty) return;
    _sending = true;
    final lines = List<String>.from(_pending);
    _pending.clear();
    try {
      await _dio.post(_endpoint, data: {'id': _id, 'model': _platform, 'version': kAppVersion, 'platform': _platform, 'lines': lines});
    } catch (_) {
      // On ne remet pas en file pour éviter une boucle si le réseau est coupé.
    } finally {
      _sending = false;
      if (_pending.isNotEmpty) _flush();
    }
  }
}
