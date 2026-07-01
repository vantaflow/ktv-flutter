import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../auth/auth_controller.dart';

final liveCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await c.liveCategories();
  return cats.where((cat) => categoryAllowed(cat.name)).toList();
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
