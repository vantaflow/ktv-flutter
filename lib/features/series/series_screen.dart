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
import '../vod/vod_screen.dart' show kAllCatId;
import 'series_providers.dart';
import 'series_detail_sheet.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});
  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  CatalogFilter _filter = const CatalogFilter();
  @override
  Widget build(BuildContext context) {
    ref.listen(seriesCategoriesProvider, (_, next) {
      final cats = next.asData?.value;
      if (cats != null && cats.isNotEmpty && ref.read(selectedSeriesCategoryProvider) == null) {
        ref.read(selectedSeriesCategoryProvider.notifier).state = cats.first.id;
      }
    });
    final cats = ref.watch(seriesCategoriesProvider);
    final selected = ref.watch(selectedSeriesCategoryProvider);
    final prefs = ref.read(prefsProvider);
    final showFilters = prefs.settingBool('catalogFilters', true);
    final isAll = selected == kAllCatId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + (filtres dans l'espace vide à droite) + bouton afficher/masquer.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(children: [
            const Text('Séries', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(width: 16),
            IconButton(
              tooltip: showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
              icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list, color: showFilters ? KtvColors.accent : KtvColors.muted),
              onPressed: () async { await prefs.setSetting('catalogFilters', !showFilters); setState(() {}); },
            ),
            const SizedBox(width: 4),
            Expanded(child: showFilters ? FilterBar(filter: _filter, onChanged: (f) => setState(() => _filter = f)) : const SizedBox.shrink()),
          ]),
        ),
        cats.when(
          loading: () => const SizedBox(height: 44),
          error: (_, _) => const SizedBox(height: 44),
          data: (list) => CategoryChips(
            categories: [const Category(kAllCatId, '⭐ Toutes'), ...list],
            selectedId: selected,
            onSelect: (id) => ref.read(selectedSeriesCategoryProvider.notifier).state = id,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AsyncView(
            value: isAll ? ref.watch(allSeriesProvider) : ref.watch(seriesListProvider),
            emptyBuilder: () => const Center(child: Text('Aucune série', style: TextStyle(color: Colors.white38))),
            data: (List<SeriesItem> all) {
              final series = applyCatalogFilter(all, _filter, nameOf: (s) => s.name, ratingOf: (s) => s.rating, addedOf: (s) => s.lastModified);
              if (series.isEmpty) return const Center(child: Text('Aucune série pour ces filtres', style: TextStyle(color: Colors.white38)));
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                itemCount: series.length,
                itemBuilder: (_, i) {
                  final s = series[i];
                  return PosterCard(
                    title: s.name,
                    imageUrl: s.cover,
                    rating: s.rating,
                    width: 170,
                    onTap: () => _open(s),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(SeriesItem s) => showSeriesDetail(context, s);
}
