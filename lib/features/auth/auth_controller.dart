import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models/models.dart';
import '../../core/xtream/xtream_client.dart';
import '../../core/source/catalog_source.dart';
import '../../core/source/xtream_source.dart';
import '../../core/source/m3u_source.dart';

/// État d'authentification : profil (source) actif (null = déconnecté).
final authControllerProvider =
    NotifierProvider<AuthController, XtreamProfile?>(AuthController.new);

class AuthController extends Notifier<XtreamProfile?> {
  @override
  XtreamProfile? build() => ref.read(prefsProvider).activeProfile();

  /// Valide les identifiants Xtream, enregistre le profil et le rend actif.
  Future<UserInfo> login(String srv, String usr, String pwd) async {
    final prof = XtreamProfile.create(srv, usr, pwd);
    final client = XtreamClient(prof);
    try {
      final info = await client.authenticate();
      if (!info.authOk) {
        throw Exception('Identifiants refusés par le fournisseur.');
      }
      final prefs = ref.read(prefsProvider);
      await prefs.upsertProfile(prof);
      await prefs.setActive(prof.id);
      state = prof;
      return info;
    } finally {
      client.close();
    }
  }

  /// Valide une playlist M3U (télécharge + parse), l'enregistre et l'active.
  Future<void> loginM3u(String url, {String? label, String epgUrl = ''}) async {
    final prof = XtreamProfile.createM3u(url, label: label, epgUrl: epgUrl);
    final src = M3uSource(prof);
    try {
      final chans = await src.liveStreams();
      if (chans.isEmpty) {
        throw Exception('Playlist vide ou illisible.');
      }
      final prefs = ref.read(prefsProvider);
      await prefs.upsertProfile(prof);
      await prefs.setActive(prof.id);
      state = prof;
    } finally {
      src.close();
    }
  }

  /// Ajoute un compte Xtream (validé) SANS changer la source active
  /// (pour la fusion multi-sources depuis les Réglages).
  Future<void> addXtreamSource(String srv, String usr, String pwd) async {
    final prof = XtreamProfile.create(srv, usr, pwd);
    final client = XtreamClient(prof);
    try {
      final info = await client.authenticate();
      if (!info.authOk) throw Exception('Identifiants refusés par le fournisseur.');
      await ref.read(prefsProvider).upsertProfile(prof);
    } finally {
      client.close();
    }
  }

  /// Ajoute une playlist M3U (validée) SANS changer la source active.
  Future<void> addM3uSource(String url, {String? label, String epgUrl = ''}) async {
    final prof = XtreamProfile.createM3u(url, label: label, epgUrl: epgUrl);
    final src = M3uSource(prof);
    try {
      if ((await src.liveStreams()).isEmpty) throw Exception('Playlist vide ou illisible.');
      await ref.read(prefsProvider).upsertProfile(prof);
    } finally {
      src.close();
    }
  }

  Future<void> switchTo(XtreamProfile prof) async {
    await ref.read(prefsProvider).setActive(prof.id);
    state = prof;
  }

  Future<void> logout() async {
    await ref.read(prefsProvider).setActive(null);
    state = null;
  }

  Future<void> deleteProfile(String id) async {
    await ref.read(prefsProvider).removeProfile(id);
    if (state?.id == id) state = null;
  }
}

/// Construit la source de catalogue d'un profil (Xtream ou M3U).
CatalogSource buildCatalogSource(XtreamProfile prof) =>
    prof.isM3u ? M3uSource(prof) : XtreamSource(prof);

/// Source de catalogue liée au profil actif (recréée au changement de profil).
/// Historiquement nommé `xtreamClientProvider` — désormais une `CatalogSource`
/// (les noms de méthodes sont identiques, donc les consommateurs sont inchangés).
final xtreamClientProvider = Provider<CatalogSource?>((ref) {
  final prof = ref.watch(authControllerProvider);
  if (prof == null) return null;
  final src = buildCatalogSource(prof);
  ref.onDispose(src.close);
  return src;
});

/// Constructeur d'URLs de flux du profil actif = la même source (compat).
final xtreamUrlsProvider = Provider<CatalogSource?>((ref) => ref.watch(xtreamClientProvider));

/// Infos d'abonnement (statut, expiration, connexions…) du profil actif.
final userInfoProvider = FutureProvider<UserInfo?>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return null;
  try {
    return await c.authenticate();
  } catch (_) {
    return null;
  }
});
