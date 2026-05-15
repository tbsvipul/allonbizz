import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Notifier that manages [ThemeMode] backed by [StorageService].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage)
    : super(_storage.isDarkMode ? ThemeMode.dark : ThemeMode.system);

  /// Toggle dark/light mode and persist.
  void setDarkMode(bool isDark) {
    _storage.isDarkMode = isDark;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;
}

/// Riverpod provider for app [ThemeMode].
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});
