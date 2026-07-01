import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Extrait le binaire ffmpeg bundlé (asset) vers un emplacement exécutable et
/// renvoie son chemin. Nécessaire car un asset n'est pas exécutable en place.
/// (App non sandboxée → Process.start autorisé.)
class FfmpegLocator {
  static String? _cached;

  static Future<String?> path() async {
    if (_cached != null && File(_cached!).existsSync()) return _cached;
    try {
      final isWin = Platform.isWindows;
      final assetName = isWin ? 'assets/bin/ffmpeg.exe' : 'assets/bin/ffmpeg';
      final support = await getApplicationSupportDirectory();
      final exe = File('${support.path}/${isWin ? 'ffmpeg.exe' : 'ffmpeg'}');
      final data = await rootBundle.load(assetName);
      // Réécrit si absent ou taille différente.
      if (!exe.existsSync() || exe.lengthSync() != data.lengthInBytes) {
        await exe.writeAsBytes(data.buffer.asUint8List(), flush: true);
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', exe.path]);
        }
      }
      _cached = exe.path;
      return _cached;
    } catch (_) {
      return null;
    }
  }
}
