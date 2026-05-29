import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// GoRouter helpers to reduce boilerplate in widgets.
extension NavigationX on BuildContext {
  void goTo(String location, {Object? extra}) => go(location, extra: extra);

  Future<T?> pushTo<T extends Object?>(String location, {Object? extra}) =>
      push<T>(location, extra: extra);

  void replaceWith(String location, {Object? extra}) =>
      pushReplacement(location, extra: extra);

  void popSafely<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    final navigator = Navigator.maybeOf(this);
    if (navigator?.canPop() != true) {
      return;
    }

    pop<T>(result);
  }

  void hideCurrentSnackBar() {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(this);
    scaffoldMessenger?.hideCurrentSnackBar();
  }
}
