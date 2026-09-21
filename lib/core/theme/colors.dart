// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Application color palette
/// Organized by usage and hierarchy
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================
  // BRAND COLORS
  // ============================================

  /// Primary brand color - Main actions, CTAs
  static const Color primary = Color(0xFFFF8F2D);
  static const Color primaryDark = Color(0xFFE67A1A);
  static const Color primaryLight = Color(0xFFFFA558);

  /// Secondary brand color - Accents, highlights
  static const Color secondary = Color(0xFFDED2FA);
  static const Color secondaryDark = Color(0xFFC5B5E8);
  static const Color secondaryLight = Color(0xFFEDE7FC);

  /// Tertiary brand color - Alternative accents
  static const Color tertiary = Color(0xFF3927AD);
  static const Color tertiaryDark = Color(0xFF2A1C7B);
  static const Color tertiaryLight = Color(0xFF5B47C9);

  // ============================================
  // NEUTRAL COLORS
  // ============================================

  /// Pure colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Grey scale - Light to Dark
  static const Color grey50 = Color(0xFFF2F2F2); // Lightest
  static const Color grey100 = Color(0xFFF3F2F2); // Almost white
  static const Color grey200 = Color(0xFFEDEDED); // Very light
  static const Color grey300 = Color(0xFFACACAC); // Light
  static const Color grey400 = Color(0xFF707070); // Medium
  static const Color grey500 = Color(0xFF717171); // Standard grey
  static const Color grey600 = Color(0xFF5A5A5A); // Dark
  static const Color grey700 = Color(0xFF3D3D3D); // Darker
  static const Color grey800 = Color(0xFF2A2A2A); // Very dark
  static const Color grey900 = Color(0xFF1A1A1A); // Almost black

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// Success - Positive actions, confirmations
  static const Color success = Colors.green;
  static const Color successDark = Color(0xFF2AB57A);
  static const Color successLight = Color(0xFF6EE1B0);

  /// Error - Destructive actions, errors
  static const Color error = Color(0xFFAB2017);
  static const Color errorDark = Color(0xFF8B1912);
  static const Color errorLight = Color(0xFFD4342A);

  /// Warning - Caution, alerts
  static const Color warning = Color(0xFFFFC542);
  static const Color warningDark = Color(0xFFE5A91C);
  static const Color warningLight = Color(0xFFFFD670);

  /// Info - Informational messages
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFF60A5FA);

  /// Critical - Urgent alerts
  static const Color critical = Color(0xFF3D0C11);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  static const Color backgroundLight = white;
  static const Color backgroundDark = black;

  /// Surface colors for cards, sheets
  static const Color surfaceLight = grey50;
  static const Color surfaceDark = grey800;

  /// Elevated surfaces
  static const Color surfaceElevatedLight = white;
  static const Color surfaceElevatedDark = grey700;

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Light theme text
  static const Color textPrimaryLight = black;
  static const Color textSecondaryLight = grey500;
  static const Color textDisabledLight = grey300;

  /// Dark theme text
  static const Color textPrimaryDark = white;
  static const Color textSecondaryDark = grey300;
  static const Color textDisabledDark = grey600;

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================

  static const Color border = grey200;
  static const Color borderLight = grey200;
  static const Color borderDark = grey700;

  static const Color divider = grey200;
  static const Color dividerLight = grey200;
  static const Color dividerDark = grey700;

  // ============================================
  // OVERLAY COLORS
  // ============================================

  /// Overlay backgrounds for modals, dialogs
  static const Color overlayLight = Color(0x80000000); // 50% black
  static const Color overlayDark = Color(0xB3000000); // 70% black

  /// Scrim for blocking interactions
  static const Color scrim = Color(0x66000000); // 40% black

  // ============================================
  // SPECIAL PURPOSE COLORS
  // ============================================

  /// Rating/stars
  static const Color rating = warning;

  /// Badges
  static const Color badgeNew = info;
  static const Color badgeSale = error;
  static const Color badgeFeatured = primary;

  /// Shadows
  static const Color shadow = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x33000000); // 20% black

  /// Transparent
  static const Color transparent = Colors.transparent;
}
