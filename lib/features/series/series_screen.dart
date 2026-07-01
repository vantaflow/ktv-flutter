import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/widgets/category_chips.dart';
import '../../core/widgets/poster_card.dart';
import '../../core/widgets/async_view.dart';
import 'series_providers.dart';
import 'series_detail_sheet.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});
  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Séries', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        cats.when(
          loading: () => const SizedBox(height: 44),
          error: (_, _) => const SizedBox(height: 44),
          data: (list) => CategoryChips(
            categories: list,
            selectedId: selected,
            onSelect: (id) => ref.read(selectedSeriesCategoryProvider.notifier).state = id,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AsyncView(
            value: ref.watch(seriesListProvider),
            emptyBuilder: () => const Center(child: Text('Aucune série', style: TextStyle(color: Colors.white38))),
            data: (List<SeriesItem> series) => GridView.builder(
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
            ),
          ),
        ),
      ],
    );
  }

  void _open(SeriesItem s) => showSeriesDetail(context, s);
}
