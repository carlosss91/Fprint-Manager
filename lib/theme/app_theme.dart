import 'package:flutter/material.dart';

/// Paleta cromática oficial inspirada en elementary OS / Pantheon y GTK moderno.
class AppColors {
  AppColors._();

  // Acentos primarios (elementary Blueberry)
  static const Color primaryLight = Color(0xFF3689E6);
  static const Color primaryDark = Color(0xFF64BAFF);

  // Éxito (elementary Mint)
  static const Color successLight = Color(0xFF28B463);
  static const Color successDark = Color(0xFF2EC27E);

  // Advertencia (elementary Banana)
  static const Color warningLight = Color(0xFFE09F1F);
  static const Color warningDark = Color(0xFFF9C440);

  // Error (elementary Strawberry)
  static const Color errorLight = Color(0xFFC6262E);
  static const Color errorDark = Color(0xFFED5353);

  // Superficies modo claro
  static const Color canvasLight = Color(0xFFF7F8FA);
  static const Color sidebarLight = Color(0xFFF1F3F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE1E4E8);
  static const Color textPrimaryLight = Color(0xFF1A1D21);
  static const Color textSecondaryLight = Color(0xFF5A626D);

  // Superficies modo oscuro
  static const Color canvasDark = Color(0xFF1C1D20);
  static const Color sidebarDark = Color(0xFF23252A);
  static const Color surfaceDark = Color(0xFF2A2C32);
  static const Color borderDark = Color(0xFF393C44);
  static const Color textPrimaryDark = Color(0xFFF2F4F7);
  static const Color textSecondaryDark = Color(0xFFA0A8B3);

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? successDark : successLight;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warningDark : warningLight;

  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorDark : errorLight;

  static Color canvas(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? canvasDark : canvasLight;

  static Color sidebar(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? sidebarDark : sidebarLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
}

/// Configuración de temas Material 3 optimizada para escritorio Linux / elementary OS.
class AppTheme {
  AppTheme._();

  static const TextStyle tabularFiguresStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      surface: AppColors.surfaceLight,
      error: AppColors.errorLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvasLight,
      dividerColor: AppColors.borderLight,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return AppColors.primaryLight.withValues(alpha: 0.16);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.textPrimaryLight.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2328),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      surface: AppColors.surfaceDark,
      error: AppColors.errorDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvasDark,
      dividerColor: AppColors.borderDark,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return AppColors.primaryDark.withValues(alpha: 0.20);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: const Color(0xFF101214),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderDark),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

