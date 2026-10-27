import 'package:flutter/material.dart';

class AppTheme {
  // M3 セマンティックカラー定義
  static const Color primary = Color(0xFF10B981); // Emerald / Forest Green
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFD1FAE5);
  static const Color onPrimaryContainer = Color(0xFF047857);

  static const Color secondary = Color(0xFFF59E0B); // Amber Accent (Fat)
  static const Color onSecondary = Colors.white;
  
  static const Color tertiary = Color(0xFF3B82F6); // Blue Accent (Carbs)
  static const Color onTertiary = Colors.white;

  static const Color surface = Color(0xFFF9FAFB);
  static const Color onSurface = Color(0xFF1F2937); // No pure black (#000000)
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color onSurfaceVariant = Color(0xFF4B5563);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  /// OS標準日本語フォント優先スタック（Skia / CanvasKitが直接解決可能な日本語フォント名）
  static const List<String> systemFontFallbacks = [
    // iOS / macOS
    'Hiragino Sans',
    'Hiragino Kaku Gothic ProN',
    // Windows
    'Yu Gothic UI',
    'Yu Gothic',
    'Meiryo',
    'MS PGothic',
    // Android / Linux / ChromeOS
    'Noto Sans CJK JP',
    'Noto Sans JP',
    // Webフォールバック
    'sans-serif',
  ];

  /// 栄養素やカロリー数値用の等幅数字（Tabular Figures）TextStyleヘルパー
  static TextStyle tabularNumbers({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'NotoSansJP',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamilyFallback: systemFontFallbacks,
    );
  }

  /// アプリ共通テーマ（内包フォントNotoSansJPによる通信不要・最速即時描画）
  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final baseTextTheme = ThemeData.light().textTheme;
    
    // ベースとなるウェイトとカラーのスタイル定義
    TextStyle style({required FontWeight weight, required Color color, double? size}) => TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: weight,
      color: color,
      fontSize: size,
      fontFamilyFallback: systemFontFallbacks,
    );

    final customTextTheme = baseTextTheme.copyWith(
      displayLarge: style(weight: FontWeight.w600, color: onSurface),
      displayMedium: style(weight: FontWeight.w600, color: onSurface),
      displaySmall: style(weight: FontWeight.w600, color: onSurface),
      headlineLarge: style(weight: FontWeight.w600, color: onSurface),
      headlineMedium: style(weight: FontWeight.w600, color: onSurface),
      headlineSmall: style(weight: FontWeight.w600, color: onSurface),
      titleLarge: style(weight: FontWeight.w600, color: onSurface),
      titleMedium: style(weight: FontWeight.w600, color: onSurface),
      titleSmall: style(weight: FontWeight.w600, color: onSurface),
      bodyLarge: style(weight: FontWeight.w400, color: onSurface),
      bodyMedium: style(weight: FontWeight.w400, color: onSurface),
      bodySmall: style(weight: FontWeight.w400, color: onSurfaceVariant),
      labelLarge: style(weight: FontWeight.w400, color: onSurface),
      labelMedium: style(weight: FontWeight.w400, color: onSurfaceVariant),
      labelSmall: style(weight: FontWeight.w400, color: onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      fontFamily: 'NotoSansJP',
      fontFamilyFallback: systemFontFallbacks,
      textTheme: customTextTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        tertiary: tertiary,
        onTertiary: onTertiary,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        titleTextStyle: customTextTheme.titleLarge?.copyWith(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: outline, width: 1),
        ),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryContainer,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return customTextTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onPrimaryContainer,
            );
          }
          return customTextTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: onSurfaceVariant,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(88, 48),
          textStyle: customTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: onPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 48),
          textStyle: customTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 48),
          textStyle: customTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: primary,
          ),
        ),
      ),
    );
  }
}
