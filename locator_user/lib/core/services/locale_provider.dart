import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Notifier that manages the active [Locale] backed by [StorageService].
class LocaleNotifier extends StateNotifier<Locale> {
  final StorageService _storage;

  LocaleNotifier(this._storage) : super(Locale(_storage.languageCode));

  /// Switch locale and persist the choice.
  void setLocale(String code) {
    _storage.languageCode = code;
    state = Locale(code);
  }

  /// Supported language codes → display names.
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
  };
}

/// Riverpod provider for the active [Locale].
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LocaleNotifier(storage);
});
