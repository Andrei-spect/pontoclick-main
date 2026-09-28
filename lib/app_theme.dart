import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores do Umbrel Design System.
///
/// Regra do sistema: apenas 2 acentos cromáticos (emberPeach e
/// twilightViolet), rationados — peach só em texto/badge, violeta só em
/// botão de ação principal/commit. As cores de status (verde/laranja/
/// azul/vermelho) são uma EXCEÇÃO funcional combinada com o usuário,
/// usadas exclusivamente para sinalizar o tipo de ponto (entrada,
/// intervalo, volta, saída) — nunca como acento decorativo.
class AppColors {
  AppColors._();

  // Acentos de marca (mesmos nos dois temas)
  static const emberPeach = Color(0xFFE3A081);
  static const twilightViolet = Color(0xFF5351F3);

  // Cores funcionais de status (exceção às 2 cores do sistema)
  static const statusGreen = Color(0xFF34C759);
  static const statusOrange = Color(0xFFF5A623);
  static const statusBlue = Color(0xFF3B82F6);
  static const statusRed = Color(0xFFEF4444);

  // --- Tema escuro ---
  static const darkBg = Color(0xFF000000); // void-black
  static const darkCard = Color(0xFF191919); // graphite
  static const darkDivider = Color(0xFF3D3D3D); // charcoal
  static const darkTextPrimary = Color(0xFFFFFFFF); // paper-white
  static const darkTextSecondary = Color(0xFFCCCCCC); // fog
  static const darkTextTertiary = Color(0xFF9E9E9E); // ash

  // --- Tema claro (extensão pedida pelo usuário; Umbrel original é dark-only) ---
  static const lightBg = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF2F1EE);
  static const lightDivider = Color(0xFFE4E2DD);
  static const lightTextPrimary = Color(0xFF101010);
  static const lightTextSecondary = Color(0xFF4B4B46);
  static const lightTextTertiary = Color(0xFF797985);
  // No claro o peach puro fica com pouco contraste sobre branco — versão
  // levemente mais escura, mesma intenção de marca.
  static const lightEmberPeach = Color(0xFFC47A52);
}

/// Escala tipográfica do Umbrel (fonte Inter). "height" no Flutter é a
/// razão line-height/font-size, o que bate direto com os valores do
/// sistema original.
class AppText {
  AppText._();

  static TextStyle caption({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 12, height: 1.2, letterSpacing: 0, color: color, fontWeight: weight ?? FontWeight.w400);

  static TextStyle body({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 16, height: 1.4, letterSpacing: 0, color: color, fontWeight: weight ?? FontWeight.w400);

  static TextStyle subheading({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 18, height: 1.3, letterSpacing: -0.54, color: color, fontWeight: weight ?? FontWeight.w500);

  static TextStyle headingSm({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 20, height: 1.3, letterSpacing: -0.6, color: color, fontWeight: weight ?? FontWeight.w600);

  static TextStyle heading({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 27, height: 1.24, letterSpacing: -0.81, color: color, fontWeight: weight ?? FontWeight.w600);

  static TextStyle headingLg({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 36, height: 1.2, letterSpacing: -1.08, color: color, fontWeight: weight ?? FontWeight.w600);

  static TextStyle display({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 48, height: 1.1, letterSpacing: -1.44, color: color, fontWeight: weight ?? FontWeight.w600);
}

/// Radii padronizados do sistema.
class AppRadius {
  AppRadius._();
  static const cards = 16.0;
  static const icons = 5.0;
  static const pills = 99.0;
  static const images = 12.0;
  static const inputs = 24.0;
  static const buttons = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        cardColor: AppColors.darkCard,
        dividerColor: AppColors.darkDivider,
        primaryColor: AppColors.twilightViolet,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.twilightViolet,
          secondary: AppColors.emberPeach,
          surface: AppColors.darkCard,
          onSurface: AppColors.darkTextPrimary,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightDivider,
        primaryColor: AppColors.twilightViolet,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: const ColorScheme.light(
          primary: AppColors.twilightViolet,
          secondary: AppColors.lightEmberPeach,
          surface: AppColors.lightCard,
          onSurface: AppColors.lightTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.lightTextPrimary,
        ),
      );
}

/// Acesso rápido às cores de texto/acento corretas para o tema atual,
/// sem precisar checar Theme.of(context).brightness toda hora nas telas.
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get textSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary => isDarkMode ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get accentPeach => isDarkMode ? AppColors.emberPeach : AppColors.lightEmberPeach;
}