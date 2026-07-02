import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../categories/category_prefs.dart';
import '../auth/auth_controller.dart';

/// Toutes les catégories LIVE du fournisseur (brutes, pour l'écran de gestion).
final liveCategoriesAllProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  return c.liveCategories();
});

/// Catégories LIVE visibles : override utilisateur sinon heuristique FR/Maroc/beIN.
final liveCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryVisibilityTickProvider);
  final cats = await ref.watch(liveCategoriesAllProvider.future);
  final prof = ref.watch(authControllerProvider);
  final ov = prof == null ? const <String, bool>{} : ref.read(prefsProvider).categoryVisibility(prof.id, CatSection.live.key);
  return cats.where((cat) => categoryVisible(catId: cat.id, name: cat.name, overrides: ov, heuristic: categoryAllowed)).toList();
});

final selectedLiveCategoryProvider = StateProvider<String?>((ref) => null);

final liveStreamsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  final cat = ref.watch(selectedLiveCategoryProvider);
  if (c == null || cat == null) return [];
  final list = await c.liveStreams(cat);
  return list.where((ch) => !isJunkChannel(ch.name)).toList();
});

/// Chaînes d'une catégorie donnée (pour le Guide TV), sans junk.
final channelsByCategoryProvider = FutureProvider.family<List<LiveChannel>, String>((ref, categoryId) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return const [];
  final list = await c.liveStreams(categoryId);
  return list.where((ch) => !isJunkChannel(ch.name)).toList();
});

/// EPG now/next d'une chaîne (chargé à la demande par carte, mis en cache Riverpod).
final shortEpgProvider = FutureProvider.family<List<EpgProgram>, String>((ref, streamId) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return const [];
  try {
    return await c.shortEpg(streamId);
  } catch (_) {
    return const [];
  }
});
