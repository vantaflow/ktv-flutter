import 'package:dio/dio.dart';
import '../../core/logic/text_utils.dart';
import '../../core/logic/tmdb_match.dart';
import '../../core/storage/prefs_store.dart';

const _tmdbImg = 'https://image.tmdb.org/t/p/';

/// Enrichissement TMDB (affiche/backdrop/synopsis) via le proxy KTV (token côté
/// serveur) ou une clé v4 perso. Réplique la logique de l'app Electron (fr-FR +
/// ktvPickResult seuil 60 + cache 30 j).
class TmdbService {
  final PrefsStore _prefs;
  final String _proxy;
  final String _lang;
  final String _key;
  final bool _enabled;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)));

  TmdbService(
    this._prefs, {
    String proxy = 'https://ktv-tmdb.khalilbenaz.workers.dev',
    String lang = 'fr-FR',
    String apiKey = '',
    bool enabled = true,
  })  : _proxy = proxy,
        _lang = lang,
        _key = apiKey.trim(),
        _enabled = enabled;

  static String img(String? path, {String size = 'w500'}) => (path == null || path.isEmpty) ? '' : '$_tmdbImg$size$path';

  /// Le cache est indexé par langue : sans ça, basculer TMDB en anglais
  /// continuait de servir les synopsis français mémorisés pour 30 jours.
  String _ck(String key) => '$_lang|$key';

  /// Appel TMDB : proxy KTV par défaut (jeton côté serveur), ou API officielle
  /// dès qu'une clé perso est saisie dans les Réglages — v4 (jeton `eyJ…`,
  /// en-tête Bearer) comme v3 (paramètre `api_key`).
  Future<Map<String, dynamic>?> _get(String pathQ) async {
    if (!_enabled) return null;
    final sep = pathQ.contains('?') ? '&' : '?';
    final own = _key.isNotEmpty;
    final v4 = own && _key.startsWith('eyJ');
    final base = own ? 'https://api.themoviedb.org' : _proxy;
    final auth = own && !v4 ? '&api_key=$_key' : '';
    final url = '$base/3$pathQ$sep' 'language=$_lang$auth';
    final r = await _dio.get(url, options: v4 ? Options(headers: {'Authorization': 'Bearer $_key'}) : null);
    return (r.data is Map) ? Map<String, dynamic>.from(r.data) : null;
  }

  /// Cherche le meilleur résultat TMDB pour un titre VOD/série (type 'movie'|'tv').
  /// Renvoie {id, poster_path, backdrop_path, overview, vote_average, title, year} ou null.
  Future<Map<String, dynamic>?> search(String type, String rawName) async {
    if (!_enabled) return null;
    final title = cleanTitle(rawName);
    final year = yearOf(rawName);
    final ck = _ck('s|$type|$title|$year');
    final cached = _prefs.tmdbCacheGet(ck);
    if (!identical(cached, PrefsStore.sentinelMissing)) {
      return cached == null ? null : Map<String, dynamic>.from(cached as Map);
    }
    Map<String, dynamic>? best;
    try {
      final q = Uri.encodeQueryComponent(title);
      final d = await _get('/search/$type?query=$q${year.isNotEmpty ? '&year=$year' : ''}');
      final results = (d?['results'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      best = ktvPickResult(results, title, year.isEmpty ? null : year);
    } catch (_) {
      best = null;
    }
    await _prefs.tmdbCacheSet(ck, best);
    return best;
  }

  /// Titres recommandés/similaires TMDB pour un id (résultats bruts).
  Future<List<Map<String, dynamic>>> recommendations(String type, int id) async {
    if (!_enabled) return [];
    final ck = _ck('r|$type|$id');
    final cached = _prefs.tmdbCacheGet(ck);
    if (!identical(cached, PrefsStore.sentinelMissing)) {
      return (cached as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    }
    List<Map<String, dynamic>> v = [];
    try {
      final d = await _get('/$type/$id/recommendations');
      v = (d?['results'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (_) {
      v = [];
    }
    await _prefs.tmdbCacheSet(ck, v);
    return v;
  }

  /// Tendances de la semaine (fallback quand aucun seed de recommandation).
  Future<List<Map<String, dynamic>>> trending(String type) async {
    if (!_enabled) return [];
    final ck = _ck('t|$type');
    final cached = _prefs.tmdbCacheGet(ck);
    if (!identical(cached, PrefsStore.sentinelMissing)) {
      return (cached as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    }
    List<Map<String, dynamic>> v = [];
    try {
      final d = await _get('/trending/$type/week');
      v = (d?['results'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (_) {
      v = [];
    }
    await _prefs.tmdbCacheSet(ck, v);
    return v;
  }

  /// Détails complets (synopsis long, genres, casting) pour un id.
  Future<Map<String, dynamic>?> details(String type, int id) async {
    if (!_enabled) return null;
    final ck = _ck('d|$type|$id');
    final cached = _prefs.tmdbCacheGet(ck);
    if (!identical(cached, PrefsStore.sentinelMissing)) {
      return cached == null ? null : Map<String, dynamic>.from(cached as Map);
    }
    Map<String, dynamic>? v;
    try {
      v = await _get('/$type/$id?append_to_response=credits');
    } catch (_) {
      v = null;
    }
    await _prefs.tmdbCacheSet(ck, v);
    return v;
  }
}
