import 'package:flutter/material.dart';

/// 设计 tokens：深色「夜骑仪表盘」—— Charcoal + 琥珀
/// 与 design-system/MASTER.md、docs/设计文档.md 第 4 节对齐
class Y {
  Y._();

  // surfaces
  static const surface = Color(0xFF0B0F16);
  static const surfaceApp = Color(0xFF111827);
  static const surfaceContainer = Color(0xFF1F2937);
  static const surfaceHigh = Color(0xFF2A3546);

  // text
  static const onSurface = Color(0xFFF9FAFB);
  static const onSurface2 = Color(0xFFD1D5DB);
  static const onSurface3 = Color(0xFF9CA3AF);

  // outline
  static const outline = Color(0x2494A3B8);
  static const outlineStrong = Color(0x4794A3B8);

  // accent 琥珀
  static const primary = Color(0xFFF59E0B);
  static const primarySoft = Color(0x24F59E0B);
  static const primaryLine = Color(0x61F59E0B);
  static const onPrimary = Color(0xFF1A1207);

  static const success = Color(0xFF34D399);
  static const successSoft = Color(0x1F34D399);
  static const error = Color(0xFFF87171);
  static const errorSoft = Color(0x1FF87171);

  // radius
  static const rCard = 20.0;
  static const rCtl = 12.0;

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surfaceApp,
        primary: primary,
        onPrimary: onPrimary,
        onSurface: onSurface,
        error: error,
      ),
      fontFamily: 'MiSans',
      cardTheme: CardTheme(
        color: surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
          side: const BorderSide(color: outline),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: TextStyle(color: onSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 常用文本样式
class YText {
  YText._();
  static const display = TextStyle(
    fontSize: 56, fontWeight: FontWeight.w500, color: Y.onSurface,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [Shadow(color: Color(0x59F59E0B), blurRadius: 42)],
  );
  static const labelCaps = TextStyle(
    fontSize: 10.5, letterSpacing: 2.4, color: Y.onSurface3, fontWeight: FontWeight.w500,
  );
  static const numV = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500, color: Y.onSurface,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
