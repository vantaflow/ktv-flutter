import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'auth_controller.dart';
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
  void dispose() {
    srv.dispose();
    usr.dispose();
    pwd.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (srv.text.trim().isEmpty || usr.text.trim().isEmpty) {
      setState(() => _error = 'Renseigne au moins le serveur et l\'utilisateur.');
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _logo(),
                      const SizedBox(height: 24),
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
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: KtvColors.line),
                        ),
                      ],
                      TextField(controller: srv, decoration: InputDecoration(hintText: L.of(context)!.loginServer)),
                      const SizedBox(height: 12),
                      TextField(controller: usr, decoration: InputDecoration(hintText: L.of(context)!.loginUser)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pwd,
                        obscureText: _obscure,
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
