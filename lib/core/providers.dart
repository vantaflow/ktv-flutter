import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'storage/prefs_store.dart';
import 'connection/connection_lock.dart';

/// Fourni via override dans main() (init async de SharedPreferences).
final prefsProvider = Provider<PrefsStore>((ref) => throw UnimplementedError('prefsProvider non initialisé'));

/// Verrou de connexion unique (partagé lecture/enregistrement/restream).
final connectionLockProvider = Provider<ConnectionLock>((ref) => ConnectionLock());

/// Incrémenté à chaque lecture (historise) → l'accueil se rafraîchit.
final recentTickProvider = StateProvider<int>((ref) => 0);

/// Incrémenté à chaque changement de thème → MaterialApp se reconstruit.
final themeVersionProvider = StateProvider<int>((ref) => 0);
