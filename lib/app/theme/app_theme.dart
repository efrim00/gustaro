import 'package:flutter/material.dart';

/// Colours from the Gustaro home design.
abstract final class GColors {
  static const red = Color(0xFFD22B3B);
  static const ink = Color(0xFF111111);
  static const white = Colors.white;
  static const textMuted = Color(0xFF5C5C5C);
  static const textSoft = Color(0xFF4A4A4A);
  static const line = Color(0xFFE6E6E6);
  static const surface = Color(0xFFF5F5F5);
  static const navInactive = Color(0xFF9A9A9A);
  static const ok = Color(0xFF1B7F3B);
}

/// Type scale from the design: Onest for text, Domine for titles, Caveat
/// for the handwritten accent.
abstract final class GText {
  static const _onest = 'Onest';
  static const _domine = 'Domine';

  static const display = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 25,
    height: 30 / 25,
    letterSpacing: -0.5,
    color: GColors.ink,
  );
  static const title = TextStyle(
    fontFamily: _domine,
    fontWeight: FontWeight.w600,
    fontSize: 25,
    height: 30 / 25,
    letterSpacing: -0.25,
    color: GColors.ink,
  );
  static const cardTitle = TextStyle(
    fontFamily: _domine,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: GColors.ink,
  );
  static const body = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
    color: GColors.ink,
  );
  static const bodyMuted = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
    color: GColors.textMuted,
  );
  static const small = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.35,
    color: GColors.textMuted,
  );
  static const label = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.3,
    color: GColors.ink,
  );
  static const button = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.2,
    color: GColors.ink,
  );
  static const buttonSmall = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
    color: GColors.ink,
  );
  static const script = TextStyle(
    fontFamily: 'Caveat',
    fontWeight: FontWeight.w700,
    fontSize: 36,
    height: 1,
    color: GColors.white,
  );
}

/// Layout constants shared by every screen.
abstract final class GLayout {
  static const gutter = 20.0;

  /// Content stays readable on anything wider than a large phone.
  static const maxContentWidth = 560.0;
}

ThemeData buildGustaroTheme() {
  const scheme = ColorScheme.light(
    primary: GColors.red,
    onPrimary: GColors.white,
    secondary: GColors.ink,
    onSecondary: GColors.white,
    surface: GColors.white,
    onSurface: GColors.ink,
    error: GColors.red,
  );
  const squareBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: GColors.ink),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Onest',
    scaffoldBackgroundColor: GColors.white,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: GColors.white,
      foregroundColor: GColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Domine',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: GColors.ink,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: GColors.white,
      border: squareBorder,
      enabledBorder: squareBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: GColors.ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: GColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: GColors.red, width: 2),
      ),
      hintStyle: GText.bodyMuted,
      errorStyle: TextStyle(
        fontFamily: 'Onest',
        fontSize: 13,
        color: GColors.red,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(),
      showDragHandle: true,
      dragHandleColor: GColors.line,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: GColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: GColors.ink,
      contentTextStyle: TextStyle(
        fontFamily: 'Onest',
        fontSize: 15,
        color: GColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: GColors.red),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(),
      side: const BorderSide(color: GColors.ink),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? GColors.red
            : Colors.transparent,
      ),
    ),
    dividerTheme: const DividerThemeData(color: GColors.line, thickness: 1),
  );
}
