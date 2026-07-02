import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/platform.dart';
import 'core/storage/prefs_store.dart';
import 'core/theme/app_theme.dart';
import 'core/version.dart';
import 'services/log/remote_log.dart';

Future<void> main() async {
  RemoteLog.init();
  // Capture des erreurs Dart (les crashs natifs, eux, se repèrent au dernier
  // breadcrumb reçu avant le silence).
  FlutterError.onError = (d) {
    RemoteLog.log('FlutterError: ${d.exceptionAsString()}');
    FlutterError.presentError(d);
  };
  runZonedGuarded(() async {
    RemoteLog.log('== main start · KTV $kAppVersion · desktop=$kDesktop ==');
    WidgetsFlutterBinding.ensureInitialized();
    PlatformDispatcher.instance.onError = (e, s) {
      RemoteLog.log('PlatformError: $e');
      return true;
    };
    MediaKit.ensureInitialized();
    RemoteLog.log('mediakit init ok');
    if (kDesktop) {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow(
        const WindowOptions(size: Size(1280, 800), minimumSize: Size(940, 600), title: 'KTV', center: true),
        () async {
          await windowManager.show();
          await windowManager.focus();
          await windowManager.maximize();
        },
      );
      RemoteLog.log('window ready');
    }
    final prefs = await PrefsStore.create();
    RemoteLog.log('prefs ok (profils=${prefs.profiles().length}, actif=${prefs.activeId() != null})');
    KtvColors.apply(light: prefs.settingBool('themeLight', false), accentKey: prefs.settingStr('accentColor', 'orange'));
    RemoteLog.log('runApp');
    runApp(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const KtvApp(),
      ),
    );
  }, (e, s) {
    RemoteLog.log('ZONE CRASH: $e\n${s.toString().split('\n').take(6).join(' | ')}');
  });
}
