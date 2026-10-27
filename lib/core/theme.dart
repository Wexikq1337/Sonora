import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildSonoraTheme(AppPalette p) {
  final ColorScheme scheme = ColorScheme.dark(
    primary: p.accent,
    onPrimary: Colors.black,
    secondary: p.accent2,
    onSecondary: Colors.black,
    surface: p.bg1,
    onSurface: p.text,
    error: const Color(0xFFED4245),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: p.bg1,
    splashFactory: InkRipple.splashFactory,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.bg1,
      contentTextStyle: TextStyle(color: p.text, fontSize: 12.5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: p.bg1.withOpacity(0.97),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      textStyle: TextStyle(color: p.text, fontSize: 11.5),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withOpacity(0.25),
      selectionHandleColor: p.accent,
    ),
  );
}
