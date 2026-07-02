import 'dart:io';
import 'package:flutter/foundation.dart';

/// Vrai sur les plateformes desktop (macOS/Windows/Linux) : elles seules
/// disposent de la gestion de fenêtre et de l'exécution de binaires (ffmpeg,
/// cloudflared). Sur mobile (Android/iOS), ces fonctions sont neutralisées.
final bool kDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// Vrai sur mobile — raccourci de lisibilité.
final bool kMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
