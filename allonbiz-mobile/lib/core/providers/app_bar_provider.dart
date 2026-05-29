import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _AppBarBindingEntry {
  const _AppBarBindingEntry({required this.owner, required this.config});

  final Object owner;
  final AppBarConfig config;
}

class AppBarConfig {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool centerTitle;

  const AppBarConfig({
    this.title,
    this.actions,
    this.leading,
    this.showAppBar = true,
    this.backgroundColor,
    this.centerTitle = false,
  });

  const AppBarConfig.none() : this(showAppBar: false);
}

class AppBarNotifier extends StateNotifier<AppBarConfig> {
  final List<_AppBarBindingEntry> _configStack = [];

  AppBarNotifier() : super(const AppBarConfig());

  void setConfig(AppBarConfig config) {
    if (_configStack.isNotEmpty) {
      final lastEntry = _configStack.removeLast();
      _configStack.add(
        _AppBarBindingEntry(owner: lastEntry.owner, config: config),
      );
      _syncState();
      return;
    }
    state = config;
  }

  void bindConfig(Object owner, AppBarConfig config) {
    final index = _configStack.indexWhere(
      (entry) => identical(entry.owner, owner),
    );
    final nextEntry = _AppBarBindingEntry(owner: owner, config: config);
    if (index == -1) {
      _configStack.add(nextEntry);
    } else {
      _configStack[index] = nextEntry;
    }
    _syncState();
  }

  void unbindConfig(Object owner) {
    _configStack.removeWhere((entry) => identical(entry.owner, owner));
    _syncState();
  }

  void _syncState() {
    if (_configStack.isNotEmpty) {
      state = _configStack.last.config;
    } else {
      state = const AppBarConfig();
    }
  }

  void reset() {
    _configStack.clear();
    state = const AppBarConfig();
  }

  void hide() {
    setConfig(const AppBarConfig.none());
  }
}

final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarConfig>((
  ref,
) {
  return AppBarNotifier();
});
