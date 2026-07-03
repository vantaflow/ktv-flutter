import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../categories/category_prefs.dart';
import '../parental/parental.dart';
import '../sources/sources_providers.dart';

/// Toutes les catégories Séries du fournisseur (brutes, pour l'écran de gestion).
final seriesCategoriesAllProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(vodSourceProvider);
  if (c == null) return [];
  return c.seriesCategories();
});

/// Catégories Séries visibles : override utilisateur sinon heuristique « françaises ».
final seriesCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryVisibilityTickProvider);
  final cats = await ref.watch(seriesCategoriesAllProvider.future);
  final prof = ref.watch(vodSourceProfileProvider);
  final prefs = ref.read(prefsProvider);
  final ov = prof == null ? const <String, bool>{} : prefs.categoryVisibility(prof.id, CatSection.series.key);
  final order = prof == null ? const <String>[] : prefs.categoryOrder(prof.id, CatSection.series.key);
  final visible = cats.where((cat) => categoryVisible(catId: cat.id, name: cat.name, overrides: ov, heuristic: frCategoryAllowed)).toList();
  final ordered = orderCategories(visible, order);
  final cfg = ref.watch(parentalConfigProvider);
  if (cfg.hideMode && !ref.watch(parentalUnlockedProvider)) {
    return ordered.where((c) => !cfg.categoryLocked(CatSection.series.key, c.id, c.name)).toList();
  }
  return ordered;
});

final selectedSeriesCategoryProvider = StateProvider<String?>((ref) => null);

final seriesListProvider = FutureProvider<List<SeriesItem>>((ref) async {
  final c = ref.watch(vodSourceProvider);
  final cat = ref.watch(selectedSeriesCategoryProvider);
  if (c == null || cat == null) return [];
  return c.seriesList(cat);
});

/// Épisodes d'une série (par saison), chargés à la demande.
final seriesInfoProvider =
    FutureProvider.family<Map<String, List<Episode>>, String>((ref, seriesId) async {
  final c = ref.watch(vodSourceProvider);
  if (c == null) return {};
  return c.seriesInfo(seriesId);
});
