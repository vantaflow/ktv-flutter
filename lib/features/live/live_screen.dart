import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/async_view.dart';
import '../player/play_launcher.dart';
import 'live_channel_card.dart';
import 'live_providers.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});
  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(liveCategoriesProvider, (_, next) {
      final cats = next.asData?.value;
      if (cats != null && cats.isNotEmpty && ref.read(selectedLiveCategoryProvider) == null) {
        ref.read(selectedLiveCategoryProvider.notifier).state = cats.first.id;
      }
    });
    final cats = ref.watch(liveCategoriesProvider);
    final selected = ref.watch(selectedLiveCategoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Live TV', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        cats.when(
          loading: () => const SizedBox(height: 44),
          error: (_, _) => const SizedBox(height: 44),
          data: (list) => CategoryChips(
            categories: list,
            selectedId: selected,
            onSelect: (id) => ref.read(selectedLiveCategoryProvider.notifier).state = id,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AsyncView(
            value: ref.watch(liveStreamsProvider),
            emptyBuilder: () => const Center(child: Text('Aucune chaîne', style: TextStyle(color: Colors.white38))),
            data: (List<LiveChannel> channels) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: 0.78,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
              ),
              itemCount: channels.length,
              itemBuilder: (_, i) {
                final ch = channels[i];
                return LiveChannelCard(channel: ch, onTap: () => _play(ch));
              },
            ),
          ),
        ),
      ],
    );
  }

  void _play(LiveChannel ch) => PlayLauncher.live(context, ref, ch);
}
