import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../logic/text_utils.dart';

enum CatalogSort { recent, rating, name }

/// État de tri/filtre d'un catalogue (films ou séries).
class CatalogFilter {
  final CatalogSort sort;
  final double minRating; // 0 = tous
  final bool onlyHq; // 4K / UHD / HDR seulement
  const CatalogFilter({this.sort = CatalogSort.recent, this.minRating = 0, this.onlyHq = false});

  CatalogFilter copyWith({CatalogSort? sort, double? minRating, bool? onlyHq}) =>
      CatalogFilter(sort: sort ?? this.sort, minRating: minRating ?? this.minRating, onlyHq: onlyHq ?? this.onlyHq);
}

bool _isHq(String name) {
  final n = name.toLowerCase();
  return n.contains('4k') || n.contains('uhd') || n.contains('hdr') || n.contains('2160');
}

/// Applique tri + filtres à une liste, via des accesseurs (name/rating/added).
List<T> applyCatalogFilter<T>(
  List<T> items,
  CatalogFilter f, {
  required String Function(T) nameOf,
  required double Function(T) ratingOf,
  required int Function(T) addedOf,
}) {
  var out = items.where((e) => ratingOf(e) >= f.minRating).toList();
  if (f.onlyHq) out = out.where((e) => _isHq(nameOf(e))).toList();
  switch (f.sort) {
    case CatalogSort.recent:
      out.sort((a, b) => addedOf(b).compareTo(addedOf(a)));
    case CatalogSort.rating:
      out.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    case CatalogSort.name:
      out.sort((a, b) => cleanTitle(nameOf(a)).toLowerCase().compareTo(cleanTitle(nameOf(b)).toLowerCase()));
  }
  return out;
}

/// Barre de tri + filtres (note mini, 4K/HDR).
class FilterBar extends StatelessWidget {
  final CatalogFilter filter;
  final ValueChanged<CatalogFilter> onChanged;
  const FilterBar({super.key, required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // se dimensionne au contenu → collé à droite
      children: [
          _sortChip('Récents', CatalogSort.recent),
          const SizedBox(width: 6),
          _sortChip('Note', CatalogSort.rating),
          const SizedBox(width: 6),
          _sortChip('A→Z', CatalogSort.name),
          const _Sep(),
          for (final r in const [0.0, 6.0, 7.0, 8.0])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(r == 0 ? 'Toutes notes' : '${r.toStringAsFixed(0)}+'),
                selected: filter.minRating == r,
                selectedColor: KtvColors.accent,
                backgroundColor: KtvColors.panel2,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onChanged(filter.copyWith(minRating: r)),
              ),
            ),
          const _Sep(),
          FilterChip(
            label: const Text('4K / HDR'),
            selected: filter.onlyHq,
            selectedColor: KtvColors.accent,
            backgroundColor: KtvColors.panel2,
            visualDensity: VisualDensity.compact,
            onSelected: (v) => onChanged(filter.copyWith(onlyHq: v)),
          ),
        ],
    );
  }

  Widget _sortChip(String label, CatalogSort s) => ChoiceChip(
        label: Text(label),
        selected: filter.sort == s,
        selectedColor: KtvColors.accent,
        backgroundColor: KtvColors.panel2,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onChanged(filter.copyWith(sort: s)),
      );
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 10), color: KtvColors.line);
}
