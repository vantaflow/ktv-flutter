import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../categories/category_prefs.dart';
import '../auth/auth_controller.dart';
import '../parental/parental.dart';

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
  final prefs = ref.read(prefsProvider);
  final ov = prof == null ? const <String, bool>{} : prefs.categoryVisibility(prof.id, CatSection.live.key);
  final order = prof == null ? const <String>[] : prefs.categoryOrder(prof.id, CatSection.live.key);
  // M3U : playlist déjà curatée → tout afficher par défaut (pas de filtre FR/Maroc/beIN).
  final heuristic = (prof?.isM3u ?? false) ? (String? _) => true : categoryAllowed;
  final visible = cats.where((cat) => categoryVisible(catId: cat.id, name: cat.name, overrides: ov, heuristic: heuristic)).toList();
  final ordered = orderCategories(visible, order);
  // Mode « masquer » : retire les catégories verrouillées tant que non déverrouillé.
  final cfg = ref.watch(parentalConfigProvider);
  if (cfg.hideMode && !ref.watch(parentalUnlockedProvider)) {
    return ordered.where((c) => !cfg.categoryLocked(CatSection.live.key, c.id, c.name)).toList();
  }
  return ordered;
});

final selectedLiveCategoryProvider = StateProvider<String?>((ref) => null);

final liveStreamsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  final cat = ref.watch(selectedLiveCategoryProvider);
  if (c == null || cat == null) return [];
  final list = await c.liveStreams(cat);
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return list.where((ch) => !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
});

/// Toutes les chaînes qui exposent une archive (tv_archive) — pour la Rediffusion.
/// Indépendant du filtre de langue : le catch-up dépend de l'archive, pas de la langue.
final archiveChannelsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return const [];
  final all = await c.liveStreams();
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return all.where((ch) => ch.tvArchive && !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
});

/// Chaînes d'une catégorie donnée (pour le Guide TV), sans junk.
final channelsByCategoryProvider = FutureProvider.family<List<LiveChannel>, String>((ref, categoryId) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return const [];
  final list = await c.liveStreams(categoryId);
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return list.where((ch) => !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
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
