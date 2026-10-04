import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// 栄養素やカロリー数値用の等幅数字（Tabular Figures）TextStyleヘルパー
  static TextStyle tabularNumbers({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.notoSansJp(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// キャッシュされたThemeData（毎フレームのフォントオブジェクト再生成を抑止）
  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final baseTextTheme = ThemeData.light().textTheme;
    const fontFallbacks = [
      'Noto Sans JP',
      'Hiragino Sans',
      'Meiryo',
      'Yu Gothic',
      'sans-serif',
    ];
    
    // Noto Sans JP を適用し、ウェイトを w400(本文/ラベル) と w600(タイトル/数値) に統一
    final notoSansTextTheme = GoogleFonts.notoSansJpTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      displayMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      displaySmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      headlineLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      headlineMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      headlineSmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      titleLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      titleMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      titleSmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurface),
      bodyMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurface),
      bodySmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurfaceVariant),
      labelLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurface),
      labelMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurfaceVariant),
      labelSmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, color: onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: notoSansTextTheme,
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
        titleTextStyle: GoogleFonts.notoSansJp(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // M3 Medium Radius
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
            return GoogleFonts.notoSansJp(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onPrimaryContainer,
            );
          }
          return GoogleFonts.notoSansJp(
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
          minimumSize: const Size(88, 48), // 48dp minimum touch target
          textStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // M3 Pill Button
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 48),
          textStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 48),
          textStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
