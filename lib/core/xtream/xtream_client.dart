import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';
import 'xtream_urls.dart';

/// Client HTTP Xtream (player_api.php). Une instance par profil actif.
class XtreamClient {
  final XtreamProfile profile;
  final XtreamUrls urls;
  final Dio _dio;

  XtreamClient(this.profile)
      : urls = XtreamUrls.of(profile),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'User-Agent': 'KTV'},
          responseType: ResponseType.json,
        ));

  Future<dynamic> _get(String params) async {
    final r = await _dio.get(urls.api(params));
    final data = r.data;
    if (data is String) {
      // Certains panels renvoient le JSON en text/plain : Dio ne le décode pas.
      // C'est notamment le cas de l'appel d'auth (base) sur certains fournisseurs,
      // d'où un « Non connecté » alors que le reste du catalogue charge bien.
      if (data.isEmpty) return null;
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<Map<String, dynamic>> _list(dynamic d) {
    if (d is List) return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return const [];
  }

  /// Authentifie et renvoie les infos utilisateur/abonnement.
  Future<UserInfo> authenticate() async {
    final d = await _get('');
    if (d is Map) return UserInfo.fromJson(Map<String, dynamic>.from(d));
    throw Exception('Réponse d\'authentification invalide');
  }

  Future<List<Category>> liveCategories() async =>
      _list(await _get('action=get_live_categories')).map(Category.fromJson).toList();
  Future<List<LiveChannel>> liveStreams([String? categoryId]) async => _list(
        await _get('action=get_live_streams${categoryId != null ? '&category_id=$categoryId' : ''}'),
      ).map(LiveChannel.fromJson).toList();

  /// EPG court (now/next) d'une chaîne live.
  Future<List<EpgProgram>> shortEpg(String streamId, {int limit = 4}) async {
    final d = await _get('action=get_short_epg&stream_id=$streamId&limit=$limit');
    if (d is Map && d['epg_listings'] is List) {
      return (d['epg_listings'] as List)
          .whereType<Map>()
          .map((e) => EpgProgram.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<List<Category>> vodCategories() async =>
      _list(await _get('action=get_vod_categories')).map(Category.fromJson).toList();
  Future<List<VodItem>> vodStreams([String? categoryId]) async => _list(
        await _get('action=get_vod_streams${categoryId != null ? '&category_id=$categoryId' : ''}'),
      ).map(VodItem.fromJson).toList();
  Future<Map<String, dynamic>> vodInfo(String vodId) async {
    final d = await _get('action=get_vod_info&vod_id=$vodId');
    return (d is Map) ? Map<String, dynamic>.from(d) : {};
  }

  Future<List<Category>> seriesCategories() async =>
      _list(await _get('action=get_series_categories')).map(Category.fromJson).toList();
  Future<List<SeriesItem>> seriesList([String? categoryId]) async => _list(
        await _get('action=get_series${categoryId != null ? '&category_id=$categoryId' : ''}'),
      ).map(SeriesItem.fromJson).toList();

  /// Épisodes d'une série, groupés par saison (clé = numéro de saison en String).
  Future<Map<String, List<Episode>>> seriesInfo(String seriesId) async {
    final d = await _get('action=get_series_info&series_id=$seriesId');
    final out = <String, List<Episode>>{};
    if (d is Map && d['episodes'] is Map) {
      final eps = Map<String, dynamic>.from(d['episodes']);
      for (final entry in eps.entries) {
        if (entry.value is List) {
          out[entry.key] = (entry.value as List)
              .whereType<Map>()
              .map((e) => Episode.fromJson(Map<String, dynamic>.from(e), entry.key))
              .toList();
        }
      }
    }
    return out;
  }

  void close() => _dio.close(force: true);
}
