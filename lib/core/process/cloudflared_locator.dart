import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Extrait le binaire cloudflared bundlé (asset) vers un emplacement exécutable.
/// Renvoie null si l'asset n'est pas présent (tunnel alors indisponible → LAN seul).
class CloudflaredLocator {
  static String? _cached;

  static Future<String?> path() async {
    if (_cached != null && File(_cached!).existsSync()) return _cached;
    try {
      final isWin = Platform.isWindows;
      final assetName = isWin ? 'assets/bin/cloudflared.exe' : 'assets/bin/cloudflared';
      final data = await rootBundle.load(assetName); // absent → lève, on renvoie null
      final support = await getApplicationSupportDirectory();
      final exe = File('${support.path}/${isWin ? 'cloudflared.exe' : 'cloudflared'}');
      if (!exe.existsSync() || exe.lengthSync() != data.lengthInBytes) {
        await exe.writeAsBytes(data.buffer.asUint8List(), flush: true);
        if (!isWin) await Process.run('chmod', ['+x', exe.path]);
      }
      _cached = exe.path;
      return _cached;
    } catch (_) {
      return null;
    }
  }
}
