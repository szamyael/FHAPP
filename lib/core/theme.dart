import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/account.dart';
import 'constants.dart';

@immutable
class FoodHubRoleTheme extends ThemeExtension<FoodHubRoleTheme> {
  const FoodHubRoleTheme({
    required this.accent,
    required this.sidebarBackground,
    required this.onSidebar,
  });

  final Color accent;
  final Color sidebarBackground;
  final Color onSidebar;

  @override
  FoodHubRoleTheme copyWith({
    Color? accent,
    Color? sidebarBackground,
    Color? onSidebar,
  }) {
    return FoodHubRoleTheme(
      accent: accent ?? this.accent,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      onSidebar: onSidebar ?? this.onSidebar,
    );
  }

  @override
  FoodHubRoleTheme lerp(ThemeExtension<FoodHubRoleTheme>? other, double t) {
    if (other is! FoodHubRoleTheme) return this;
    return FoodHubRoleTheme(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t) ?? sidebarBackground,
      onSidebar: Color.lerp(onSidebar, other.onSidebar, t) ?? onSidebar,
    );
  }
}

ThemeData foodHubLightThemeForRole(AccountRole? role) {
  return _buildThemeForRole(role, brightness: Brightness.light);
}

ThemeData foodHubDarkThemeForRole(AccountRole? role) {
  return _buildThemeForRole(role, brightness: Brightness.dark);
}

ThemeData _buildThemeForRole(AccountRole? role, {required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final scheme = isDark
      ? const ColorScheme.dark(
          primary: FoodHubConstants.brandPrimary,
          onPrimary: Colors.white,
          secondary: FoodHubConstants.brandSecondary,
          onSecondary: FoodHubConstants.textPrimary,
          tertiary: FoodHubConstants.brandAccent,
          onTertiary: Colors.white,
          surface: FoodHubConstants.darkCardBackground,
          onSurface: FoodHubConstants.darkTextPrimary,
          outline: FoodHubConstants.darkBorder,
          error: FoodHubConstants.brandPrimaryDark,
          onError: Colors.white,
        )
      : const ColorScheme.light(
          primary: FoodHubConstants.brandPrimary,
          onPrimary: Colors.white,
          secondary: FoodHubConstants.brandSecondary,
          onSecondary: FoodHubConstants.textPrimary,
          tertiary: FoodHubConstants.brandAccent,
          onTertiary: Colors.white,
          surface: FoodHubConstants.cardBackground,
          onSurface: FoodHubConstants.textPrimary,
          outline: FoodHubConstants.borderDefault,
          error: FoodHubConstants.brandPrimaryDark,
          onError: Colors.white,
        );

  final baseTextTheme = GoogleFonts.dmSansTextTheme();
  final display = GoogleFonts.playfairDisplayTextTheme();

  final textTheme = baseTextTheme.copyWith(
    displayLarge: display.displayLarge?.copyWith(
      fontSize: 64,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    displayMedium: display.displayMedium?.copyWith(
      fontSize: 40,
      height: 1.1,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      height: 1.6,
      color: scheme.onSurface,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      color: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: scheme.onSurface,
    ),
  );

  final roleAccent = FoodHubConstants.rolePrimaryColor(role);
  final roleTheme = FoodHubRoleTheme(
    accent: roleAccent,
    sidebarBackground: role == AccountRole.admin
        ? FoodHubConstants.adminNavy
        : (isDark ? FoodHubConstants.darkCardBackground : FoodHubConstants.cardBackground),
    onSidebar: role == AccountRole.admin
        ? Colors.white
        : (isDark ? FoodHubConstants.darkTextPrimary : FoodHubConstants.textPrimary),
  );

  const cardRadius = 12.0;
  const inputRadius = 8.0;

  final border = isDark ? FoodHubConstants.darkBorder : FoodHubConstants.borderDefault;
  final subtleSurface = isDark ? FoodHubConstants.darkRaisedBackground : FoodHubConstants.cardBackground;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
      isDark ? FoodHubConstants.darkPageBackground : FoodHubConstants.pageBackground,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[roleTheme],
    dividerTheme: DividerThemeData(color: border),
    appBarTheme: AppBarTheme(
      backgroundColor: subtleSurface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withAlpha(isDark ? 56 : 20),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? FoodHubConstants.darkRaisedBackground : FoodHubConstants.textPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: isDark ? FoodHubConstants.darkTextPrimary : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(width: 1.5, color: scheme.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide(color: border),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: textTheme.bodySmall?.copyWith(
        color: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
      ),
      hintStyle: textTheme.bodySmall?.copyWith(
        color: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(width: 1.5, color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(width: 1.5, color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(width: 1.5, color: scheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(width: 1.5, color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(width: 1.5, color: scheme.error),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: subtleSurface,
      indicatorColor: isDark ? FoodHubConstants.darkRaisedBackground : FoodHubConstants.brandPrimaryLight,
      selectedIconTheme: const IconThemeData(color: FoodHubConstants.brandPrimary),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: FoodHubConstants.brandPrimary),
      unselectedIconTheme: IconThemeData(
        color: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: subtleSurface,
      selectedItemColor: FoodHubConstants.brandPrimary,
      unselectedItemColor: isDark ? FoodHubConstants.darkTextSecondary : FoodHubConstants.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? FoodHubConstants.darkRaisedBackground : FoodHubConstants.brandPrimaryLight,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      labelStyle: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    ),
  );
}
