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
  AppBarNotifier() : super(const AppBarConfig());

  void setConfig(AppBarConfig config) {
    state = config;
  }

  void reset() {
    state = const AppBarConfig();
  }

  void hide() {
    state = const AppBarConfig.none();
  }
}

final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarConfig>((
  ref,
) {
  return AppBarNotifier();
});
