import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const primary      = Color(0xFF0D9488); // deep teal
  static const primaryLight = Color(0xFF2DD4BF); // mid teal
  static const primaryFaint = Color(0xFFCCFBF1); // very light teal
  static const ink          = Color(0xFF0F2B2A); // near-black teal
  static const inkMid       = Color(0xFF2D4A48); // dark teal text
  static const inkSoft      = Color(0xFF5F8A87); // muted teal text
  static const white        = Color(0xFFFFFFFF);
  static const _darkSurface = Color(0xFF1A2E2D);
  static const _darkBg      = Color(0xFF0F1E1D);

  // ── Context-aware ──────────────────────────────────────────────────────────
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkBg : const Color(0xFFF5FFFE);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurface : white;

  static Color surfaceTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F3533) : primaryFaint;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : ink;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryLight : inkSoft;

  static Color iconPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryLight : primary;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? white.withValues(alpha: 0.08)
          : ink.withValues(alpha: 0.07);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF059669);
  static const error   = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const gradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDeep = LinearGradient(
    colors: [Color(0xFF0A7A6E), primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDiagonal = LinearGradient(
    colors: [Color(0xFF0A6B60), primary],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const gradientSoft = LinearGradient(
    colors: [primaryLight, Color(0xFF99F6E4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient subtleGradient(BuildContext context) => LinearGradient(
    colors: [primary.withValues(alpha: 0.08), primary.withValues(alpha: 0.03)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double space4  = 4.0;
  static const double space8  = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const double radius   = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusSm = 10.0;

  // ── Shadow ─────────────────────────────────────────────────────────────────
  static BoxShadow get shadow => BoxShadow(
    color: primary.withValues(alpha: 0.12),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static BoxShadow get shadowStrong => BoxShadow(
    color: primary.withValues(alpha: 0.28),
    blurRadius: 28,
    offset: const Offset(0, 10),
  );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryLight,
      surface: white,
      onPrimary: white,
      onSecondary: white,
      onSurface: ink,
    ),
    scaffoldBackgroundColor: Color(0xFFEFFEFD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: inkMid, size: 24),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryFaint.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      labelStyle: TextStyle(color: inkSoft, fontSize: 14),
      hintStyle: TextStyle(color: inkSoft.withValues(alpha: 0.6), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
    ),
    dividerTheme: DividerThemeData(
      color: ink.withValues(alpha: 0.07),
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? white : inkSoft),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : ink.withValues(alpha: 0.12)),
    ),
    iconTheme: const IconThemeData(color: inkMid, size: 22),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ink,    letterSpacing: -0.5, height: 1.2),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: inkMid, letterSpacing: -0.3),
      titleLarge:    TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: inkMid),
      titleMedium:   TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: inkMid),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: inkMid, height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: inkSoft, height: 1.55),
      labelSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: inkSoft, letterSpacing: 0.5),
    ),
  );

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: primary,
      surface: _darkSurface,
      onPrimary: ink,
      onSecondary: white,
      onSurface: white,
    ),
    scaffoldBackgroundColor: _darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: white, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: primaryLight, size: 22),
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: primaryLight, width: 1.8)),
      labelStyle: const TextStyle(color: primaryLight, fontSize: 14),
      hintStyle: TextStyle(color: white.withValues(alpha: 0.35), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
    ),
    iconTheme: const IconThemeData(color: primaryLight, size: 22),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: white,       letterSpacing: -0.5, height: 1.2),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: white),
      titleLarge:    TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: white),
      titleMedium:   TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: white),
      bodyLarge:     TextStyle(fontSize: 16, color: white,       height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, color: primaryLight, height: 1.55),
      labelSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryLight, letterSpacing: 0.5),
    ),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color getConfidenceColor(String level) =>
      level == 'high' ? primary : level == 'medium' ? primaryLight : inkSoft;

  static Color getStateColor(String state) =>
      state.contains('calm') ? primaryLight : primary;
}
