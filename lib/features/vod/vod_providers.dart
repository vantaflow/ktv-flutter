import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../auth/auth_controller.dart';

/// Catégories VOD (filtrées « françaises » comme KTV).
final vodCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await c.vodCategories();
  return cats.where((cat) => frCategoryAllowed(cat.name)).toList();
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
