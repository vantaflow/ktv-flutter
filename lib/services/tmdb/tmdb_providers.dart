import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'tmdb_service.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService(ref.read(prefsProvider)));

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
