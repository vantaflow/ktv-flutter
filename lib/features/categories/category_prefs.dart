import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';

/// Section de catalogue dont on gère les catégories.
enum CatSection { live, vod, series }

extension CatSectionX on CatSection {
  /// Clé de persistance (stable, ne pas traduire).
  String get key => switch (this) {
        CatSection.live => 'live',
        CatSection.vod => 'vod',
        CatSection.series => 'series',
      };

  String get label => switch (this) {
        CatSection.live => 'Live TV',
        CatSection.vod => 'Films',
        CatSection.series => 'Séries',
      };
}

/// Bumpé à chaque changement de visibilité → les providers de catégories
/// (filtrés) se reconstruisent et l'UI se rafraîchit.
final categoryVisibilityTickProvider = StateProvider<int>((ref) => 0);

/// Visibilité effective d'une catégorie : override utilisateur s'il existe,
/// sinon l'heuristique par défaut (FR/Maroc/beIN selon la section).
bool categoryVisible({
  required String catId,
  required String name,
  required Map<String, bool> overrides,
  required bool Function(String?) heuristic,
}) {
  return overrides[catId] ?? heuristic(name);
}

/// Applique l'ordre utilisateur [order] (liste d'ids) à [cats] : les catégories
/// listées passent en tête dans cet ordre ; les autres suivent en conservant
/// leur ordre d'origine (tri stable). [order] vide → [cats] inchangé.
List<Category> orderCategories(List<Category> cats, List<String> order) {
  if (order.isEmpty) return cats;
  final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
  final indexed = <(int, Category)>[
    for (var i = 0; i < cats.length; i++) (pos[cats[i].id] ?? (order.length + i), cats[i]),
  ];
  indexed.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final e in indexed) e.$2];
}
