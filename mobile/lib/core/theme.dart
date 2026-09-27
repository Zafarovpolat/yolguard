import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
import 'package:google_fonts/google_fonts.dart';

import 'motion.dart';

/// Дизайн-система Yo'lGuard: минималистичная редакторская монохромия на тёплой
/// «костяной» базе + настоящее light liquid glass. Почти чёрный текст на светлом
/// фоне, чернильный акцент (кнопки чёрные, без цвета), цвет — только у статусов
/// дел (приглушённая семантика). Типографика: гротеск Onest (кириллица), serif
/// Instrument Serif курсивом для латинского логотипа, JetBrains Mono для меток.
/// Стеклянные панели с specular-фасками, тонкие волоски-границы, мягкие тени.
class AppTheme {
  AppTheme._();

  // — Нейтральная тёплая шкала (почти чёрный текст на «костяной» базе) —
  static const Color _ink = Color(0xFF141210); // основной текст / акцент CTA
  static const Color inkSoft = Color(0xFF4A4742); // сильный вторичный
  static const Color _muted = Color(0xFF8B867E); // третичный текст / подписи
  static const Color _bg = Color(0xFFF6F5F2); // фон экрана (тёплый bone)
  static const Color bgTint = Color(0xFFFBFAF8); // подложка секций/скелетов
  static const Color _surface =
      Color(0xFFFFFFFF); // непрозрачные панели (поля/диалоги)
  static const Color surfaceAlt = Color(0xFFF1EFEA);
  static const Color _line = Color(0x14141210); // границы-волоски (ink ~8%)

  // — «Акцент» монохромный: интеракция = чернильный, без цвета —
  static const Color _accent = Color(0xFF141210); // ink — кнопки/фокус/иконки
  static const Color accentDark = Color(0xFF000000); // нажатое состояние
  static const Color accentSoft = Color(0x14141210); // тонировка (ink ~8%)
  static const Color accent2 =
      Color(0xFFB9B3A7); // тёплый камень — только блики

  // — Семантика статусов: приглушённая, читаемая на светлом —
  static const Color green = Color(0xFF2E7D57);
  static const Color greenSoft = Color(0x1F2E7D57);
  static const Color red = Color(0xFFC0392B);
  static const Color redSoft = Color(0x1FC0392B);
  static const Color amber = Color(0xFF9A6A12);
  static const Color amberSoft = Color(0x249A6A12);

  // Публичные алиасы (обратная совместимость со всеми экранами и case_labels).
  static const Color ink = _ink;
  static const Color muted = _muted;
  static const Color accent = _accent;
  static const Color line = _line;
  static const Color bg = _bg;
  static const Color surface = _surface;

  // — Токены light liquid glass (полупрозрачное белое + чернильные волоски) —
  static const Color glassFill =
      Color(0x8CFFFFFF); // матовая заливка (белый ~55%)
  static const Color glassFillStrong =
      Color(0xB3FFFFFF); // плотнее — чипы/кнопки (~70%)
  static const Color glassStroke =
      Color(0x1F141210); // волосок-граница (ink 12%)
  static const Color glassHighlight = Color(0xE6FFFFFF); // specular-блик (~90%)

  // Радиусы: чёткая редакторская геометрия (внешний = внутренний + отступ).
  static const double rCard = 16;
  static const double rInner = 12;
  static const double rField = 12;
  static const double rButton = 12;

  /// Мягкая тёплая тень для карточек и оверлеев на светлом фоне.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14141210), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A141210), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Моноширинный стиль для кодов, госномеров и меняющихся чисел (табличные цифры).
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double spacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? _ink,
        letterSpacing: spacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Редакторский serif-акцент (Instrument Serif, курсив). ТОЛЬКО латиница —
  /// логотип «Yo'lGuard» и крупные числа: у шрифта нет кириллического сабсета.
  static TextStyle serif({
    double size = 28,
    FontWeight weight = FontWeight.w400,
    Color? color,
    FontStyle style = FontStyle.italic,
    double spacing = -0.5,
  }) =>
      GoogleFonts.instrumentSerif(
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color ?? _ink,
        letterSpacing: spacing,
        height: 1.0,
      );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      primary: _accent,
      surface: _surface,
      onSurface: _ink,
      error: red,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      // Прозрачный фон — под ним живёт глобальный AmbientBackground,
      // поэтому «жидкое стекло» читается на любом экране.
      scaffoldBackgroundColor: Colors.transparent,
    );
    final text = GoogleFonts.onestTextTheme(base.textTheme)
        .apply(bodyColor: _ink, displayColor: _ink);

    // Плавные переходы между экранами — «анимации везде».
    const spring = SpringPageTransitionsBuilder();

    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4, color: inkSoft),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: spring,
        TargetPlatform.iOS: spring,
        TargetPlatform.macOS: spring,
        TargetPlatform.windows: spring,
        TargetPlatform.linux: spring,
        TargetPlatform.fuchsia: spring,
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.onest(
          color: _ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
          side: const BorderSide(color: _line),
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: _line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
        border: _border(_line),
        enabledBorder: _border(_line),
        focusedBorder: _border(_accent, width: 1.6),
        errorBorder: _border(red),
        focusedErrorBorder: _border(red, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE4E1D9),
          disabledForegroundColor: const Color(0xFFA8A399),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rButton)),
          textStyle:
              GoogleFonts.onest(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          backgroundColor: glassFillStrong,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: glassStroke, width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rButton)),
          textStyle:
              GoogleFonts.onest(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          textStyle:
              GoogleFonts.onest(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassFill,
        selectedColor: accentSoft,
        side: const BorderSide(color: glassStroke),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(rInner)),
        labelStyle: GoogleFonts.onest(
            fontSize: 13, fontWeight: FontWeight.w600, color: inkSoft),
        secondaryLabelStyle: GoogleFonts.onest(
            fontSize: 13, fontWeight: FontWeight.w700, color: _accent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? _accent
                : const Color(0xFFD9D6CE)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle:
            GoogleFonts.onest(color: Colors.white, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(rInner)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? _accent : _muted),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _accent),
    );
  }

  static OutlineInputBorder _border(Color c, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(rField),
        borderSide: BorderSide(color: c, width: width),
      );
}
