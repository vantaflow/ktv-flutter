import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../../core/logic/merge_live.dart';
import '../categories/category_prefs.dart';
import '../auth/auth_controller.dart';
import '../parental/parental.dart';
import '../sources/sources_providers.dart';

/// Toutes les catégories LIVE du fournisseur (brutes, pour l'écran de gestion).
final liveCategoriesAllProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  return c.liveCategories();
});

/// Catalogue Live FUSIONNÉ de toutes les sources activées (≥2), dédoublonné.
/// Chaque source contribue ses chaînes visibles (visibilité + junk par source) ;
/// les doublons (tvg-id sinon nom normalisé) sont regroupés avec des `alts`
/// (sources de secours). Le parental (mode masquer) est appliqué ici.
final mergedLiveProvider = FutureProvider<MergedLive>((ref) async {
  ref.watch(categoryVisibilityTickProvider);
  final profs = ref.watch(enabledProfilesProvider);
  final instances = ref.watch(sourceInstancesProvider);
  final prefs = ref.read(prefsProvider);
  final items = <SourcedChannel>[];
  await Future.wait(profs.map((prof) async {
    final src = instances[prof.id];
    if (src == null) return;
    try {
      final cats = await src.liveCategories();
      final catName = {for (final c in cats) c.id: c.name};
      final ov = prefs.categoryVisibility(prof.id, CatSection.live.key);
      bool heur(String? n) => prof.isM3u ? true : categoryAllowed(n);
      for (final ch in await src.liveStreams()) {
        if (isJunkChannel(ch.name)) continue;
        final cn = catName[ch.categoryId] ?? '';
        if (!categoryVisible(catId: ch.categoryId, name: cn, overrides: ov, heuristic: heur)) continue;
        items.add((sourceId: prof.id, ch: ch, catName: cn));
      }
    } catch (_) {
      // Source injoignable → ignorée (les autres continuent).
    }
  }));
  final merged = mergeLive(items);
  final cfg = ref.watch(parentalConfigProvider);
  if (cfg.hideMode && !ref.watch(parentalUnlockedProvider)) {
    return MergedLive(
      merged.channels.where((c) => !cfg.channelLocked(c.streamId, catId: c.categoryId, name: c.name)).toList(),
      merged.categories.where((c) => !cfg.categoryLocked(CatSection.live.key, c.id, c.name)).toList(),
    );
  }
  return merged;
});

/// Toutes les catégories LIVE fusionnées (brutes, pour l'écran de gestion en
/// mode multi-sources).
final mergedLiveCategoriesAllProvider = FutureProvider<List<Category>>((ref) async {
  return (await ref.watch(mergedLiveProvider.future)).categories;
});

/// Catégories LIVE visibles : override utilisateur sinon heuristique FR/Maroc/beIN.
/// En mode multi-sources (≥2), renvoie les catégories fusionnées (visibilité +
/// ordre gérés au niveau fusionné via kMergedProfileId).
final liveCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  if (ref.watch(multiSourceActiveProvider)) {
    ref.watch(categoryVisibilityTickProvider);
    final cats = (await ref.watch(mergedLiveProvider.future)).categories;
    final prefs = ref.read(prefsProvider);
    final ov = prefs.categoryVisibility(kMergedProfileId, CatSection.live.key);
    final order = prefs.categoryOrder(kMergedProfileId, CatSection.live.key);
    final visible = cats.where((c) => ov[c.id] ?? true).toList();
    return orderCategories(visible, order);
  }
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
  final cat = ref.watch(selectedLiveCategoryProvider);
  if (cat == null) return [];
  // Multi-sources : chaînes fusionnées de la catégorie (filtres déjà appliqués).
  if (ref.watch(multiSourceActiveProvider)) {
    final m = await ref.watch(mergedLiveProvider.future);
    return m.channels.where((c) => c.categoryId == cat).toList();
  }
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final list = await c.liveStreams(cat);
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return list.where((ch) => !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
});

/// Toutes les chaînes qui exposent une archive (tv_archive) — pour la Rediffusion.
/// Indépendant du filtre de langue : le catch-up dépend de l'archive, pas de la langue.
final archiveChannelsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  if (ref.watch(multiSourceActiveProvider)) {
    final m = await ref.watch(mergedLiveProvider.future);
    return m.channels.where((ch) => ch.tvArchive).toList();
  }
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return const [];
  final all = await c.liveStreams();
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return all.where((ch) => ch.tvArchive && !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
});

/// Chaînes d'une catégorie donnée (pour le Guide TV), sans junk.
final channelsByCategoryProvider = FutureProvider.family<List<LiveChannel>, String>((ref, categoryId) async {
  if (ref.watch(multiSourceActiveProvider)) {
    final m = await ref.watch(mergedLiveProvider.future);
    return m.channels.where((ch) => ch.categoryId == categoryId).toList();
  }
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
