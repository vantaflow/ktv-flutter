import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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
      final want = Platform.isMacOS ? 'macos' : 'windows';
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
      final path = '${dir.path}/${info.assetName.isEmpty ? 'KTV-update.zip' : info.assetName}';
      await _dio.download(info.assetUrl!, path, onReceiveProgress: (r, t) {
        if (t > 0) onProgress?.call(r / t);
      });
      return path;
    } catch (_) {
      return null;
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());
