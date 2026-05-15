import 'package:flutter/material.dart';

/// Common Dart / Flutter extensions.
extension StringX on String {
  /// Capitalize first letter.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case each word.
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');
}

extension ContextX on BuildContext {
  /// Quick access to theme data.
  ThemeData get theme => Theme.of(this);

  /// Quick access to color scheme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Quick access to text theme.
  TextTheme get textTheme => theme.textTheme;

  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Safe area padding.
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);

  /// Show a snackbar.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

extension DateTimeX on DateTime {
  /// Greeting based on time of day.
  String get greeting {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
