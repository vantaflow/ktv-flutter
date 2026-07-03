import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs_store.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/categories/category_prefs.dart';
import '../trakt/trakt_providers.dart';
import 'crypto_box.dart';
import 'sync_merge.dart';

const kDefaultSyncEndpoint = 'https://ktv-sync.khalilbenaz.workers.dev';

enum SyncStatus { idle, syncing, ok, error }

class SyncState {
  final SyncStatus status;
  final int lastAt; // ms epoch du dernier sync réussi (0 = jamais)
  final String? message;
  const SyncState({this.status = SyncStatus.idle, this.lastAt = 0, this.message});
  SyncState copyWith({SyncStatus? status, int? lastAt, String? message}) =>
      SyncState(status: status ?? this.status, lastAt: lastAt ?? this.lastAt, message: message);
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);

class SyncController extends Notifier<SyncState> {
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30)));

  PrefsStore get _prefs => ref.read(prefsProvider);

  @override
  SyncState build() {
    final l = ref.read(prefsProvider).syncLocal();
    return SyncState(lastAt: (l['lastAt'] as num?)?.toInt() ?? 0);
  }

  // --- Config locale (jamais synchronisée) ---
  String get endpoint {
    final e = _prefs.syncLocal()['endpoint'];
    return (e is String && e.isNotEmpty) ? e : kDefaultSyncEndpoint;
  }

  bool get enabled => _prefs.syncLocal()['enabled'] == true;
  bool get hasPassphrase => (_prefs.syncLocal()['passphrase'] ?? '').toString().isNotEmpty;
  String get _passphrase => (_prefs.syncLocal()['passphrase'] ?? '').toString();

  /// Phrase secrète en clair (stockée localement, jamais envoyée au serveur) —
  /// pour l'afficher/rappeler à l'utilisateur dans les réglages.
  String get passphrase => _passphrase;

  Future<void> _patchLocal(Map<String, dynamic> patch) async {
    final l = _prefs.syncLocal()..addAll(patch);
    await _prefs.setSyncLocal(l);
  }

  Future<void> setEndpoint(String url) => _patchLocal({'endpoint': url.trim()});

  /// Active la synchro avec une phrase secrète, puis lance un premier sync.
  Future<void> activate(String passphrase) async {
    await _patchLocal({'enabled': true, 'passphrase': passphrase});
    await syncNow();
  }

  Future<void> disable() => _patchLocal({'enabled': false});

  Map<String, dynamic> _collectLocal() =>
      {for (final k in PrefsStore.syncKeys) if (_prefs.readJson(k) != null) k: _prefs.readJson(k)};

  Future<void> _applyBundle(Map<String, dynamic> merged) async {
    for (final k in PrefsStore.syncKeys) {
      if (merged.containsKey(k)) await _prefs.writeJson(k, merged[k]);
    }
    // Rafraîchit l'UI concernée par les données importées.
    KtvColors.apply(light: _prefs.settingBool('themeLight', false), accentKey: _prefs.settingStr('accentColor', 'orange'));
    ref.read(themeVersionProvider.notifier).state++;
    ref.read(recentTickProvider.notifier).state++;
    ref.read(categoryVisibilityTickProvider.notifier).state++;
    ref.invalidate(authControllerProvider); // profils/actif éventuellement modifiés
  }

  /// Pull → fusion → apply → push (concurrence optimiste via If-Match).
  Future<void> syncNow() async {
    if (!enabled) return;
    // Token Trakt frais (rafraîchi si expiré) — sinon reconnexion requise.
    final token = await ref.read(traktServiceProvider).freshAccessToken();
    if (token == null) {
      state = state.copyWith(status: SyncStatus.error, message: 'Session Trakt expirée — reconnecte Trakt (Réglages → Synchronisation Trakt).');
      return;
    }
    if (!hasPassphrase) {
      state = state.copyWith(status: SyncStatus.error, message: 'Phrase secrète manquante.');
      return;
    }
    state = state.copyWith(status: SyncStatus.syncing, message: null);
    try {
      final opts = Options(headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => s != null && s < 500);
      await _pullMergePush(token, opts, retriesLeft: 1);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _patchLocal({'lastAt': now});
      state = state.copyWith(status: SyncStatus.ok, lastAt: now, message: null);
    } on _SyncError catch (e) {
      state = state.copyWith(status: SyncStatus.error, message: e.message);
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, message: 'Échec : $e');
    }
  }

  Future<void> _pullMergePush(String token, Options opts, {required int retriesLeft}) async {
    // 1) Pull
    final getR = await _dio.getUri(Uri.parse('$endpoint/sync'), options: opts);
    if (getR.statusCode == 401) throw _SyncError('Session Trakt invalide — reconnecte Trakt.');

    final local = _collectLocal();
    int knownVersion = 0;
    Map<String, dynamic> merged = local;
    bool remoteNewer = false;

    if (getR.statusCode == 200 && getR.data is Map && (getR.data['blob'] is String)) {
      knownVersion = (getR.data['version'] as num?)?.toInt() ?? 0;
      final remoteUpdatedAt = (getR.data['updatedAt'] as num?)?.toInt() ?? 0;
      final lastAt = (_prefs.syncLocal()['remoteUpdatedAt'] as num?)?.toInt() ?? 0;
      remoteNewer = remoteUpdatedAt > lastAt;
      Map<String, dynamic> remote;
      try {
        remote = Map<String, dynamic>.from(jsonDecode(await CryptoBox.open(getR.data['blob'] as String, _passphrase)));
      } catch (_) {
        throw _SyncError('Phrase secrète incorrecte (déchiffrement impossible).');
      }
      merged = mergeBundle(local, remote, remoteNewer: remoteNewer);
      await _applyBundle(merged);
    }

    // 2) Push
    final envelope = await CryptoBox.seal(jsonEncode(merged), _passphrase);
    final putR = await _dio.putUri(
      Uri.parse('$endpoint/sync'),
      data: {'blob': envelope},
      options: Options(headers: {...?opts.headers, 'If-Match': '$knownVersion'}, validateStatus: (s) => s != null && s < 500),
    );
    if (putR.statusCode == 409 && retriesLeft > 0) {
      // Un autre appareil a écrit entre-temps → on repull et refusionne.
      return _pullMergePush(token, opts, retriesLeft: retriesLeft - 1);
    }
    if (putR.statusCode != 200) throw _SyncError('Le serveur a refusé (${putR.statusCode}).');
    await _patchLocal({'remoteUpdatedAt': (putR.data?['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch});
  }
}

class _SyncError implements Exception {
  final String message;
  _SyncError(this.message);
}
