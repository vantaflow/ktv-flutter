import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/async_view.dart';
import '../live/live_providers.dart';
import '../player/play_launcher.dart';

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

  String _time(int ts) {
    if (ts == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progs = ref.watch(shortEpgProvider(channel.streamId)).asData?.value ?? const <EpgProgram>[];
    return InkWell(
      onTap: () => PlayLauncher.live(context, ref, channel),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(channel.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: progs.isEmpty
                  ? const Text('—', style: TextStyle(color: KtvColors.muted))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: progs.take(4).map((p) {
                        final now = p.isNow;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: now ? KtvColors.accent.withValues(alpha: 0.18) : KtvColors.panel2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: now ? KtvColors.accent : KtvColors.line),
                          ),
                          child: Text(
                            '${_time(p.start)}  ${p.title}',
                            style: TextStyle(fontSize: 11.5, color: now ? KtvColors.accent2 : KtvColors.txt),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
