import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';

class KtvApp extends ConsumerWidget {
  const KtvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);
    ref.watch(themeVersionProvider); // reconstruit au changement d'accent
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'KTV',
      debugShowCheckedModeBanner: false,
      theme: buildKtvTheme(),
      locale: locale, // null = suit la langue du système
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: profile == null ? const LoginScreen() : const HomeShell(),
    );
  }
}
