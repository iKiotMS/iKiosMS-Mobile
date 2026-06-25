import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_token_provider.dart';
import 'presentation/auth/views/login_view.dart';
import 'presentation/shell/app_shell.dart';

/// Root widget for the iKiotMS Mobile app.
///
/// Configures Material 3 theme with a clean blue/indigo color scheme.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(authTokenProvider);

    return MaterialApp(
      title: 'iKiotMS Mobile',
      debugShowCheckedModeBanner: false,

      // Enable Material 3 with a professional, calm color seed.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6FD4), // professional blue
          brightness: Brightness.light,
        ),
        // Clean card defaults
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        // App bar — no elevation, clean
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      ),

      home: tokenState.when(
        data: (token) {
          if (token == null) {
            return const LoginView();
          }
          return const AppShell();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => const LoginView(),
      ),
    );
  }
}
