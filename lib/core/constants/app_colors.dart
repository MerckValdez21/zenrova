import 'package:flutter/material.dart';

class AppColors {
  // --- Primary Palette ---
  static const Color primary = Color(0xFF7C5CBF);
  static const Color primaryLight = Color(0xFF9B7FD4);
  static const Color primaryDark = Color(0xFF5A3D9A);

  // --- Secondary Palette ---
  static const Color secondary = Color(0xFF5BB8F5);
  static const Color secondaryLight = Color(0xFF89CFFA);
  static const Color secondaryDark = Color(0xFF2D9AD8);

  // --- Accent ---
  static const Color accent = Color(0xFFFF7E6B);
  static const Color accentSoft = Color(0xFFFFB3A7);

  // --- Gradient Colors ---
  static const Color gradientStart = Color(0xFF6A4BC4);
  static const Color gradientMid = Color(0xFF8E5BBF);
  static const Color gradientEnd = Color(0xFF5B90D9);

  // --- Neutral / Surface ---
  static const Color background = Color(0xFFF7F5FF);
  static const Color backgroundDark = Color(0xFF0E0A1A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFCFAFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1C1635);

  // --- Text ---
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF0D0D0D);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceMuted = Color(0xFF6B6B8A);
  static const Color onDark = Color(0xFFEEEAFF);

  // --- Status ---
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF3182CE);

  // --- Overlays / Shadows ---
  static const Color shadowPrimary = Color(0x407C5CBF);
  static const Color shadowSoft = Color(0x1A000000);
  static const Color overlayDark = Color(0x80000000);

  // --- Google Brand ---
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE7FF), Color(0xFFE3F0FF)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF130E2B), Color(0xFF1E1440), Color(0xFF0E1A33)],
  );
}
