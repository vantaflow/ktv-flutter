import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/version.dart';

class UpdateInfo {
  final String tag; // ex. "0.1.13"
  final String? assetUrl; // .zip pour la plateforme
  final String assetName;
  final String notes;
  final bool isNewer;
  const UpdateInfo({required this.tag, this.assetUrl, this.assetName = '', this.notes = '', required this.isNewer});
}

/// Vérifie les releases GitHub et télécharge l'archive de la nouvelle version.
/// (Installation manuelle : on révèle le .zip dans le Finder/Explorer — remplacer
/// un bundle en cours d'exécution automatiquement est trop risqué.)
class UpdateService {
  final Dio _dio = Dio();
  static const _repo = 'khalilbenaz/ktv-flutter';

  Future<UpdateInfo?> check() async {
    try {
      final r = await _dio.get(
        'https://api.github.com/repos/$_repo/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
      final data = r.data;
      if (data is! Map) return null;
      final tag = (data['tag_name'] ?? '').toString().replaceFirst('v', '');
      final notes = (data['body'] ?? '').toString();
      final assets = (data['assets'] as List?) ?? const [];
      // Cible l'artefact de la plateforme : APK universel sur Android, .zip sinon.
      final want = Platform.isAndroid ? 'android-universal' : (Platform.isMacOS ? 'macos' : 'windows');
      String? url;
      String name = '';
      for (final a in assets) {
        final n = (a is Map ? a['name'] : '').toString();
        if (n.toLowerCase().contains(want)) {
          url = (a as Map)['browser_download_url']?.toString();
          name = n;
          break;
        }
      }
      return UpdateInfo(tag: tag, assetUrl: url, assetName: name, notes: notes, isNewer: _isNewer(tag, kAppVersion));
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String remote, String local) {
    List<int> parts(String v) => v.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final a = parts(remote), b = parts(local);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Télécharge l'archive dans Téléchargements et renvoie son chemin.
  Future<String?> download(UpdateInfo info, {void Function(double)? onProgress}) async {
    if (info.assetUrl == null) return null;
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fallback = Platform.isAndroid ? 'KTV-update.apk' : 'KTV-update.zip';
      final path = '${dir.path}/${info.assetName.isEmpty ? fallback : info.assetName}';
      await _dio.download(info.assetUrl!, path, onReceiveProgress: (r, t) {
        if (t > 0) onProgress?.call(r / t);
      });
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Android : télécharge l'APK puis ouvre l'installateur système.
  Future<String?> downloadAndInstall(UpdateInfo info, {void Function(double)? onProgress}) async {
    final path = await download(info, onProgress: onProgress);
    if (path == null) return null;
    try {
      if (Platform.isAndroid) await OpenFilex.open(path);
    } catch (_) {}
    return path;
  }

  /// Révèle l'archive dans le Finder/Explorateur (repli si l'auto-install échoue).
  Future<void> reveal(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      }
    } catch (_) {}
  }

  /// Installe la MAJ desktop : extrait l'archive, remplace le bundle/dossier de
  /// l'app en cours puis la relance — via un script détaché qui attend d'abord
  /// la fermeture de l'app (on ne peut pas écraser un binaire en cours d'exécution).
  /// Renvoie true si le script a été lancé : l'app DOIT alors se fermer (exit).
  Future<bool> installUpdate(String archivePath) async {
    try {
      if (Platform.isMacOS) return await _installMacOS(archivePath);
      if (Platform.isWindows) return await _installWindows(archivePath);
    } catch (_) {}
    return false;
  }

  Future<bool> _installMacOS(String zipPath) async {
    final exe = Platform.resolvedExecutable; // …/KTV.app/Contents/MacOS/KTV
    const marker = '.app/';
    final i = exe.indexOf(marker);
    if (i < 0) return false;
    final bundle = exe.substring(0, i + marker.length - 1); // …/KTV.app
    final tmp = await Directory.systemTemp.createTemp('ktv_upd');
    // ditto : gère les archives produites par `ditto -c -k --keepParent` (CI).
    final ex = await Process.run('ditto', ['-x', '-k', zipPath, tmp.path]);
    if (ex.exitCode != 0) return false;
    String? newApp;
    for (final e in tmp.listSync()) {
      if (e.path.endsWith('.app')) {
        newApp = e.path;
        break;
      }
    }
    if (newApp == null) return false;
    final sh = '''#!/bin/bash
while pgrep -f "$bundle/Contents/MacOS/" >/dev/null 2>&1; do sleep 0.4; done
rm -rf "$bundle"
cp -R "$newApp" "$bundle"
xattr -dr com.apple.quarantine "$bundle" 2>/dev/null || true
codesign --force --deep -s - "$bundle" 2>/dev/null || true
sleep 0.4
open "$bundle"
rm -rf "${tmp.path}" 2>/dev/null || true
''';
    final sp = '${tmp.path}/ktv_install.sh';
    await File(sp).writeAsString(sh);
    await Process.run('chmod', ['+x', sp]);
    await Process.start('/bin/bash', [sp], mode: ProcessStartMode.detached);
    return true;
  }

  Future<bool> _installWindows(String zipPath) async {
    final exe = Platform.resolvedExecutable; // install\KTV.exe
    final appDir = File(exe).parent.path;
    final tmp = await Directory.systemTemp.createTemp('ktv_upd');
    final ex = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Expand-Archive -Force -LiteralPath "$zipPath" -DestinationPath "${tmp.path}"',
    ]);
    if (ex.exitCode != 0) return false;
    final bat = '''@echo off
:wait
tasklist /FI "IMAGENAME eq KTV.exe" 2>nul | find /I "KTV.exe" >nul && (timeout /t 1 /nobreak >nul & goto wait)
xcopy /E /I /Y "${tmp.path}\\*" "$appDir" >nul
start "" "$appDir\\KTV.exe"
rmdir /S /Q "${tmp.path}"
del "%~f0"
''';
    final bp = '${tmp.path}\\ktv_install.bat';
    await File(bp).writeAsString(bat);
    await Process.start('cmd', ['/c', bp], mode: ProcessStartMode.detached);
    return true;
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());
