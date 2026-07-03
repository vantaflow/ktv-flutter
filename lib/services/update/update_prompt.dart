import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/version.dart';
import '../../l10n/app_localizations.dart';
import 'update_service.dart';

/// Vérifie une nouvelle version au démarrage (si activé) et propose la mise à
/// jour. Android : télécharge l'APK + ouvre l'installateur. Desktop : télécharge
/// l'archive et la révèle.
Future<void> checkAndPromptUpdate(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(prefsProvider);
  if (!prefs.settingBool('autoUpdateCheck', true)) return;
  final info = await ref.read(updateServiceProvider).check();
  if (info == null || !info.isNewer || info.assetUrl == null) return;
  if (!context.mounted) return;

  final l = L.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: KtvColors.panel,
      title: Text(l.updTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.updBody(info.tag, kAppVersion), style: TextStyle(color: KtvColors.txt)),
          if (info.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160, maxWidth: 420),
              child: SingleChildScrollView(child: Text(info.notes.trim(), style: TextStyle(color: KtvColors.muted, fontSize: 12.5))),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.updLater)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.updNow)),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  final svc = ref.read(updateServiceProvider);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.updDownloading)));

  // Android : télécharge l'APK + ouvre l'installateur système.
  if (Platform.isAndroid) {
    await svc.downloadAndInstall(info);
    return;
  }

  // Desktop : télécharge puis installe automatiquement (swap + relance).
  final path = await svc.download(info);
  if (path == null) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.sDownloadErr)));
    return;
  }
  final ok = await svc.installUpdate(path);
  if (ok) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.updInstalling)));
    await Future.delayed(const Duration(milliseconds: 500));
    exit(0); // le script détaché attend cette fermeture, remplace l'app puis relance
  } else {
    await svc.reveal(path); // repli : révéler l'archive
  }
}
