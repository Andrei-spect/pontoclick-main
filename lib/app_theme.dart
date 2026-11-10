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

  // Mesmos tons de status, um pouco mais fechados: usados como FUNDO de botão
  // com texto branco por cima (os tons acima não têm contraste suficiente).
  static const statusGreenStrong = Color(0xFF1E9E4A);
  static const statusOrangeStrong = Color(0xFFC77A00);
  static const statusBlueStrong = Color(0xFF2F6FDB);
  static const statusRedStrong = Color(0xFFDC3B3B);

  // --- Tema escuro ---
  static const darkBg = Color(0xFF000000); // void-black
  static const darkCard = Color(0xFF191919); // graphite
  static const darkCardRaised = Color(0xFF222222); // superfície dentro de um card / toasts
  static const darkDivider = Color(0xFF3D3D3D); // charcoal
  static const darkHairline = Color(0xFF2A2A2A); // separador entre linhas de um card
  static const darkTextPrimary = Color(0xFFFFFFFF); // paper-white
  static const darkTextSecondary = Color(0xFFCCCCCC); // fog
  static const darkTextTertiary = Color(0xFF9E9E9E); // ash
  static const darkVioletText = Color(0xFFA9A8FF); // violeta legível sobre fundo escuro

  // --- Tema claro (extensão pedida pelo usuário; Umbrel original é dark-only) ---
  static const lightBg = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF2F1EE);
  static const lightCardRaised = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE4E2DD);
  static const lightHairline = Color(0xFFE4E2DD);
  static const lightTextPrimary = Color(0xFF101010);
  static const lightTextSecondary = Color(0xFF4B4B46);
  // Ajustado (era #797985) para atingir contraste 4.5:1 sobre o card claro.
  static const lightTextTertiary = Color(0xFF66666F);
  // No claro o peach puro fica com pouco contraste sobre branco — versão
  // mais escura, mesma intenção de marca (ajustada para 4.5:1).
  static const lightEmberPeach = Color(0xFFA8613B);
  static const lightVioletText = Color(0xFF4341D9);
}

/// Escala tipográfica do Umbrel (fonte Inter). "height" no Flutter é a
/// razão line-height/font-size, o que bate direto com os valores do
/// sistema original.
class AppText {
  AppText._();

  static TextStyle caption({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 12, height: 1.3, letterSpacing: 0, color: color, fontWeight: weight ?? FontWeight.w400);

  /// 13 px — rótulos de campo, títulos de seção, textos de apoio.
  static TextStyle label({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 13, height: 1.35, letterSpacing: 0, color: color, fontWeight: weight ?? FontWeight.w500);

  /// 15 px — texto de listas, cards e botões.
  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: 15, height: 1.4, letterSpacing: 0, color: color, fontWeight: weight ?? FontWeight.w400);

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

  /// Números que mudam (relógio, horários, totais): largura fixa para não "pular".
  static TextStyle numeric(TextStyle base) => base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Radii padronizados do sistema.
class AppRadius {
  AppRadius._();
  static const cards = 16.0;
  static const tiles = 10.0; // quadradinho de ícone dentro de listas
  static const inner = 12.0; // blocos dentro de um card (células, avisos)
  static const icons = 5.0;
  static const pills = 99.0;
  static const images = 12.0;
  static const inputs = 24.0;
  static const buttons = 24.0;
}

/// Espaçamentos (múltiplos de 4).
class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const page = 20.0; // margem lateral das telas
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        raised: AppColors.darkCardRaised,
        divider: AppColors.darkDivider,
        text: AppColors.darkTextPrimary,
        text2: AppColors.darkTextSecondary,
        peach: AppColors.emberPeach,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        card: AppColors.lightCard,
        raised: AppColors.lightCardRaised,
        divider: AppColors.lightDivider,
        text: AppColors.lightTextPrimary,
        text2: AppColors.lightTextSecondary,
        peach: AppColors.lightEmberPeach,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color raised,
    required Color divider,
    required Color text,
    required Color text2,
    required Color peach,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark
        ? ColorScheme.dark(primary: AppColors.twilightViolet, secondary: peach, surface: card, onSurface: text, error: AppColors.statusRed)
        : ColorScheme.light(primary: AppColors.twilightViolet, secondary: peach, surface: card, onSurface: text, error: AppColors.statusRed);

    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: divider,
      primaryColor: AppColors.twilightViolet,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: text),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: raised,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cards),
          side: BorderSide(color: isDark ? const Color(0xFF333333) : divider),
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, height: 1.45, color: text2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.twilightViolet : divider),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.twilightViolet),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.twilightViolet,
        selectionColor: AppColors.twilightViolet.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.twilightViolet,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: raised, borderRadius: BorderRadius.circular(8), border: Border.all(color: divider)),
        textStyle: GoogleFonts.inter(fontSize: 12, color: text),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        dialHandColor: AppColors.twilightViolet,
      ),
    );
    return base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme));
  }
}

/// Acesso rápido às cores de texto/acento corretas para o tema atual,
/// sem precisar checar Theme.of(context).brightness toda hora nas telas.
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary => isDarkMode ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get accentPeach => isDarkMode ? AppColors.emberPeach : AppColors.lightEmberPeach;

  /// Violeta para TEXTO e ícones (o #5351F3 puro tem pouco contraste sobre o preto).
  Color get violetText => isDarkMode ? AppColors.darkVioletText : AppColors.lightVioletText;

  /// Fundo suave violeta (aba ativa, avatar, ícones de menu).
  Color get violetSoft => AppColors.twilightViolet.withValues(alpha: isDarkMode ? 0.22 : 0.12);
  Color get peachSoft => accentPeach.withValues(alpha: isDarkMode ? 0.16 : 0.14);
  Color get cardRaised => isDarkMode ? AppColors.darkCardRaised : AppColors.lightCardRaised;
  Color get hairline => isDarkMode ? AppColors.darkHairline : AppColors.lightHairline;
}
