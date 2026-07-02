import 'package:flutter_riverpod/legacy.dart';

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
