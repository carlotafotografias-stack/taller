import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta del sistema de diseño de Taller.
class AppColors {
  static const arcilla = Color(0xFFB84A33);
  static const arcillaOscura = Color(0xFF8E3524);
  static const arcillaClara = Color(0xFFD9785F);
  static const arcillaSuave = Color(0xFFF8E7E2);
  static const tinta = Color(0xFF2B2420);
  static const piedra = Color(0xFF6B5F57);
  static const crema = Color(0xFFF6EFE6);
  static const borde = Color(0xFFE7DCCF);
  static const salvia = Color(0xFF557558);
  static const salviaOscura = Color(0xFF3E5A41);
  static const mostaza = Color(0xFFE2A23B);
  static const lavanda = Color(0xFFCFC3EC);
  static const lavandaOscura = Color(0xFF8C79C4);
  static const blanco = Color(0xFFFFFFFF);
}

/// Estilo de títulos (Fraunces).
TextStyle titulo(double size, {Color color = AppColors.tinta}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: FontWeight.w600, color: color, height: 1.15);

ThemeData construirTema() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.arcilla,
      primary: AppColors.arcilla,
      onPrimary: AppColors.blanco,
      secondary: AppColors.salvia,
      surface: AppColors.crema,
      onSurface: AppColors.tinta,
    ),
    scaffoldBackgroundColor: AppColors.crema,
  );

  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.tinta,
      displayColor: AppColors.tinta,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.crema,
      foregroundColor: AppColors.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: titulo(22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.arcilla,
        foregroundColor: AppColors.blanco,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tinta,
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.tinta, width: 1.5),
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.arcillaOscura,
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blanco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borde, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borde, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.arcilla, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.blanco,
      indicatorColor: AppColors.arcillaSuave,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.tinta,
    ),
  );
}
