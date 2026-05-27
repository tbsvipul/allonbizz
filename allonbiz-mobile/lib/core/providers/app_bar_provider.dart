import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final List<AppBarConfig> _configStack = [];

  AppBarNotifier() : super(const AppBarConfig());

  void setConfig(AppBarConfig config) {
    if (_configStack.isNotEmpty) {
      _configStack.removeLast();
    }
    _configStack.add(config);
    state = config;
  }

  void pushConfig(AppBarConfig config) {
    _configStack.add(config);
    state = config;
  }

  void popConfig() {
    if (_configStack.isNotEmpty) {
      _configStack.removeLast();
    }
    if (_configStack.isNotEmpty) {
      state = _configStack.last;
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
