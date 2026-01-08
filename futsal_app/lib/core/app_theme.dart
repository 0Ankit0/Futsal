import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors - Vibrant Green (Futsal Field)
  static const Color primary = Color(0xFF00C853); // Bright Green
  static const Color primaryDark = Color(0xFF00A843);
  static const Color primaryLight = Color(0xFF5EFC82);

  // Secondary Colors - Deep Blue (Sports Energy)
  static const Color secondary = Color(0xFF1565C0);
  static const Color secondaryDark = Color(0xFF003C8F);
  static const Color secondaryLight = Color(0xFF5E92F3);

  // Accent Colors
  static const Color accent = Color(0xFFFF6F00); // Orange for highlights
  static const Color accentLight = Color(0xFFFF9E40);

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF1E88E5);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow
  static BoxShadow cardShadow = BoxShadow(
    color: primary.withOpacity(0.1),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow buttonShadow = BoxShadow(
    color: primary.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );
}
