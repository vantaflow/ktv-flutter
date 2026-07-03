import '../models/models.dart';
import '../xtream/xtream_client.dart';
import '../xtream/xtream_urls.dart';
import 'catalog_source.dart';

/// Source Xtream : délègue au `XtreamClient` (catalogue) et à `XtreamUrls` (flux).
class XtreamSource implements CatalogSource {
  final XtreamProfile profile;
  final XtreamClient _client;
  final XtreamUrls _urls;

  XtreamSource(this.profile)
      : _client = XtreamClient(profile),
        _urls = XtreamUrls.of(profile);

  @override
  String get sourceId => profile.id;

  @override
  Future<UserInfo> authenticate() => _client.authenticate();
  @override
  Future<List<Category>> liveCategories() => _client.liveCategories();
  @override
  Future<List<LiveChannel>> liveStreams([String? categoryId]) => _client.liveStreams(categoryId);
  @override
  Future<List<EpgProgram>> shortEpg(String streamId, {int limit = 4}) => _client.shortEpg(streamId, limit: limit);
  @override
  Future<List<Category>> vodCategories() => _client.vodCategories();
  @override
  Future<List<VodItem>> vodStreams([String? categoryId]) => _client.vodStreams(categoryId);
  @override
  Future<Map<String, dynamic>> vodInfo(String vodId) => _client.vodInfo(vodId);
  @override
  Future<List<Category>> seriesCategories() => _client.seriesCategories();
  @override
  Future<List<SeriesItem>> seriesList([String? categoryId]) => _client.seriesList(categoryId);
  @override
  Future<Map<String, List<Episode>>> seriesInfo(String seriesId) => _client.seriesInfo(seriesId);

  @override
  String api(String params) => _urls.api(params);
  @override
  String live(String id, {String ext = 'ts'}) => _urls.live(id, ext: ext);
  @override
  String movie(String id, String ext) => _urls.movie(id, ext);
  @override
  String series(String id, String ext) => _urls.series(id, ext);
  @override
  String timeshift(String id, int durMin, String startYmdHi, {String ext = 'ts'}) =>
      _urls.timeshift(id, durMin, startYmdHi, ext: ext);
  @override
  String xmltv() => _urls.xmltv();

  @override
  void close() => _client.close();
}
