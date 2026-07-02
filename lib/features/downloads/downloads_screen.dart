import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../services/downloads/download_service.dart';
import '../player/play_launcher.dart';

/// Écran dédié Téléchargements : état des téléchargements en cours (progression,
/// annulation) et liste des éléments terminés (lecture locale, révéler, retirer).
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  Future<String> _folder(WidgetRef ref) async {
    final custom = ref.read(prefsProvider).settingStr('downloadsDir');
    if (custom.isNotEmpty) return custom;
    return '${(await getApplicationDocumentsDirectory()).path}/KTV Téléchargements';
  }

  Future<void> _openFolder(WidgetRef ref) async {
    final dir = await _folder(ref);
    if (Platform.isMacOS) {
      await Process.run('open', [dir]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [dir]);
    } else {
      await Process.run('xdg-open', [dir]);
    }
  }

  Future<void> _reveal(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(downloadControllerProvider);
    final ctrl = ref.read(downloadControllerProvider.notifier);
    final active = jobs.where((j) => j.status == DownloadStatus.downloading || j.status == DownloadStatus.queued).toList();
    final finished = jobs.where((j) => j.status != DownloadStatus.downloading && j.status != DownloadStatus.queued).toList().reversed.toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Text('Téléchargements', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(onPressed: () => _openFolder(ref), icon: const Icon(Icons.folder_open, size: 18), label: const Text('Dossier')),
                if (finished.isNotEmpty)
                  TextButton.icon(onPressed: ctrl.clearFinished, icon: const Icon(Icons.clear_all, size: 18), label: const Text('Vider terminés')),
              ],
            ),
          ),
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun téléchargement.\nBouton ⬇ sur un film, un épisode ou une rediffusion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: KtvColors.muted),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      if (active.isNotEmpty) ...[
                        _sectionTitle('En cours (${active.length})'),
                        for (final j in active) _ActiveTile(job: j, onCancel: () => ctrl.remove(j.id)),
                        const SizedBox(height: 12),
                      ],
                      if (finished.isNotEmpty) ...[
                        _sectionTitle('Terminés (${finished.length})'),
                        for (final j in finished)
                          _FinishedTile(
                            job: j,
                            onPlay: j.filePath != null ? () => PlayLauncher.localFile(context, ref, j.name, j.filePath!) : null,
                            onReveal: j.filePath != null ? () => _reveal(j.filePath!) : null,
                            onRemove: () => ctrl.remove(j.id),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: KtvColors.accent2)),
      );
}

class _ActiveTile extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback onCancel;
  const _ActiveTile({required this.job, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final pct = job.status == DownloadStatus.downloading && job.progress > 0 ? '${(job.progress * 100).round()}%' : 'en file';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: KtvColors.panel2, borderRadius: BorderRadius.circular(10), border: Border.all(color: KtvColors.line)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: job.progress == 0 ? null : job.progress,
              minHeight: 4,
              backgroundColor: KtvColors.panel,
              valueColor: AlwaysStoppedAnimation(KtvColors.accent),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Text(pct, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
        IconButton(tooltip: 'Annuler', icon: Icon(Icons.close, size: 18, color: KtvColors.muted), onPressed: onCancel),
      ]),
    );
  }
}

class _FinishedTile extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback? onPlay;
  final VoidCallback? onReveal;
  final VoidCallback onRemove;
  const _FinishedTile({required this.job, this.onPlay, this.onReveal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final ok = job.status == DownloadStatus.done;
    final (icon, color, label) = switch (job.status) {
      DownloadStatus.done => (Icons.play_circle_fill, KtvColors.accent, null),
      DownloadStatus.error => (Icons.error_outline, KtvColors.rec, 'échec'),
      DownloadStatus.canceled => (Icons.cancel_outlined, KtvColors.muted, 'annulé'),
      _ => (Icons.help_outline, KtvColors.muted, null),
    };
    return InkWell(
      onTap: ok ? onPlay : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(color: KtvColors.panel2, borderRadius: BorderRadius.circular(10), border: Border.all(color: KtvColors.line)),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(label ?? (ok ? 'Téléchargé · appuyez pour lire' : ''), style: TextStyle(color: KtvColors.muted, fontSize: 11.5)),
            ]),
          ),
          if (onReveal != null)
            IconButton(tooltip: 'Révéler dans le dossier', icon: Icon(Icons.folder_open, size: 18, color: KtvColors.muted), onPressed: onReveal),
          IconButton(tooltip: 'Retirer de la liste', icon: Icon(Icons.delete_outline, size: 18, color: KtvColors.muted), onPressed: onRemove),
        ]),
      ),
    );
  }
}
