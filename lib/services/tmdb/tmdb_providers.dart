import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers.dart';
import 'tmdb_service.dart';

/// Bumpé quand un réglage TMDB change → le service et les résultats mémoïsés
/// sont reconstruits.
final tmdbSettingsTickProvider = StateProvider<int>((ref) => 0);

/// Le service lit les Réglages : langue, clé perso et interrupteur étaient
/// écrits par l'écran Réglages mais relus par personne — les trois contrôles
/// n'avaient donc aucun effet.
final tmdbServiceProvider = Provider<TmdbService>((ref) {
  ref.watch(tmdbSettingsTickProvider);
  final prefs = ref.read(prefsProvider);
  return TmdbService(
    prefs,
    lang: prefs.settingStr('tmdbLang', 'fr-FR'),
    apiKey: prefs.settingStr('tmdbKey'),
    enabled: prefs.settingBool('tmdbEnabled', true),
  );
});

/// Recherche TMDB mémoïsée par (type, nom brut).
typedef TmdbQuery = ({String type, String name});
final tmdbSearchProvider = FutureProvider.family<Map<String, dynamic>?, TmdbQuery>((ref, q) async {
  return ref.read(tmdbServiceProvider).search(q.type, q.name);
});

/// Détails TMDB (synopsis long + casting) par (type, id).
typedef TmdbId = ({String type, int id});
final tmdbDetailsProvider = FutureProvider.family<Map<String, dynamic>?, TmdbId>((ref, q) async {
  return ref.read(tmdbServiceProvider).details(q.type, q.id);
});
