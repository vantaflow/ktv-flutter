import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cryptography/cryptography.dart';
import '../../core/logic/text_utils.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

/// Instantané immuable de la configuration du contrôle parental.
/// Le contrôle n'est actif que lorsqu'un PIN est défini ([enabled]).
class ParentalConfig {
  final bool pinSet;
  final String mode; // 'lock' | 'hide'
  final bool autoAdult;
  final Set<String> lockedCats; // '<section>::<catId>'
  final Set<String> lockedChannels; // streamId (composite plus tard)

  const ParentalConfig({
    required this.pinSet,
    required this.mode,
    required this.autoAdult,
    required this.lockedCats,
    required this.lockedChannels,
  });

  bool get enabled => pinSet;
  bool get hideMode => mode == 'hide';

  /// Une catégorie est verrouillée si marquée manuellement OU (auto) « adulte ».
  bool categoryLocked(String section, String catId, String? name) {
    if (!enabled) return false;
    if (lockedCats.contains('$section::$catId')) return true;
    if (autoAdult && isAdultCategory(name)) return true;
    return false;
  }

  /// Une chaîne est verrouillée si marquée, si sa catégorie l'est, ou (auto)
  /// si son nom est « adulte ».
  bool channelLocked(String channelId, {String section = 'live', String? catId, String? name}) {
    if (!enabled) return false;
    if (lockedChannels.contains(channelId)) return true;
    if (catId != null && lockedCats.contains('$section::$catId')) return true;
    if (autoAdult && isAdultCategory(name)) return true;
    return false;
  }
}

/// Bumpé à chaque changement de config parentale → reconstruit les filtres.
final parentalTickProvider = StateProvider<int>((ref) => 0);

/// Déverrouillage de session (réinitialisé au redémarrage de l'app).
final parentalUnlockedProvider = StateProvider<bool>((ref) => false);

/// Config parentale courante (relue à chaque tick).
final parentalConfigProvider = Provider<ParentalConfig>((ref) {
  ref.watch(parentalTickProvider);
  final p = ref.read(prefsProvider);
  return ParentalConfig(
    pinSet: p.parentalPinSet,
    mode: p.parentalMode(),
    autoAdult: p.parentalAutoAdult(),
    lockedCats: p.parentalLockedCats(),
    lockedChannels: p.parentalLockedChannels(),
  );
});

// --- Hachage du PIN (SHA-256 salé — le store est déjà local en clair) ---

Future<String> _hashPin(String pin, String salt) async {
  final d = await Sha256().hash(utf8.encode('$salt::$pin'));
  return base64Encode(d.bytes);
}

String _randSalt() {
  final r = Random.secure();
  return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

/// Définit (ou remplace) le PIN parental.
Future<void> setParentalPin(WidgetRef ref, String pin) async {
  final salt = _randSalt();
  final h = await _hashPin(pin, salt);
  await ref.read(prefsProvider).setParentalCredential(h, salt);
  ref.read(parentalTickProvider.notifier).state++;
}

/// Supprime le PIN et désactive le contrôle parental.
Future<void> removeParentalPin(WidgetRef ref) async {
  await ref.read(prefsProvider).setParentalCredential(null, null);
  ref.read(parentalUnlockedProvider.notifier).state = false;
  ref.read(parentalTickProvider.notifier).state++;
}

Future<bool> verifyParentalPin(WidgetRef ref, String pin) async {
  final p = ref.read(prefsProvider);
  final salt = p.parentalSalt();
  final h = p.parentalPinHash();
  if (salt == null || h == null) return false;
  return await _hashPin(pin, salt) == h;
}

/// Autorise une action protégée : renvoie true si [locked] est faux, si la
/// session est déjà déverrouillée, ou après saisie correcte du PIN.
Future<bool> parentalAllow(BuildContext context, WidgetRef ref, {required bool locked}) async {
  if (!locked) return true;
  if (ref.read(parentalUnlockedProvider)) return true;
  final ok = await _promptPinUnlock(context, ref);
  if (ok) ref.read(parentalUnlockedProvider.notifier).state = true;
  return ok;
}

/// Dialogue de saisie du PIN pour déverrouiller (avec ré-essais).
Future<bool> _promptPinUnlock(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _PinDialog(mode: _PinMode.unlock),
  );
  return ok ?? false;
}

enum _PinMode { unlock, setNew }

/// Ouvre le dialogue de définition/changement du PIN (double saisie).
Future<void> promptSetParentalPin(BuildContext context, WidgetRef ref) async {
  await showDialog(context: context, builder: (_) => const _PinDialog(mode: _PinMode.setNew));
}

class _PinDialog extends ConsumerStatefulWidget {
  final _PinMode mode;
  const _PinDialog({required this.mode});
  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _c1.text.trim();
    if (pin.length < 4) {
      setState(() => _err = 'Le code doit comporter au moins 4 chiffres.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    if (widget.mode == _PinMode.setNew) {
      if (_c2.text.trim() != pin) {
        setState(() {
          _busy = false;
          _err = 'Les deux codes ne correspondent pas.';
        });
        return;
      }
      await setParentalPin(ref, pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final ok = await verifyParentalPin(ref, pin);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _busy = false;
          _err = 'Code incorrect.';
          _c1.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final setNew = widget.mode == _PinMode.setNew;
    return AlertDialog(
      backgroundColor: KtvColors.panel,
      title: Row(children: [
        const Icon(Icons.lock_outline, size: 20),
        const SizedBox(width: 8),
        Text(setNew ? 'Définir le code parental' : 'Code parental'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _c1,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            decoration: InputDecoration(labelText: setNew ? 'Nouveau code (4-8 chiffres)' : 'Entrez le code'),
            onSubmitted: (_) => setNew ? null : _submit(),
          ),
          if (setNew) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _c2,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: const InputDecoration(labelText: 'Confirmez le code'),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_err != null) ...[
            const SizedBox(height: 10),
            Text(_err!, style: const TextStyle(color: Color(0xffff6b6b), fontSize: 12.5)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(setNew ? 'Enregistrer' : 'Déverrouiller')),
      ],
    );
  }
}
