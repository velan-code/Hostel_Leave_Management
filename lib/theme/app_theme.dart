import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A3C5E);
  static const Color studentAccent = Color(0xFF2563EB);
  static const Color wardenAccent = Color(0xFF16A34A);
  static const Color hodAccent = Color(0xFF7C3AED);
  static const Color adminAccent = Color(0xFFEA580C);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color secondary = Color(0xFF16A34A);
  static const Color secondaryContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color surfaceDark = Color(0xFF1E2433);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF14532D),
      surface: surfaceLight,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: textSecondary,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: primary,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceLight,
      indicatorColor: primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary);
        }
        return IconThemeData(color: Color(0xFF94A3B8));
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primaryContainer,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      side: BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF60A5FA),
      onPrimary: Color(0xFF1E3A8A),
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: Color(0xFF4ADE80),
      onSecondary: Color(0xFF14532D),
      surface: surfaceDark,
      onSurface: Color(0xFFF1F5F9),
      surfaceContainerHighest: Color(0xFF2D3748),
      onSurfaceVariant: Color(0xFF94A3B8),
      error: Color(0xFFF87171),
      onError: Colors.white,
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  );
}
