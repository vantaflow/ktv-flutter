import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'auth_controller.dart';
import '../../services/log/remote_log.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/sync/sync_providers.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final srv = TextEditingController();
  final usr = TextEditingController();
  final pwd = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    RemoteLog.log('LoginScreen init');
  }

  @override
  void dispose() {
    srv.dispose();
    usr.dispose();
    pwd.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (srv.text.trim().isEmpty || usr.text.trim().isEmpty) {
      setState(() => _error = L.of(context)!.loginNeedServer);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(srv.text.trim(), usr.text.trim(), pwd.text.trim());
    } catch (e) {
      setState(() => _error = 'Échec de connexion : ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useProfile(XtreamProfile p) async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).switchTo(p);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Connexion via un autre appareil : Trakt (code) + synchro chiffrée ---
  Future<void> _syncLogin() async {
    final trakt = ref.read(traktServiceProvider);
    setState(() => _error = null);
    try {
      if (!trakt.connected) {
        final ok = await _traktDeviceFlow(trakt);
        if (ok != true) return;
      }
      final pass = await _askPassphrase();
      if (pass == null || pass.trim().isEmpty) return;
      setState(() => _loading = true);
      await ref.read(syncControllerProvider.notifier).activate(pass.trim());
      final st = ref.read(syncControllerProvider);
      if (st.status == SyncStatus.error) {
        setState(() => _error = st.message);
      } else if (ref.read(prefsProvider).profiles().isEmpty) {
        setState(() => _error = L.of(context)!.syncNoProfile);
      }
      // Sinon : le profil actif synchronisé est appliqué → l'app bascule sur l'accueil.
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Affiche le code device Trakt et attend l'autorisation. true si connecté.
  Future<bool?> _traktDeviceFlow(dynamic trakt) async {
    final Map<String, dynamic> dev;
    try {
      dev = await trakt.requestDeviceCode();
    } catch (_) {
      setState(() => _error = L.of(context)!.sTraktCodeErr);
      return false;
    }
    final code = (dev['user_code'] ?? '').toString();
    final url = (dev['verification_url'] ?? 'https://trakt.tv/activate').toString();
    final deviceCode = (dev['device_code'] ?? '').toString();
    final interval = (dev['interval'] as num?)?.toInt() ?? 5;
    final expires = (dev['expires_in'] as num?)?.toInt() ?? 600;
    if (code.isEmpty || deviceCode.isEmpty) return false;
    var cancelled = false;
    var connected = false;
    if (!context.mounted) return false;
    // Dialogue non bloquant qui affiche le code (annulable).
    // ignore: unawaited_futures
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: KtvColors.panel,
        title: Text(L.of(context)!.sTraktConnDialog),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(L.of(context)!.sGoTo, style: TextStyle(color: KtvColors.muted)),
          SelectableText(url, style: TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(L.of(context)!.sEnterCode, style: TextStyle(color: KtvColors.muted)),
          SelectableText(code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 12),
          Row(children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text(L.of(context)!.syncWaiting, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
          ]),
        ]),
        actions: [TextButton(onPressed: () { cancelled = true; Navigator.pop(context); }, child: Text(L.of(context)!.downloadsCancel))],
      ),
    );

    var elapsed = 0;
    while (!connected && !cancelled && elapsed < expires) {
      await Future.delayed(Duration(seconds: interval));
      elapsed += interval;
      if (cancelled) break;
      connected = await trakt.pollDeviceToken(deviceCode);
    }
    // ignore: use_build_context_synchronously
    if (!cancelled && context.mounted) Navigator.of(context, rootNavigator: true).pop(); // ferme le dialogue code
    if (!connected) setState(() => _error = L.of(context)!.syncTraktCanceled);
    return connected;
  }

  Future<String?> _askPassphrase() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KtvColors.panel,
        title: Text(L.of(context)!.sPassphraseLabel),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
          decoration: InputDecoration(hintText: L.of(context)!.sPassphraseChoose),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L.of(context)!.downloadsCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: Text(L.of(context)!.actionRefresh)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.read(prefsProvider).profiles();
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedBackdrop(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: KtvColors.panel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KtvColors.line),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
                  ),
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _logo(),
                        const SizedBox(height: 20),
                        // Connexion sans rien taper : récupère les accès d'un autre appareil.
                        FilledButton.tonalIcon(
                          onPressed: _loading ? null : _syncLogin,
                          icon: const Icon(Icons.devices, size: 18),
                          label: Text(L.of(context)!.syncLoginBtn),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(children: [
                            Expanded(child: Divider(color: KtvColors.line)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(L.of(context)!.syncOrManual, style: TextStyle(color: KtvColors.muted, fontSize: 11))),
                            Expanded(child: Divider(color: KtvColors.line)),
                          ]),
                        ),
                        if (profiles.isNotEmpty) ...[
                          Text(L.of(context)!.loginSavedProfiles, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profiles
                                .map((p) => ActionChip(
                                      label: Text(p.label),
                                      backgroundColor: KtvColors.panel2,
                                      side: BorderSide(color: KtvColors.line),
                                      onPressed: _loading ? null : () => _useProfile(p),
                                    ))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: KtvColors.line),
                          ),
                        ],
                        TextField(
                          controller: srv,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(hintText: L.of(context)!.loginServer),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: usr,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(hintText: L.of(context)!.loginUser),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pwd,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _connect(),
                          decoration: InputDecoration(
                            hintText: L.of(context)!.loginPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: KtvColors.rec, fontSize: 13)),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _connect,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(L.of(context)!.loginConnect),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(gradient: KtvColors.accentGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('KTV', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      );
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.7),
          radius: 1.4,
          colors: [Color(0xFF241A14), KtvColors.bg],
        ),
      ),
    );
  }
}
