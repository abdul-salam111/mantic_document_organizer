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
  static const Color primary = Color(0xFF197DCA);
  static const Color primaryDark = Color(0xFF4850E4);
  static const Color primaryLight = Color(0xFF9398EF);

  /// Dark-theme-tuned primary accent. [primary] itself stays the same
  /// value across both themes because it's always paired with white
  /// foreground content (AppBar, filled buttons) — brightening it would
  /// hurt that white-on-primary contrast. This tone is for the opposite
  /// case: a small accent (focused input border, active nav icon) sitting
  /// directly on a dark surface, where [primary] alone only measures
  /// ~4.3:1 against the new near-black background — acceptable but tight.
  /// This measures ~6.9:1 in the same spot.
  static const Color primaryOnDark = Color(0xFF4FA3E3);

  /// Secondary brand color - Accents, highlights
  static const Color secondary = Color(0xFFDED2FA);
  static const Color secondaryDark = Color(0xFFC5B5E8);
  static const Color secondaryLight = Color(0xFFEDE7FC);

  /// Tertiary brand color - Alternative accents
  ///
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

  /// Dark-theme-tuned error accent — [error] measures only ~2.6:1 against
  /// the near-black dark background (it was tuned for use on white), which
  /// fails even the 3:1 minimum for UI text. This measures ~5.1:1 in the
  /// same spot.
  static const Color errorOnDark = Color(0xFFE5544A);

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

  /// Material's canonical dark base rather than pure black — pure black
  /// gives elevated surfaces no headroom to read as "lighter" against it,
  /// and reads harsher than intended on OLED screens.
  static const Color backgroundDark = Color(0xFF121212);

  /// Surface colors for cards, sheets
  static const Color surfaceLight = grey50;
  static const Color surfaceDark = Color(0xFF1C1C1E);

  /// Elevated surfaces
  static const Color surfaceElevatedLight = white;
  static const Color surfaceElevatedDark = Color(0xFF2C2C2E);

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

  /// A step lighter than [surfaceElevatedDark] so a border is actually
  /// visible on an elevated surface — it used to equal grey700, the same
  /// value as the elevated surface itself, making borders on cards/sheets
  /// invisible.
  static const Color borderDark = Color(0xFF3A3A3D);

  static const Color divider = grey200;
  static const Color dividerLight = grey200;
  static const Color dividerDark = Color(0xFF3A3A3D);

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

  /// Shadows. A black shadow barely reads against a near-black background
  /// no matter its opacity — elevation in dark mode should mostly come
  /// from the surface/surfaceElevated step, not the shadow. This is
  /// nudged up from 20% mainly so it still contributes a little definition.
  static const Color shadow = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x4D000000); // 30% black

  /// Transparent
  static const Color transparent = Colors.transparent;
}
