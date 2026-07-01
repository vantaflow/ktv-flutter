import '../models/models.dart';

/// Construction des URLs de flux Xtream (fichier dédié, testable).
class XtreamUrls {
  final String srv; // déjà normalisé (sans / final)
  final String usr;
  final String pwd;
  const XtreamUrls(this.srv, this.usr, this.pwd);

  factory XtreamUrls.of(XtreamProfile p) => XtreamUrls(p.srv, p.usr, p.pwd);

  String _enc(String s) => Uri.encodeComponent(s);

  String api(String params) =>
      '$srv/player_api.php?username=${_enc(usr)}&password=${_enc(pwd)}${params.isEmpty ? '' : '&$params'}';

  String live(String id, {String ext = 'ts'}) => '$srv/live/${_enc(usr)}/${_enc(pwd)}/$id.$ext';
  String movie(String id, String ext) => '$srv/movie/${_enc(usr)}/${_enc(pwd)}/$id.$ext';
  String series(String id, String ext) => '$srv/series/${_enc(usr)}/${_enc(pwd)}/$id.$ext';
  String xmltv() => '$srv/xmltv.php?username=${_enc(usr)}&password=${_enc(pwd)}';

  /// Catch-up / timeshift : {srv}/timeshift/{u}/{p}/{durMin}/{Y-m-d:H-i}/{id}.{ext}
  String timeshift(String id, int durMin, String startYmdHi, {String ext = 'ts'}) =>
      '$srv/timeshift/${_enc(usr)}/${_enc(pwd)}/$durMin/$startYmdHi/$id.$ext';
}
