import 'package:flutter/material.dart';

import '../models/account.dart';

class FoodHubConstants {
  static const double baseCommissionRate = 0.10;

  // ---- Brand palette (from FoodHub_Complete_UIUX_Prompt.md) ----
  static const Color brandPrimary = Color(0xFFE63946); // Chili Red
  static const Color brandPrimaryLight = Color(0xFFFDECEA);
  static const Color brandPrimaryDark = Color(0xFFB02A35);

  static const Color brandSecondary = Color(0xFFF4A261); // Saffron Gold
  static const Color brandSecondaryLight = Color(0xFFFEF3E2);
  static const Color brandSecondaryDark = Color(0xFFC07A38);

  static const Color brandAccent = Color(0xFF2A9D8F); // Basil Green
  static const Color brandAccentLight = Color(0xFFE0F5F3);
  static const Color brandAccentDark = Color(0xFF1A6B62);

  static const Color pageBackground = Color(0xFFFFF8F1); // Cream White
  static const Color cardBackground = Color(0xFFFFFFFF); // Warm White

  static const Color textPrimary = Color(0xFF1A1A2E); // Charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Warm Gray
  static const Color borderDefault = Color(0xFFF0E6DC); // Soft Blush

  // Overlay: rgba(26,26,46,0.7)
  static const Color overlayCharcoal70 = Color(0xB31A1A2E);

  // ---- Dark mode palette (from spec) ----
  static const Color darkPageBackground = Color(0xFF121212);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkRaisedBackground = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // ---- Role accents (dashboard accents from spec) ----
  static const Color adminNavy = Color(0xFF1D3557);
  static const Color sellerAmber = Color(0xFFE76F51);
  static const Color riderBlue = Color(0xFF457B9D);
  static const Color userRed = brandPrimary;

  static Color rolePrimaryColor(AccountRole? role) {
    return switch (role) {
      AccountRole.admin => adminNavy,
      AccountRole.seller => sellerAmber,
      AccountRole.rider => riderBlue,
      AccountRole.user => userRed,
      null => userRed,
    };
  }
}
