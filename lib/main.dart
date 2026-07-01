import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/storage/prefs_store.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1280, 800), minimumSize: Size(940, 600), title: 'KTV', center: true),
    () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize(); // démarre en grand (remplit l'écran)
    },
  );
  final prefs = await PrefsStore.create();
  // Applique le thème enregistré avant le 1er rendu.
  KtvColors.apply(accentKey: prefs.settingStr('accentColor', 'orange'));
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const KtvApp(),
    ),
  );
}
