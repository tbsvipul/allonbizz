import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_screens.dart';
import 'app_router.dart';
import 'providers.dart';

class AllonbizApp extends ConsumerStatefulWidget {
  const AllonbizApp({super.key});

  @override
  ConsumerState<AllonbizApp> createState() => _AllonbizAppState();
}

class _AllonbizAppState extends ConsumerState<AllonbizApp> {
  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);

    return bootstrap.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAllonbizTheme(Brightness.light),
        darkTheme: buildAllonbizTheme(Brightness.dark),
        themeMode: ThemeMode.light,
        home: const SplashScreen(statusText: 'Preparing allonbiz...'),
      ),
      error: (error, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAllonbizTheme(Brightness.light),
        darkTheme: buildAllonbizTheme(Brightness.dark),
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Startup failed: $error'),
            ),
          ),
        ),
      ),
      data: (_) {
        final preferences = ref.watch(preferencesControllerProvider).preferences;
        final themeMode = preferences.darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildAllonbizTheme(Brightness.light),
          darkTheme: buildAllonbizTheme(Brightness.dark),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
