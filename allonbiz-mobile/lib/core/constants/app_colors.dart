import 'package:flutter/material.dart';

/// allonbiz color palette.
/// Primary Green = deals & navigation, Orange = offers & CTAs,
/// Blue = info & accents.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF00C853);
  static const Color primaryLight = Color(0xFF69F0AE);
  static const Color primaryDark = Color(0xFF009624);

  static const Color secondary = Color(0xFFFF6D00);
  static const Color secondaryLight = Color(0xFFFF9E40);
  static const Color secondaryDark = Color(0xFFC43E00);

  static const Color accent = Color(0xFF2979FF);
  static const Color accentLight = Color(0xFF75A7FF);
  static const Color accentDark = Color(0xFF004ECB);

  // ── Offer Pin Colors (Map) ────────────────────────────────────
  static const Color pinFood = Color(0xFF00C853);
  static const Color pinShopping = Color(0xFF2979FF);
  static const Color pinSightseeing = Color(0xFFFFD600);

  // ── Neutral Palette ───────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Background ────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFF9100);
  static const Color info = Color(0xFF2979FF);

  // ── Loyalty Tiers ─────────────────────────────────────────────
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dealGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
