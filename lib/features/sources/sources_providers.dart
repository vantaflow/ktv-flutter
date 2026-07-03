import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/source/catalog_source.dart';
import '../auth/auth_controller.dart';

/// Bumpé quand l'ensemble des sources activées change → recalcul des providers.
final sourcesTickProvider = StateProvider<int>((ref) => 0);

/// Profils (sources) participant au catalogue fusionné.
/// = la liste `enabled_sources` (∩ profils existants) ; si vide, la source active
/// seule (comportement historique). La source active est toujours placée en tête
/// (priorité pour le dédoublonnage / le failover).
final enabledProfilesProvider = Provider<List<XtreamProfile>>((ref) {
  ref.watch(sourcesTickProvider);
  final active = ref.watch(authControllerProvider);
  if (active == null) return const [];
  final prefs = ref.read(prefsProvider);
  final all = {for (final p in prefs.profiles()) p.id: p};
  final ids = prefs.enabledSourceIds().where(all.containsKey);
  // Source active toujours en tête (priorité), puis les autres sources activées.
  final ordered = [active.id, ...ids.where((id) => id != active.id)];
  return [for (final id in ordered) if (all[id] != null) all[id]!];
});

/// Fusion active = au moins 2 sources activées.
final multiSourceActiveProvider = Provider<bool>((ref) => ref.watch(enabledProfilesProvider).length > 1);

/// Instances `CatalogSource` des sources activées (fermées à la disposition).
final sourceInstancesProvider = Provider<Map<String, CatalogSource>>((ref) {
  final profs = ref.watch(enabledProfilesProvider);
  final map = {for (final p in profs) p.id: buildCatalogSource(p)};
  ref.onDispose(() {
    for (final s in map.values) {
      s.close();
    }
  });
  return map;
});
