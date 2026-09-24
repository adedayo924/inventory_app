import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette: Emerald Green & White
  static const Color primaryGreen = Color(0xFF10B981); // Emerald 500
  static const Color primaryDarkGreen = Color(0xFF047857); // Emerald 700
  static const Color primaryMint = Color(0xFF34D399); // Emerald 400
  static const Color accentLight = Color(0xFF6EE7B7); // Emerald 300
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Backgrounds - Dark Theme (Deep Obsidian / Graphite)
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color bgDarkCard = Color(0xFF111827);
  static const Color bgDarkCardHover = Color(0xFF1F2937);
  static const Color borderDark = Color(0xFF1F2937);

  // Backgrounds - Light Theme
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color bgLightCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Status & Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFF43F5E);
  static const Color infoSky = Color(0xFF0EA5E9);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  // Text Colors
  static const Color textDarkPrimary = Color(0xFFF9FAFB);
  static const Color textDarkSecondary = Color(0xFF9CA3AF);
  static const Color textDarkMuted = Color(0xFF6B7280);

  static const Color textLightPrimary = Color(0xFF111827);
  static const Color textLightSecondary = Color(0xFF4B5563);
  static const Color textLightMuted = Color(0xFF9CA3AF);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: primaryMint,
      surface: bgDarkCard,
      error: dangerRed,
      onPrimary: pureWhite,
    ),
    cardTheme: CardThemeData(
      color: bgDarkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark, width: 1),
      ),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textDarkPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111827),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textDarkMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: pureWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: primaryDarkGreen,
      surface: bgLightCard,
      error: dangerRed,
      onPrimary: pureWhite,
    ),
    cardTheme: CardThemeData(
      color: bgLightCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight, width: 1),
      ),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgLightCard,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textLightPrimary),
      titleTextStyle: TextStyle(color: textLightPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textLightMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: pureWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
  );
}
