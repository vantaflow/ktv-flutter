import 'package:dio/dio.dart';
import '../models/models.dart';
import '../m3u/m3u_parser.dart';
import 'catalog_source.dart';

/// Source M3U/M3U8 : télécharge et parse une playlist (chaînes Live uniquement).
/// Les catégories dérivent du `group-title`. Les IDs de chaîne sont des hachés
/// STABLES de l'URL (FNV-1a) → favoris/reprise/historique restent valides d'une
/// session à l'autre tant que l'URL de la chaîne ne change pas.
class M3uSource implements CatalogSource {
  final XtreamProfile profile;
  final Dio _dio;

  M3uSource(this.profile)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'User-Agent': 'KTV'},
          responseType: ResponseType.plain,
        ));

  static const _noGroup = '__m3u_nogroup__';

  Future<void>? _loading;
  List<Category> _cats = const [];
  List<LiveChannel> _channels = const [];
  final Map<String, String> _urlById = {}; // streamId → URL réelle

  /// Haché stable et déterministe (FNV-1a 32 bits) pour un id de chaîne.
  static String _stableId(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  Future<void> _ensure() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final r = await _dio.get<String>(profile.m3uUrl);
    final entries = parseM3u(r.data ?? '');
    final cats = <String, String>{}; // id → nom
    final channels = <LiveChannel>[];
    for (final e in entries) {
      final group = (e.group == null || e.group!.trim().isEmpty) ? _noGroup : e.group!.trim();
      cats.putIfAbsent(group, () => group == _noGroup ? 'Sans catégorie' : group);
      final id = _stableId(e.url);
      _urlById[id] = e.url;
      channels.add(LiveChannel(
        streamId: id,
        name: e.name,
        icon: (e.logo == null || e.logo!.isEmpty) ? null : e.logo,
        categoryId: group,
        epgChannelId: e.tvgId,
      ));
    }
    _cats = [for (final e in cats.entries) Category(e.key, e.value)];
    _channels = channels;
  }

  @override
  String get sourceId => profile.id;

  @override
  Future<UserInfo> authenticate() async =>
      const UserInfo(authOk: true, status: 'M3U', expDate: '', activeCons: 0, maxCons: 0, message: 'Playlist M3U');

  @override
  Future<List<Category>> liveCategories() async {
    await _ensure();
    return _cats;
  }

  @override
  Future<List<LiveChannel>> liveStreams([String? categoryId]) async {
    await _ensure();
    if (categoryId == null) return _channels;
    return _channels.where((c) => c.categoryId == categoryId).toList();
  }

  @override
  Future<List<EpgProgram>> shortEpg(String streamId, {int limit = 4}) async => const [];

  // Une playlist M3U ne porte pas de VOD/Séries structurés.
  @override
  Future<List<Category>> vodCategories() async => const [];
  @override
  Future<List<VodItem>> vodStreams([String? categoryId]) async => const [];
  @override
  Future<Map<String, dynamic>> vodInfo(String vodId) async => const {};
  @override
  Future<List<Category>> seriesCategories() async => const [];
  @override
  Future<List<SeriesItem>> seriesList([String? categoryId]) async => const [];
  @override
  Future<Map<String, List<Episode>>> seriesInfo(String seriesId) async => const {};

  @override
  String api(String params) => '';
  @override
  String live(String id, {String ext = 'ts'}) => _urlById[id] ?? '';
  @override
  String movie(String id, String ext) => _urlById[id] ?? '';
  @override
  String series(String id, String ext) => _urlById[id] ?? '';
  @override
  String timeshift(String id, int durMin, String startYmdHi, {String ext = 'ts'}) => '';
  @override
  String xmltv() => profile.epgUrl;

  @override
  void close() => _dio.close(force: true);
}
