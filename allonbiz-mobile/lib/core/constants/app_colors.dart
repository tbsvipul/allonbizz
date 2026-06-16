import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary        = Color(0xFF5A6DBA);
  static const Color primaryLight   = Color(0xFF8191D1);
  static const Color primaryDark    = Color(0xFF3D4B85);

  static const Color secondary      = Color(0xFFFFC107);
  static const Color secondaryLight = Color(0xFFFFD54F);
  static const Color secondaryDark  = Color(0xFFFFA000);

  static const Color accent          = Color(0xFFE44985);
  static const Color accentLight     = Color(0xFFF177A8);
  static const Color accentDark      = Color(0xFFAD3161);

  // Offer Pin Colors (Map)
  static const Color pinFood          = Color(0xFF5A6DBA);
  static const Color pinShopping      = Color(0xFFE44985);
  static const Color pinSightseeing   = Color(0xFFFFC107);

  // Neutral Palette
  static const Color white                = Color(0xFFFFFFFF);
  static const Color black                = Color(0xFF000000);
  static const Color grey50               = Color(0xFFF8F9FB);
  static const Color grey100              = Color(0xFFF1F3F7); 
  static const Color grey200              = Color(0xFFE2E6ED);
  static const Color grey300              = Color(0xFFC7CDDA);
  static const Color grey400              = Color(0xFFA3ABBC);
  static const Color grey500              = Color(0xFF7A8499);
  static const Color grey600              = Color(0xFF576075);
  static const Color grey700              = Color(0xFF3F4659);
  static const Color grey800              = Color(0xFF262C3A); 
  static const Color grey900              = Color(0xFF141824); 

  // Background & Surface
  static const Color backgroundLight      = Color(0xFFEAF0F9);
  static const Color backgroundDark       = Color(0xFF0C1017);
  static const Color surfaceLight         = Color(0xFFFFFFFF);
  static const Color surfaceDark          = Color(0xFF161B22);
  static const Color cardDark             = Color(0xFF1E242C);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark  = Color(0xFF1F252E);
  static const Color glassLight           = Color(0xCCFFFFFF);
  static const Color glassDark            = Color(0xB3161B22);
  static const Color outlineLight         = Color(0xFFD3DAE8);
  static const Color outlineDark          = Color(0xFF2A313F);
  static const Color ink                  = Color(0xFF1C2230);
  static const Color pearl                = Color(0xFFF4F6F9);
  static const Color champagne            = Color(0xFFE6EBF5);

  // Semantic
  static const Color success = Color(0xFF34A853);
  static const Color error   = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC05);
  static const Color info    = Color(0xFF4285F4);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A82CE), Color(0xFF5A6DBA), Color(0xFF4A5A9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dealGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFC107), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBackgroundLight = LinearGradient(
    colors: [Color(0xFFF5F8FC), Color(0xFFE8EEF8), Color(0xFFDEE6F4)],
    stops: [0, 0.5, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient appBackgroundDark = LinearGradient(
    colors: [Color(0xFF131824), Color(0xFF0E121B), Color(0xFF090B11)],
    stops: [0, 0.5, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassHighlight = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.10),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 28,
      spreadRadius: -8,
      offset: const Offset(0, 14),
    ),
  ];
}
