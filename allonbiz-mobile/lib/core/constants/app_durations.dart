/// Shared animation and feedback durations used across the app.
abstract final class AppDurations {
  static const Duration immediate = Duration.zero;
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration debounce = Duration(milliseconds: 1200);
  static const Duration snackbar = Duration(seconds: 4);
}
