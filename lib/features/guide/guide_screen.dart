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
import 'epg_dialog.dart';

final _selectedGuideCatProvider = StateProvider<String?>((ref) => null);

/// Guide TV : par catégorie, une ligne par chaîne avec sa grille EPG (en cours + à venir).
class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(liveCategoriesProvider, (_, next) {
      final cats = next.asData?.value;
      if (cats != null && cats.isNotEmpty && ref.read(_selectedGuideCatProvider) == null) {
        ref.read(_selectedGuideCatProvider.notifier).state = cats.first.id;
      }
    });
    final cats = ref.watch(liveCategoriesProvider);
    final selected = ref.watch(_selectedGuideCatProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Guide TV', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          cats.when(
            loading: () => const SizedBox(height: 44),
            error: (_, _) => const SizedBox(height: 44),
            data: (list) => CategoryChips(
              categories: list,
              selectedId: selected,
              onSelect: (id) => ref.read(_selectedGuideCatProvider.notifier).state = id,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selected == null
                ? const SizedBox()
                : AsyncView<List<LiveChannel>>(
                    value: ref.watch(channelsByCategoryProvider(selected)),
                    emptyBuilder: () => const Center(child: Text('Aucune chaîne', style: TextStyle(color: KtvColors.muted))),
                    data: (channels) => ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: channels.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: KtvColors.line),
                      itemBuilder: (_, i) => _GuideRow(channel: channels[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends ConsumerWidget {
  final LiveChannel channel;
  const _GuideRow({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(epgIndexProvider).asData?.value;
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final all = index?.forChannel(channel) ?? const <EpgProgram>[];
    // Programmes à partir de maintenant (en cours + à venir).
    final progs = all.where((p) => p.stop > t).toList();
    final now = progs.isNotEmpty && progs.first.isNow ? progs.first : null;
    final upcoming = (now != null ? progs.skip(1) : progs).take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: InkWell(
              onTap: () => PlayLauncher.live(context, ref, channel),
              child: Row(children: [
                if (channel.icon != null && channel.icon!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(channel.icon!, width: 30, height: 22, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                Expanded(child: Text(channel.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: progs.isEmpty
                ? const Text('—', style: TextStyle(color: KtvColors.muted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Programme en cours : titre + horaires + description (cliquable).
                      if (now != null)
                        InkWell(
                          onTap: () => showEpgProgram(context, channel.name, now),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.fiber_manual_record, size: 10, color: KtvColors.rec),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(now.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: KtvColors.accent2))),
                                  Text('${epgTime(now.start)}–${epgTime(now.stop)}', style: const TextStyle(fontSize: 11, color: KtvColors.muted)),
                                ]),
                                if (now.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 15),
                                    child: Text(now.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: KtvColors.muted, height: 1.3)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      // À suivre : puces horaire + titre (cliquables).
                      if (upcoming.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: upcoming.map((p) => InkWell(
                                onTap: () => showEpgProgram(context, channel.name, p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: KtvColors.panel2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: KtvColors.line),
                                  ),
                                  child: Text('${epgTime(p.start)}  ${p.title}', style: const TextStyle(fontSize: 11.5, color: KtvColors.txt)),
                                ),
                              )).toList(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
