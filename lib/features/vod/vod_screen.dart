import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/poster_card.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../home/home_providers.dart';
import 'movie_detail_sheet.dart';
import 'vod_providers.dart';

const kAllCatId = '__all__';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});
  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  CatalogFilter _filter = const CatalogFilter();
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
    final prefs = ref.read(prefsProvider);
    final showFilters = prefs.settingBool('catalogFilters', true);
    final isAll = selected == kAllCatId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Films', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        // Catégories + bouton filtres à droite (en haut).
        Row(children: [
          Expanded(
            child: cats.when(
              loading: () => const SizedBox(height: 44),
              error: (_, _) => const SizedBox(height: 44),
              data: (list) => CategoryChips(
                categories: [const Category(kAllCatId, '⭐ Toutes'), ...list],
                selectedId: selected,
                onSelect: (id) => ref.read(selectedVodCategoryProvider.notifier).state = id,
              ),
            ),
          ),
          IconButton(
            tooltip: showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
            icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list, color: showFilters ? KtvColors.accent : KtvColors.muted),
            onPressed: () async { await prefs.setSetting('catalogFilters', !showFilters); setState(() {}); },
          ),
          const SizedBox(width: 8),
        ]),
        if (showFilters) ...[
          const SizedBox(height: 6),
          FilterBar(filter: _filter, onChanged: (f) => setState(() => _filter = f)),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: AsyncView(
            value: isAll ? ref.watch(allVodProvider) : ref.watch(vodStreamsProvider),
            emptyBuilder: () => const Center(child: Text('Aucun film', style: TextStyle(color: Colors.white38))),
            data: (List<VodItem> all) {
              final movies = applyCatalogFilter(all, _filter, nameOf: (m) => m.name, ratingOf: (m) => m.rating, addedOf: (m) => m.added);
              if (movies.isEmpty) return const Center(child: Text('Aucun film pour ces filtres', style: TextStyle(color: Colors.white38)));
              return GridView.builder(
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _play(VodItem m) => showMovieDetail(context, m);
}
