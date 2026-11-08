import 'package:flutter/material.dart';

/// Official STRADIO Brand Identity & Design System Tokens.
///
/// Philosophy: "Stride + Audio: Movement becomes music"
/// Dial: ENERGY 3 / RHYTHM 2 / MOTION 2
///
/// Design Rationale (Point 7 - Zero AI Slop & Warm Organic Dual System):
/// - Light Theme: Warm Ivory (#F7F6F2) canvas with Pure White (#FFFFFF) borderless
///   surfaces and Midnight (#191923) typography (14.1:1 contrast).
/// - Dark Theme: Deep Obsidian (#121217) canvas with Charcoal (#1E1E26) tonal
///   surfaces and Warm Ivory (#F5F0E8) typography for night runs without harsh glare.
/// - Accents: Sonic Coral (#FF765F) for primary actions/impacts and Rhythm Violet
///   (#8B72DE / #A995DB) for reactive tempo telemetry.
/// - 100% Borderless Architecture: Cards use diffused 2-stage ambient shadows
///   (Light) or tonal surface elevation (Dark) with zero 1px hairline outlines.
/// - Deep Organic Squircle Radii: 28px hero containers, 20px squircle decks,
///   16px nested cards, and 999px stadium pills.
class StradioColors {
  const StradioColors._();

  // --- Light Theme Palette (Warm Ivory - Ref 1 & 2) ---

  /// Warm Ivory / Off-white primary canvas background (#F7F6F2).
  static const Color ivoryCanvas = Color(0xFFF7F6F2);

  /// Pure White for elevated cards and floating surfaces (#FFFFFF).
  static const Color whiteSurface = Color(0xFFFFFFFF);

  /// Subtle warm tint for nested secondary containers (#F0EFEA).
  static const Color surfaceSubtle = Color(0xFFF0EFEA);

  /// Midnight Dark Neutral for high-contrast primary typography and icons (#191923).
  static const Color midnight = Color(0xFF191923);

  /// Secondary neutral for labels, subheaders, and helper copy (#666680).
  static const Color secondaryNeutral = Color(0xFF666680);

  /// Muted neutral for tertiary readouts and disabled states (#9E9EB2).
  static const Color mutedNeutral = Color(0xFF9E9EB2);

  // --- Dark Theme Palette (Deep Obsidian - Night Run) ---

  /// Deep Obsidian primary canvas background (#121217) — never dead #000000.
  static const Color obsidianCanvas = Color(0xFF121217);

  /// Charcoal elevated card surface (#1E1E26) for tonal separation.
  static const Color charcoalSurface = Color(0xFF1E1E26);

  /// Subtle elevated charcoal for nested pills and controls (#282834).
  static const Color charcoalSubtle = Color(0xFF282834);

  /// Warm Ivory primary typography for dark mode (#F5F0E8).
  static const Color ivoryText = Color(0xFFF5F0E8);

  /// Soft Silver secondary typography for dark mode (#9E9EB2).
  static const Color silverSecondary = Color(0xFF9E9EB2);

  /// Muted slate for tertiary dark mode readouts (#68687D).
  static const Color silverMuted = Color(0xFF68687D);

  // --- Brand Accents & Semantic Status ---

  /// Vibrant Accent / Primary CTA: Sonic Coral (#FF765F).
  static const Color sonicCoral = Color(0xFFFF765F);

  /// Rhythm & Tempo Accent (Light): Rhythm Violet (#8B72DE).
  static const Color rhythmViolet = Color(0xFF8B72DE);

  /// Rhythm & Tempo Accent (Dark): Soft Lavender Violet (#A995DB).
  static const Color rhythmVioletDark = Color(0xFFA995DB);

  /// Solid Live Status Green (#2EBF6F) - solid indicator when recording is active.
  static const Color statusLive = Color(0xFF2EBF6F);

  /// Paused / Standby Status Amber (#F59E0B).
  static const Color statusPaused = Color(0xFFF59E0B);

  /// Error / Alert Red (#EF4444).
  static const Color statusError = Color(0xFFEF4444);

  /// Subtle border for form text fields only (#E2E0D8).
  static const Color borderSubtle = Color(0xFFE2E0D8);

  /// Legacy aliases preserved for backward compatibility across existing screens.
  static const Color warmIvory = midnight;
  static const Color mutedIvory = secondaryNeutral;
  static const Color surfaceDark = whiteSurface;
  static const Color borderDark = borderSubtle;

  /// Diffused 2-stage ambient elevation shadow for 100% borderless Light cards (Point 7.2).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black ambient
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000), // 2% black contact
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Subtle tonal shadow for Dark Mode cards (avoids muddy dark halos).
  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x24000000), // 14% black depth
      blurRadius: 20,
      offset: Offset(0, 6),
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

/// Context-aware Warm Organic Dual Theme palette resolver.
class StradioPalette {
  const StradioPalette({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentCoral,
    required this.accentViolet,
    required this.cardShadow,
  });

  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentCoral;
  final Color accentViolet;
  final List<BoxShadow> cardShadow;

  static const StradioPalette light = StradioPalette(
    isDark: false,
    canvas: StradioColors.ivoryCanvas,
    surface: StradioColors.whiteSurface,
    surfaceSubtle: StradioColors.surfaceSubtle,
    textPrimary: StradioColors.midnight,
    textSecondary: StradioColors.secondaryNeutral,
    textMuted: StradioColors.mutedNeutral,
    accentCoral: StradioColors.sonicCoral,
    accentViolet: StradioColors.rhythmViolet,
    cardShadow: StradioColors.cardShadow,
  );

  static const StradioPalette dark = StradioPalette(
    isDark: true,
    canvas: StradioColors.obsidianCanvas,
    surface: StradioColors.charcoalSurface,
    surfaceSubtle: StradioColors.charcoalSubtle,
    textPrimary: StradioColors.ivoryText,
    textSecondary: StradioColors.silverSecondary,
    textMuted: StradioColors.silverMuted,
    accentCoral: StradioColors.sonicCoral,
    accentViolet: StradioColors.rhythmVioletDark,
    cardShadow: StradioColors.darkCardShadow,
  );

  static StradioPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Deep Organic Squircle Corner Radius Hierarchy (Point 7.2).
class StradioRadii {
  const StradioRadii._();

  /// Level 1: Hero containers, Waveform deck, and bottom sheets (28.0px Deep Pebble).
  static const double hero = 28.0;

  /// Level 2: Stride Goal metric deck & Quick Action squircle tiles (20.0px Tactile Tile).
  static const double squircle = 20.0;

  /// Level 3: Secondary stat cards and nested panels (16.0px).
  static const double card = 16.0;

  /// Form inputs and technical controls (12.0px).
  static const double control = 12.0;

  /// Compact status tags (8.0px).
  static const double tag = 8.0;

  /// Level 4: Stadium buttons, status capsules, and floating islands (999.0px Pill).
  static const double pill = 999.0;
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

  /// Borderless Warm Ivory Light Theme (Default)
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
          borderRadius: BorderRadius.circular(StradioRadii.squircle),
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: BorderSide.none,
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
              borderRadius: BorderRadius.circular(StradioRadii.pill),
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
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.pill),
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
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StradioColors.sonicCoral;
          }
          return const Color(0xFFD6D4CC); // High-contrast visible track when OFF
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

  /// Borderless Deep Obsidian Dark Theme (Night Run Mode - Point 7.3)
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: StradioColors.sonicCoral,
      onPrimary: Colors.white,
      secondary: StradioColors.rhythmVioletDark,
      onSecondary: StradioColors.obsidianCanvas,
      surface: StradioColors.charcoalSurface,
      onSurface: StradioColors.ivoryText,
      error: StradioColors.statusError,
      onError: Colors.white,
      outline: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: StradioColors.obsidianCanvas,
      canvasColor: StradioColors.obsidianCanvas,
      dividerColor: Colors.transparent,
      focusColor: StradioColors.sonicCoral.withValues(alpha: 0.22),
      hoverColor: StradioColors.rhythmVioletDark.withValues(alpha: 0.12),
      splashColor: StradioColors.sonicCoral.withValues(alpha: 0.16),
      appBarTheme: AppBarTheme(
        backgroundColor: StradioColors.obsidianCanvas,
        foregroundColor: StradioColors.ivoryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: StradioTypography.soraHeading(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: StradioColors.ivoryText,
          letterSpacing: 1.8,
        ),
        iconTheme: const IconThemeData(
          color: StradioColors.ivoryText,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: StradioColors.charcoalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.squircle),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StradioColors.charcoalSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: StradioTypography.interLabel(
          fontSize: 13,
          color: StradioColors.silverSecondary,
          letterSpacing: 0.2,
        ),
        hintStyle: StradioTypography.interBody(
          fontSize: 13,
          color: StradioColors.silverMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          borderSide: BorderSide.none,
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
              return StradioColors.charcoalSubtle;
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE86049);
            }
            return StradioColors.sonicCoral;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return StradioColors.silverMuted;
            }
            return Colors.white;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.pill),
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
              return StradioColors.silverMuted;
            }
            return StradioColors.ivoryText;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return StradioColors.charcoalSubtle;
            }
            return StradioColors.charcoalSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StradioRadii.pill),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            StradioTypography.interLabel(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StradioColors.ivoryText,
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
          return StradioColors.silverSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StradioColors.sonicCoral;
          }
          return const Color(0xFF383848); // High-contrast visible track in dark mode when OFF
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: StradioColors.charcoalSurface,
        contentTextStyle: StradioTypography.interBody(
          color: StradioColors.ivoryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          side: BorderSide.none,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
