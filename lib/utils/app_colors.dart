// lib/utils/app_colors.dart
// Palet warna tema sinema gelap (Dark Cinema Theme)

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE50914); // Merah bioskop
  static const Color primaryDark = Color(0xFFB20710); // Merah lebih gelap
  static const Color primaryLight = Color(0xFFFF3D47); // Merah lebih terang

  // ── Background & Surface ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A); // Sangat gelap
  static const Color surface = Color(0xFF1A1A2E); // Biru tua gelap
  static const Color card = Color(0xFF16213E); // Card gelap
  static const Color cardLight = Color(0xFF1F2D4A); // Card sedikit lebih terang

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0); // Abu-abu terang
  static const Color textDisabled = Color(0xFF5A5A5A); // Abu-abu gelap
  static const Color textHint = Color(0xFF7A7A7A); // Hint text

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFD700); // Emas/aksen rating
  static const Color goldDark = Color(0xFFCCA800); // Emas gelap

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50); // Hijau
  static const Color warning = Color(0xFFFFC107); // Kuning
  static const Color error = Color(0xFFE53935); // Merah error
  static const Color info = Color(0xFF2196F3); // Biru info

  // ── UI Elements ───────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A3E);
  static const Color border = Color(0xFF2E2E4E);
  static const Color inputFill = Color(0xFF1E1E32);
  static const Color shimmer = Color(0xFF2A2A3E);
  static const Color shimmerHighlight = Color(0xFF3A3A5E);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [card, cardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
