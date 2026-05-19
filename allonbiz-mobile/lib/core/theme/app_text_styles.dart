import 'package:flutter/material.dart';

/// Poppins-based typography scale following Material 3 type roles.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get displaySmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
    textBaseline: TextBaseline.alphabetic,
  );

  // ── Headline ──────────────────────────────────────────────────
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get headlineSmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  // ── Title ─────────────────────────────────────────────────────
  static TextStyle get titleLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  // ── Body ──────────────────────────────────────────────────────
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  // ── Label ─────────────────────────────────────────────────────
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    textBaseline: TextBaseline.alphabetic,
  );
}
