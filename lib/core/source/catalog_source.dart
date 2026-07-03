import '../models/models.dart';

/// Abstraction commune d'une source de catalogue (compte Xtream OU playlist M3U).
/// Les noms de méthodes calquent `XtreamClient`/`XtreamUrls` pour que les
/// providers/lecteur restent inchangés. Une source M3U ne fournit que du Live :
/// les méthodes VOD/Séries renvoient des listes vides.
abstract class CatalogSource {
  /// Identifiant stable de la source (= XtreamProfile.id).
  String get sourceId;

  // --- Catalogue (calqué sur XtreamClient) ---
  Future<UserInfo> authenticate();
  Future<List<Category>> liveCategories();
  Future<List<LiveChannel>> liveStreams([String? categoryId]);
  Future<List<EpgProgram>> shortEpg(String streamId, {int limit = 4});
  Future<List<Category>> vodCategories();
  Future<List<VodItem>> vodStreams([String? categoryId]);
  Future<Map<String, dynamic>> vodInfo(String vodId);
  Future<List<Category>> seriesCategories();
  Future<List<SeriesItem>> seriesList([String? categoryId]);
  Future<Map<String, List<Episode>>> seriesInfo(String seriesId);

  // --- URLs de flux (calqué sur XtreamUrls) ---
  String api(String params);
  String live(String id, {String ext = 'ts'});
  String movie(String id, String ext);
  String series(String id, String ext);
  String timeshift(String id, int durMin, String startYmdHi, {String ext = 'ts'});
  String xmltv();

  void close();
}
