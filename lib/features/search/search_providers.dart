import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../auth/auth_controller.dart';
import '../live/live_providers.dart';
import '../parental/parental.dart';

/// Toutes les chaînes live (catégories FR, sans junk) — pour la recherche globale.
final allLiveProvider = FutureProvider<List<LiveChannel>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await ref.watch(liveCategoriesProvider.future);
  final ids = cats.map((e) => e.id).toSet();
  final all = await c.liveStreams();
  final cfg = ref.watch(parentalConfigProvider);
  final hide = cfg.hideMode && !ref.watch(parentalUnlockedProvider);
  return all.where((ch) => ids.contains(ch.categoryId) && !isJunkChannel(ch.name) && !(hide && cfg.channelLocked(ch.streamId, catId: ch.categoryId, name: ch.name))).toList();
});

/// Requête de recherche courante.
final searchQueryProvider = StateProvider<String>((ref) => '');
