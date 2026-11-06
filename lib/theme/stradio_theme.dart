import 'package:flutter/material.dart';

/// Official STRADIO Brand Identity & Design System Tokens.
///
/// Philosophy: "Stride + Audio: Movement becomes music"
/// Dial: ENERGY 3 / RHYTHM 2 / MOTION 2
///
/// One-line design rationale (R-31):
/// - Palette: Midnight (#191923) and Warm Ivory (#F5F0E8) provide 14.1:1 WCAG AAA
///   contrast for instant legibility during outdoor or night runs, accented by
///   Sonic Coral (#FF765F) for primary actions and Rhythm Violet (#A995DB) for
///   reactive tempo telemetry.
/// - Typography: Sora with tabular figures keeps live step and cadence readouts
///   horizontally stable at 100 Hz, while Inter keeps labels and diagnostics legible.
/// - Border Radius Hierarchy (R-11): 24px for hero containers/bottom decks,
///   16px for secondary metric cards, and 12px for inputs and technical controls.
class StradioColors {
  const StradioColors._();

  /// Deep Midnight background (#191923).
  static const Color midnight = Color(0xFF191923);

  /// Warm Ivory primary typography and readouts (#F5F0E8) - 14.1:1 contrast on Midnight.
  static const Color warmIvory = Color(0xFFF5F0E8);

  /// Secondary Warm Ivory for labels (#CBC5BA) - 8.9:1 contrast on Midnight, 6.4:1 on SurfaceDark.
  static const Color mutedIvory = Color(0xFFCBC5BA);

  /// Vibrant Accent / Primary CTA: Sonic Coral (#FF765F).
  static const Color sonicCoral = Color(0xFFFF765F);

  /// Rhythm & Tempo Accent: Rhythm Violet (#A995DB).
  static const Color rhythmViolet = Color(0xFFA995DB);

  /// Elevated Dark Surface (#2A2B3D).
  static const Color surfaceDark = Color(0xFF2A2B3D);

  /// Subtle Elevated Surface for nested controls (#212232).
  static const Color surfaceSubtle = Color(0xFF212232);

  /// Structural Dark Border (#46506E).
  static const Color borderDark = Color(0xFF46506E);

  /// Solid Live Status Green (#3DDC84) - solid indicator when recording is active (R-19).
  static const Color statusLive = Color(0xFF3DDC84);

  /// Paused / Standby Status Amber (#FFB74D).
  static const Color statusPaused = Color(0xFFFFB74D);

  /// Error / Alert Coral Red (#FF8A80).
  static const Color statusError = Color(0xFFFF8A80);

  /// Hero Linear Gradient from Sonic Coral (#FF765F) to Rhythm Violet (#A995DB).
  static const LinearGradient heroGradient = LinearGradient(
    colors: [sonicCoral, rhythmViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class StradioRadii {
  const StradioRadii._();

  /// Hero containers, floating control deck, and modal sheet top corners (24px).
  static const double hero = 24.0;

  /// Secondary stat cards, rhythm signature card, and diagnostic cards (16px).
  static const double card = 16.0;

  /// Form inputs, segment selectors, and technical buttons (12px).
  static const double control = 12.0;

  /// Compact status tags (8px).
  static const double tag = 8.0;
}

class StradioTypography {
  const StradioTypography._();

  static const List<String> _soraFallback = [
    'Inter',
    'Roboto',
    'Segoe UI',
    'sans-serif',
  ];

  static const List<String> _interFallback = [
    'Roboto',
    'Segoe UI',
    'sans-serif',
  ];

  /// Sora bold display style with tabular figures for primary step and SPM readouts.
  static TextStyle soraMetric({
    double fontSize = 56,
    FontWeight fontWeight = FontWeight.w800,
    Color color = StradioColors.warmIvory,
    double letterSpacing = -1.2,
    double height = 1.05,
  }) {
    return TextStyle(
      fontFamily: 'Sora',
      fontFamilyFallback: _soraFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Sora heading style for brand wordmarks, section headers, and card titles.
  static TextStyle soraHeading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StradioColors.warmIvory,
    double letterSpacing = -0.3,
    double height = 1.25,
  }) {
    return TextStyle(
      fontFamily: 'Sora',
      fontFamilyFallback: _soraFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Inter readable body copy and helper descriptions.
  static TextStyle interBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = StradioColors.warmIvory,
    double letterSpacing = 0.0,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: _interFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Inter structured label with tabular figures for secondary runner metrics.
  static TextStyle interLabel({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = StradioColors.mutedIvory,
    double letterSpacing = 0.6,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: _interFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class StradioTheme {
  const StradioTheme._();

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: StradioColors.sonicCoral,
      onPrimary: StradioColors.midnight,
      secondary: StradioColors.rhythmViolet,
      onSecondary: StradioColors.midnight,
      surface: StradioColors.surfaceDark,
      onSurface: StradioColors.warmIvory,
      error: StradioColors.statusError,
      onError: StradioColors.midnight,
      outline: StradioColors.borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: StradioColors.midnight,
      canvasColor: StradioColors.midnight,
      dividerColor: StradioColors.borderDark,
      focusColor: StradioColors.sonicCoral.withValues(alpha: 0.28),
      hoverColor: StradioColors.rhythmViolet.withValues(alpha: 0.14),
      splashColor: StradioColors.sonicCoral.withValues(alpha: 0.2),
      appBarTheme: AppBarTheme(
        backgroundColor: StradioColors.midnight,
        foregroundColor: StradioColors.warmIvory,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: StradioTypography.soraHeading(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
        iconTheme: const IconThemeData(
          color: StradioColors.warmIvory,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: StradioColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.card),
          side: const BorderSide(color: StradioColors.borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StradioColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: StradioTypography.interLabel(
          fontSize: 13,
          color: StradioColors.mutedIvory,
          letterSpacing: 0.2,
        ),
        hintStyle: StradioTypography.interBody(
          fontSize: 13,
          color: StradioColors.mutedIvory,
        ),
        helperStyle: StradioTypography.interBody(
          fontSize: 12,
          color: StradioColors.mutedIvory,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: const BorderSide(color: StradioColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: const BorderSide(color: StradioColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: const BorderSide(
            color: StradioColors.sonicCoral,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return StradioColors.borderDark.withValues(alpha: 0.45);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE86049);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFFF8672);
            }
            return StradioColors.sonicCoral;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return StradioColors.mutedIvory;
            }
            return StradioColors.midnight;
          }),
          overlayColor: WidgetStatePropertyAll(
            StradioColors.warmIvory.withValues(alpha: 0.12),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: StradioColors.warmIvory, width: 2);
            }
            return BorderSide.none;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.control),
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click;
          }),
          textStyle: WidgetStatePropertyAll(
            StradioTypography.soraHeading(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: StradioColors.midnight,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return StradioColors.mutedIvory;
            }
            return StradioColors.warmIvory;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return StradioColors.borderDark.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.hovered)) {
              return StradioColors.borderDark.withValues(alpha: 0.2);
            }
            return StradioColors.surfaceSubtle;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(
                color: StradioColors.sonicCoral,
                width: 2,
              );
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(
                color: StradioColors.rhythmViolet,
                width: 1.5,
              );
            }
            return const BorderSide(color: StradioColors.borderDark, width: 1);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.control),
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click;
          }),
          textStyle: WidgetStatePropertyAll(
            StradioTypography.interLabel(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StradioColors.warmIvory,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: const WidgetStatePropertyAll(StradioColors.warmIvory),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(
                color: StradioColors.sonicCoral,
                width: 1.5,
              );
            }
            return BorderSide.none;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.control),
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StradioColors.warmIvory;
          }
          return StradioColors.mutedIvory;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StradioColors.sonicCoral;
          }
          return StradioColors.surfaceSubtle;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return StradioColors.warmIvory;
          }
          if (states.contains(WidgetState.selected)) {
            return StradioColors.sonicCoral;
          }
          return StradioColors.borderDark;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: StradioColors.surfaceDark,
        contentTextStyle: StradioTypography.interBody(
          color: StradioColors.warmIvory,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          side: const BorderSide(color: StradioColors.borderDark),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

