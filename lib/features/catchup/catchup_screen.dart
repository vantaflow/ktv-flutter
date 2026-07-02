import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/async_view.dart';
import '../../services/epg/epg_providers.dart';
import '../live/live_providers.dart';
import '../player/play_launcher.dart';
import '../guide/epg_dialog.dart';
import '../../services/downloads/download_service.dart';
import '../../l10n/app_localizations.dart';

final _selectedCatchupCatProvider = StateProvider<String?>((ref) => null);
final _selectedCatchupChannelProvider = StateProvider<LiveChannel?>((ref) => null);

/// Profondeur d'archive parcourue (doit rester ≤ à la fenêtre passée du XMLTV).
const _archiveDays = 3;

/// Rediffusion / Catch-up : parcourir et rejouer les programmes passés des
/// chaînes qui exposent une archive (tv_archive). Master-détail : catégorie →
/// chaîne → programmes passés groupés par jour → rejouer via timeshift.
class CatchupScreen extends ConsumerWidget {
  const CatchupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(archiveChannelsProvider);
    // Catégories ACTIVES (visibilité + ordre de la config Live) — on n'affiche
    // en catch-up que celles-ci, croisées avec la présence de chaînes à archive.
    final visibleCats = ref.watch(liveCategoriesProvider).asData?.value ?? const <Category>[];
    final selectedCat = ref.watch(_selectedCatchupCatProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(L.of(context)!.catchupTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(L.of(context)!.catchupSubtitle, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
          ),
          Expanded(
            child: AsyncView<List<LiveChannel>>(
              value: archive,
              emptyBuilder: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(L.of(context)!.catchupNoArchive, textAlign: TextAlign.center, style: TextStyle(color: KtvColors.muted)),
                ),
              ),
              data: (channels) {
                // Catégories qui ont au moins une chaîne à archive.
                final archiveCatIds = channels.map((c) => c.categoryId).toSet();
                // On garde uniquement les catégories ACTIVES (config Live) qui en contiennent.
                final cats = visibleCats.where((c) => archiveCatIds.contains(c.id)).toList();
                final catIds = cats.map((c) => c.id).toList();
                if (cats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(L.of(context)!.catchupNoArchive, textAlign: TextAlign.center, style: TextStyle(color: KtvColors.muted)),
                    ),
                  );
                }
                // Auto-sélection de la 1re catégorie.
                final sel = (selectedCat != null && catIds.contains(selectedCat)) ? selectedCat : catIds.first;
                if (sel != selectedCat) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(_selectedCatchupCatProvider.notifier).state = sel;
                  });
                }
                final list = channels.where((c) => c.categoryId == sel).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryChips(
                      categories: cats,
                      selectedId: sel,
                      onSelect: (id) {
                        ref.read(_selectedCatchupCatProvider.notifier).state = id;
                        ref.read(_selectedCatchupChannelProvider.notifier).state = null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 280, child: _ChannelList(channels: list)),
                          VerticalDivider(width: 1, color: KtvColors.line),
                          const Expanded(child: _CatchupPrograms()),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  final List<LiveChannel> channels;
  const _ChannelList({required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedCatchupChannelProvider);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: channels.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: KtvColors.line),
      itemBuilder: (_, i) {
        final ch = channels[i];
        final active = ch.streamId == selected?.streamId;
        return InkWell(
          onTap: () => ref.read(_selectedCatchupChannelProvider.notifier).state = ch,
          child: Container(
            color: active ? KtvColors.panel2 : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (ch.icon != null && ch.icon!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.network(ch.icon!, width: 34, height: 24, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(width: 34)),
                ),
              Expanded(child: Text(ch.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? KtvColors.accent : KtvColors.txt))),
            ]),
          ),
        );
      },
    );
  }
}

class _CatchupPrograms extends ConsumerWidget {
  const _CatchupPrograms();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ch = ref.watch(_selectedCatchupChannelProvider);
    if (ch == null) {
      return Center(child: Text(L.of(context)!.catchupSelectChannel, style: TextStyle(color: KtvColors.muted)));
    }
    final index = ref.watch(epgIndexProvider).asData?.value;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final minStart = now - _archiveDays * 86400;
    final past = (index?.forChannel(ch) ?? const <EpgProgram>[])
        .where((p) => p.stop > 0 && p.stop <= now && p.start >= minStart)
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start)); // plus récent d'abord

    if (past.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(L.of(context)!.catchupNone(ch.name),
              textAlign: TextAlign.center, style: TextStyle(color: KtvColors.muted)),
        ),
      );
    }

    // Groupement par jour.
    final groups = <String, List<EpgProgram>>{};
    for (final p in past) {
      groups.putIfAbsent(_dayLabel(context, p.start), () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: KtvColors.accent2)),
          ),
          for (final p in entry.value) _ProgramTile(channel: ch, program: p),
        ],
      ],
    );
  }
}

class _ProgramTile extends ConsumerWidget {
  final LiveChannel channel;
  final EpgProgram program;
  const _ProgramTile({required this.channel, required this.program});

  void _download(BuildContext context, WidgetRef ref) {
    final url = PlayLauncher.timeshiftUrl(ref, channel, program);
    if (url == null) return;
    final title = program.title.isEmpty ? 'Programme' : program.title;
    final dur = (program.stop - program.start).clamp(60, 6 * 3600);
    ref.read(downloadControllerProvider.notifier).enqueueStream(
          name: '${channel.name} - $title (rediffusion)',
          url: url,
          durationSec: dur,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Téléchargement lancé : « $title » — Réglages → Téléchargements')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dur = epgDuration(program);
    return InkWell(
      onTap: () => PlayLauncher.timeshift(context, ref, channel, program),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: KtvColors.panel2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KtvColors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.replay, size: 20, color: KtvColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program.title.isEmpty ? 'Programme' : program.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${epgTime(program.start)} → ${epgTime(program.stop)}${dur.isEmpty ? '' : '  ·  $dur'}',
                      style: TextStyle(color: KtvColors.muted, fontSize: 11.5)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Télécharger la rediffusion',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.download_rounded, color: KtvColors.muted, size: 20),
              onPressed: () => _download(context, ref),
            ),
            Icon(Icons.play_arrow_rounded, color: KtvColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = ['janv.', 'févr.', 'mars', 'avril', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

String _dayLabel(BuildContext context, int startTs) {
  final d = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
  final today = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final ref = DateTime(today.year, today.month, today.day);
  final diff = ref.difference(day).inDays;
  if (diff == 0) return L.of(context)!.dayToday;
  if (diff == 1) return L.of(context)!.dayYesterday;
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}
