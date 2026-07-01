import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/poster_card.dart';
import '../../core/widgets/async_view.dart';
import '../../core/providers.dart';
import 'movie_detail_sheet.dart';
import 'vod_providers.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});
  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  @override
  Widget build(BuildContext context) {
    // Auto-sélection de la 1re catégorie.
    ref.listen(vodCategoriesProvider, (_, next) {
      final cats = next.asData?.value;
      if (cats != null && cats.isNotEmpty && ref.read(selectedVodCategoryProvider) == null) {
        ref.read(selectedVodCategoryProvider.notifier).state = cats.first.id;
      }
    });
    final cats = ref.watch(vodCategoriesProvider);
    final selected = ref.watch(selectedVodCategoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Films', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        cats.when(
          loading: () => const SizedBox(height: 44),
          error: (_, _) => const SizedBox(height: 44),
          data: (list) => CategoryChips(
            categories: list,
            selectedId: selected,
            onSelect: (id) => ref.read(selectedVodCategoryProvider.notifier).state = id,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AsyncView(
            value: ref.watch(vodStreamsProvider),
            emptyBuilder: () => const Center(child: Text('Aucun film', style: TextStyle(color: Colors.white38))),
            data: (List<VodItem> movies) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                childAspectRatio: 0.52,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
              ),
              itemCount: movies.length,
              itemBuilder: (_, i) {
                final m = movies[i];
                final prefs = ref.read(prefsProvider);
                final key = 'movie:${m.streamId}';
                final r = prefs.resume(key);
                final dur = (r?['d'] as num?)?.toDouble() ?? 0;
                final t = (r?['t'] as num?)?.toDouble() ?? 0;
                return PosterCard(
                  title: m.name,
                  imageUrl: m.cover,
                  rating: m.rating,
                  watched: prefs.isWatched(key),
                  progress: dur > 0 ? (t / dur) : 0,
                  width: 170,
                  onTap: () => _play(m),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _play(VodItem m) => showMovieDetail(context, m);
}
