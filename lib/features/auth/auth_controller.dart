import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models/models.dart';
import '../../core/xtream/xtream_client.dart';
import '../../core/xtream/xtream_urls.dart';

/// État d'authentification : profil Xtream actif (null = déconnecté).
final authControllerProvider =
    NotifierProvider<AuthController, XtreamProfile?>(AuthController.new);

class AuthController extends Notifier<XtreamProfile?> {
  @override
  XtreamProfile? build() => ref.read(prefsProvider).activeProfile();

  /// Valide les identifiants, enregistre le profil et le rend actif.
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

/// Client Xtream lié au profil actif (recréé au changement de profil).
final xtreamClientProvider = Provider<XtreamClient?>((ref) {
  final prof = ref.watch(authControllerProvider);
  if (prof == null) return null;
  final client = XtreamClient(prof);
  ref.onDispose(client.close);
  return client;
});

/// Constructeur d'URLs de flux du profil actif.
final xtreamUrlsProvider = Provider<XtreamUrls?>((ref) {
  final prof = ref.watch(authControllerProvider);
  return prof == null ? null : XtreamUrls.of(prof);
});

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
