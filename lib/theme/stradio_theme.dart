import 'package:flutter/material.dart';

/// Official STRADIO Brand Identity & Design System Tokens.
///
/// Philosophy: "Strava + Audio: Movement becomes music"
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

  /// Warm Ivory / Off-white primary canvas background (#F7F6F2) per Reference 1 & 2.
  static const Color ivoryCanvas = Color(0xFFF7F6F2);

  /// Pure White for elevated cards and floating surfaces (#FFFFFF).
  static const Color whiteSurface = Color(0xFFFFFFFF);

  /// Subtle tint for nested secondary containers (#F0EFEA).
  static const Color surfaceSubtle = Color(0xFFF0EFEA);

  /// Midnight Dark Neutral for high-contrast primary typography and icons (#191923).
  static const Color midnight = Color(0xFF191923);

  /// Secondary neutral for labels, subheaders, and helper copy (#666680).
  static const Color secondaryNeutral = Color(0xFF666680);

  /// Muted neutral for tertiary readouts and disabled states (#9E9EB2).
  static const Color mutedNeutral = Color(0xFF9E9EB2);

  /// Vibrant Accent / Primary CTA: Sonic Coral (#FF765F).
  static const Color sonicCoral = Color(0xFFFF765F);

  /// Rhythm & Tempo Accent: Rhythm Violet (#8B72DE).
  static const Color rhythmViolet = Color(0xFF8B72DE);

  /// Solid Live Status Green (#2EBF6F) - solid indicator when recording is active.
  static const Color statusLive = Color(0xFF2EBF6F);

  /// Paused / Standby Status Amber (#F59E0B).
  static const Color statusPaused = Color(0xFFF59E0B);

  /// Error / Alert Red (#EF4444).
  static const Color statusError = Color(0xFFEF4444);

  /// Subtle border for interactive form inputs, chips, and outlined utility buttons (#E2E0D8).
  static const Color borderSubtle = Color(0xFFE2E0D8);

  /// Legacy dark colors preserved for backward compatibility
  static const Color warmIvory = midnight;
  static const Color mutedIvory = secondaryNeutral;
  static const Color surfaceDark = whiteSurface;
  static const Color borderDark = borderSubtle;

  /// Soft elevation shadow for borderless cards (eliminates AI-slop hairline borders).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x06000000), // 2.5% black
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Hero Linear Gradient from Sonic Coral (#FF765F) to Rhythm Violet (#8B72DE).
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

  /// Borderless Light Theme (Default)
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: StradioColors.sonicCoral,
      onPrimary: Colors.white,
      secondary: StradioColors.rhythmViolet,
      onSecondary: Colors.white,
      surface: StradioColors.whiteSurface,
      onSurface: StradioColors.midnight,
      error: StradioColors.statusError,
      onError: Colors.white,
      outline: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: StradioColors.ivoryCanvas,
      canvasColor: StradioColors.ivoryCanvas,
      dividerColor: Colors.transparent,
      focusColor: StradioColors.sonicCoral.withValues(alpha: 0.18),
      hoverColor: StradioColors.rhythmViolet.withValues(alpha: 0.08),
      splashColor: StradioColors.sonicCoral.withValues(alpha: 0.12),
      appBarTheme: AppBarTheme(
        backgroundColor: StradioColors.ivoryCanvas,
        foregroundColor: StradioColors.midnight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: StradioTypography.soraHeading(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: StradioColors.midnight,
          letterSpacing: 1.8,
        ),
        iconTheme: const IconThemeData(
          color: StradioColors.midnight,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: StradioColors.whiteSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.card),
          side: BorderSide.none,
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
          color: StradioColors.secondaryNeutral,
          letterSpacing: 0.2,
        ),
        hintStyle: StradioTypography.interBody(
          fontSize: 13,
          color: StradioColors.mutedNeutral,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: const BorderSide(color: StradioColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: const BorderSide(color: StradioColors.borderSubtle, width: 1.0),
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
              return StradioColors.surfaceSubtle;
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
              return StradioColors.mutedNeutral;
            }
            return Colors.white;
          }),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999), // Stadium per Ref 1 & 2
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(
            StradioTypography.soraHeading(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
              return StradioColors.mutedNeutral;
            }
            return StradioColors.midnight;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return StradioColors.surfaceSubtle;
            }
            return StradioColors.whiteSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none), // Borderless
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            StradioTypography.interLabel(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StradioColors.midnight,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return StradioColors.secondaryNeutral;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StradioColors.sonicCoral;
          }
          return StradioColors.surfaceSubtle;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: StradioColors.midnight,
        contentTextStyle: StradioTypography.interBody(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          side: BorderSide.none,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Backward-compatible dark theme alias pointing to modern light theme
  static ThemeData get darkTheme => lightTheme;
}

