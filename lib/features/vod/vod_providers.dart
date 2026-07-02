import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../categories/category_prefs.dart';
import '../auth/auth_controller.dart';

/// Toutes les catégories VOD du fournisseur (brutes, pour l'écran de gestion).
final vodCategoriesAllProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  return c.vodCategories();
});

/// Catégories VOD visibles : override utilisateur sinon heuristique « françaises ».
final vodCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryVisibilityTickProvider);
  final cats = await ref.watch(vodCategoriesAllProvider.future);
  final prof = ref.watch(authControllerProvider);
  final ov = prof == null ? const <String, bool>{} : ref.read(prefsProvider).categoryVisibility(prof.id, CatSection.vod.key);
  return cats.where((cat) => categoryVisible(catId: cat.id, name: cat.name, overrides: ov, heuristic: frCategoryAllowed)).toList();
});

/// Catégorie sélectionnée (null tant que non initialisée).
final selectedVodCategoryProvider = StateProvider<String?>((ref) => null);

/// Films de la catégorie sélectionnée.
final vodStreamsProvider = FutureProvider<List<VodItem>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  final cat = ref.watch(selectedVodCategoryProvider);
  if (c == null || cat == null) return [];
  return c.vodStreams(cat);
});
