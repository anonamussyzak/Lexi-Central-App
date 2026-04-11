import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final kirbyTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFF5F7),
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFB7C5),
      primary: const Color(0xFFFFB7C5),
      secondary: const Color(0xFFB8F2E6),
      tertiary: const Color(0xFFFFF5B7),
      surface: Colors.white,
      background: const Color(0xFFFFF5F7),
    ),
    
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFF6B8B),
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFF6B8B),
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF4A4A4A),
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6A6A6A),
      ),
    ),
    
    cardTheme: CardTheme(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 6,
      shadowColor: const Color(0xFFFFB7C5).withOpacity(0.3),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFB7C5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 4,
        shadowColor: const Color(0xFFFFB7C5).withOpacity(0.4),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB8F2E6),
        foregroundColor: const Color(0xFF2A7F7E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFB7C5),
        side: const BorderSide(color: Color(0xFFFFB7C5), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFFB7C5),
      unselectedItemColor: const Color(0xFFB8B8B8),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
    ),
    
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconColor: const Color(0xFFFFB7C5),
      unselectedIconColor: const Color(0xFFB8B8B8),
      selectedLabelTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFFFB7C5),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFB8B8B8),
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      elevation: 8,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFFFF6B8B),
      elevation: 4,
      shadowColor: const Color(0xFFFFB7C5).withOpacity(0.3),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFF6B8B),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFFB7C5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFFB7C5), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.nunito(color: const Color(0xFFB8B8B8)),
      hintStyle: GoogleFonts.nunito(color: const Color(0xFFD8D8D8)),
    ),
  );
}
