import 'package:dio/dio.dart';
import '../../core/logic/text_utils.dart';
import '../../core/storage/prefs_store.dart';

const _api = 'https://api.trakt.tv';
const _oob = 'urn:ietf:wg:oauth:2.0:oob';

/// Client Trakt : OAuth device flow, refresh, scrobble (marquer vu), pull watched.
/// Réplique la logique de l'app Electron (lib/trakt-client.js).
class TraktService {
  final PrefsStore _prefs;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));
  TraktService(this._prefs);

  String get _clientId => _prefs.settingStr('traktClientId');
  String get _secret => _prefs.settingStr('traktSecret');
  bool get connected => _prefs.traktConnected;

  Map<String, dynamic> _headers() {
    final t = _prefs.traktToken();
    final h = {'Content-Type': 'application/json', 'trakt-api-version': '2', 'trakt-api-key': _clientId};
    final at = t?['access_token'];
    if (at != null) h['Authorization'] = 'Bearer $at';
    return h;
  }

  /// Étape 1 : demande un code d'appariement (device flow).
  Future<Map<String, dynamic>> requestDeviceCode() async {
    final r = await _dio.post('$_api/oauth/device/code',
        data: {'client_id': _clientId}, options: Options(headers: {'Content-Type': 'application/json'}));
    return Map<String, dynamic>.from(r.data);
  }

  /// Étape 2 : échange le device_code contre un token (à appeler en boucle).
  /// Renvoie true si connecté, false si en attente (autoriser à réessayer).
  Future<bool> pollDeviceToken(String deviceCode) async {
    try {
      final r = await _dio.post('$_api/oauth/device/token',
          data: {'code': deviceCode, 'client_id': _clientId, 'client_secret': _secret},
          options: Options(headers: {'Content-Type': 'application/json'}, validateStatus: (_) => true));
      if (r.statusCode == 200 && r.data is Map) {
        final tok = Map<String, dynamic>.from(r.data);
        tok['obtained_at'] = DateTime.now().millisecondsSinceEpoch;
        await _prefs.setTraktToken(tok);
        return true;
      }
      return false; // 400 = en attente d'autorisation
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refresh() async {
    final t = _prefs.traktToken();
    final rt = t?['refresh_token'];
    if (rt == null || _clientId.isEmpty) return false;
    try {
      final r = await _dio.post('$_api/oauth/token',
          data: {'refresh_token': rt, 'client_id': _clientId, 'client_secret': _secret, 'grant_type': 'refresh_token', 'redirect_uri': _oob},
          options: Options(headers: {'Content-Type': 'application/json'}, validateStatus: (_) => true));
      if (r.statusCode == 200 && r.data is Map) {
        final tok = Map<String, dynamic>.from(r.data);
        tok['obtained_at'] = DateTime.now().millisecondsSinceEpoch;
        await _prefs.setTraktToken(tok);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Response?> _req(String path, {String method = 'GET', Object? body}) async {
    if (!connected) return null;
    Future<Response> call() => _dio.request('$_api$path',
        data: body, options: Options(method: method, headers: _headers(), validateStatus: (_) => true));
    var r = await call();
    if (r.statusCode == 401 && await _refresh()) r = await call();
    return r;
  }

  Future<void> disconnect() => _prefs.setTraktToken(null);

  /// Renvoie un access_token FRAIS (rafraîchit via refresh_token si expiré).
  /// null si non connecté ou si le refresh échoue → reconnexion device requise.
  Future<String?> freshAccessToken() async {
    if (!connected) return null;
    final r = await _req('/users/settings'); // _req rafraîchit tout seul sur 401
    if (r?.statusCode == 200) {
      return _prefs.traktToken()?['access_token']?.toString();
    }
    return null;
  }

  /// Marque un film comme vu (par titre + année ; Trakt fait le matching).
  Future<void> markMovieWatched(String rawName) async {
    final title = cleanTitle(rawName);
    final year = yearOf(rawName);
    await _req('/sync/history', method: 'POST', body: {
      'movies': [
        {'title': title, if (year.isNotEmpty) 'year': int.tryParse(year)}
      ]
    });
  }

  /// Retire un film de l'historique vu (par titre + année).
  Future<void> unmarkMovieWatched(String rawName) async {
    final title = cleanTitle(rawName);
    final year = yearOf(rawName);
    await _req('/sync/history/remove', method: 'POST', body: {
      'movies': [
        {'title': title, if (year.isNotEmpty) 'year': int.tryParse(year)}
      ]
    });
  }

  /// Marque un épisode de série comme vu (titre série + saison + n° épisode).
  Future<void> markEpisodeWatched(String showRawName, int season, int number) async {
    final title = cleanTitle(showRawName);
    final year = yearOf(showRawName);
    await _req('/sync/history', method: 'POST', body: {
      'shows': [
        {
          'title': title,
          if (year.isNotEmpty) 'year': int.tryParse(year),
          'seasons': [
            {'number': season, 'episodes': [{'number': number}]}
          ]
        }
      ]
    });
  }

  /// Watchlist Trakt (films OU séries) → suggestions {title, year, ids} pour le
  /// matching catalogue. [type] = 'movies' | 'shows'.
  Future<List<Map<String, dynamic>>> watchlist(String type) async {
    final r = await _req('/sync/watchlist/$type');
    if (r?.statusCode != 200 || r?.data is! List) return [];
    final key = type == 'shows' ? 'show' : 'movie';
    final out = <Map<String, dynamic>>[];
    for (final it in (r!.data as List)) {
      final m = (it is Map) ? it[key] : null;
      if (m is Map && m['title'] != null) {
        final ids = (m['ids'] is Map) ? Map<String, dynamic>.from(m['ids']) : <String, dynamic>{};
        out.add({'title': m['title'].toString(), 'year': m['year'], 'ids': {'tmdb': ids['tmdb']}});
      }
    }
    return out;
  }

  /// Récupère les films vus sur Trakt (clé titre|année) pour marquer le catalogue.
  Future<Set<String>> pullWatchedMovieKeys() async {
    final r = await _req('/sync/watched/movies');
    if (r?.statusCode != 200 || r?.data is! List) return {};
    final keys = <String>{};
    for (final it in (r!.data as List)) {
      final m = (it is Map) ? it['movie'] : null;
      if (m is Map && m['title'] != null) {
        keys.add('${cleanTitle(m['title'].toString()).toLowerCase()}|${m['year'] ?? ''}');
      }
    }
    return keys;
  }
}
