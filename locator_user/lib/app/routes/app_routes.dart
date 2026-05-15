import 'package:flutter/material.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String navigate = '/navigate';
  static const String discover = '/discover';
  static const String trips = '/trips';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String offerDetail = '/offer-detail/:id';
  static const String shopDetail = '/shop-detail/:id';
  static const String arView = '/ar-view';
  static const String notifications = '/notifications';
  static const String error = '/error';
  static const String pastJourneys = '/profile/history';
  static const String savedItems = '/profile/saved';
}

extension NavigationExtension on BuildContext {
  /// Simple routing extension over GoRouter to eliminate string coupling in views
  void flushBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}
