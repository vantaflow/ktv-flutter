import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../auth/auth_controller.dart';

final seriesCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await c.seriesCategories();
  return cats.where((cat) => frCategoryAllowed(cat.name)).toList();
});

final selectedSeriesCategoryProvider = StateProvider<String?>((ref) => null);

final seriesListProvider = FutureProvider<List<SeriesItem>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  final cat = ref.watch(selectedSeriesCategoryProvider);
  if (c == null || cat == null) return [];
  return c.seriesList(cat);
});

/// Épisodes d'une série (par saison), chargés à la demande.
final seriesInfoProvider =
    FutureProvider.family<Map<String, List<Episode>>, String>((ref, seriesId) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return {};
  return c.seriesInfo(seriesId);
});
