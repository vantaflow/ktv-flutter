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

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.updDownloading)));
  await ref.read(updateServiceProvider).downloadAndInstall(info);
}
