import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stradio_theme.dart';

/// Official STRADIO "S" Topographical Ribbon Logo Widget.
///
/// Renders `assets/images/stradio-logo.png` with explicit dimensions (R-40)
/// and semantic description (R-39). Includes an optional subtle ambient glow
/// for the launch screen (R-13 dose cap: used only on the focal splash emblem)
/// and a deterministic CustomPainter fallback if asset loading is unavailable.
class StradioLogoWidget extends StatelessWidget {
  const StradioLogoWidget({
    super.key,
    this.size = 132,
    this.showWordmark = true,
    this.showAmbientGlow = false,
    this.wordmarkFontSize = 30,
  });

  static const String assetPath = 'assets/images/stradio-logo.png';

  final double size;
  final bool showWordmark;
  final bool showAmbientGlow;
  final double wordmarkFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Stradio topographical S ribbon logo',
          image: true,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (showAmbientGlow)
                  Container(
                    width: size * 0.86,
                    height: size * 0.86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: StradioColors.sonicCoral.withValues(alpha: 0.20),
                          blurRadius: size * 0.42,
                          spreadRadius: size * 0.04,
                        ),
                        BoxShadow(
                          color: StradioColors.rhythmViolet.withValues(alpha: 0.18),
                          blurRadius: size * 0.48,
                          spreadRadius: size * 0.02,
                        ),
                      ],
                    ),
                  ),
                Image.asset(
                  assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  semanticLabel: 'Stradio topographical S ribbon logo',
                  errorBuilder: (context, error, stackTrace) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: const _StradioRibbonFallbackPainter(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 20),
          Text(
            'STRADIO',
            style: StradioTypography.soraHeading(
              fontSize: wordmarkFontSize,
              fontWeight: FontWeight.w800,
              color: StradioColors.warmIvory,
              letterSpacing: 5.0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Delicate mini topographical ribbon wave badge used in the celebratory header
/// of Screen 3 (`PostRunSummaryScreen`).
class StradioMiniWaveBadge extends StatelessWidget {
  const StradioMiniWaveBadge({
    super.key,
    this.width = 48,
    this.height = 28,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Stradio rhythm wave emblem',
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: StradioColors.surfaceDark,
          borderRadius: BorderRadius.circular(StradioRadii.tag),
          border: Border.all(color: StradioColors.borderDark),
        ),
        child: CustomPaint(
          size: Size(width - 12, height - 8),
          painter: const _MiniWaveBadgePainter(),
        ),
      ),
    );
  }
}

class _StradioRibbonFallbackPainter extends CustomPainter {
  const _StradioRibbonFallbackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    for (var layer = 0; layer < 5; layer++) {
      final t = layer / 4.0;
      final offset = (layer - 2) * (w * 0.025);
      final path = Path()
        ..moveTo(w * 0.68 + offset, h * 0.16)
        ..cubicTo(
          w * 0.30 + offset,
          h * 0.06,
          w * 0.16 + offset,
          h * 0.36,
          w * 0.50 + offset,
          h * 0.49,
        )
        ..cubicTo(
          w * 0.84 + offset,
          h * 0.62,
          w * 0.70 + offset,
          h * 0.92,
          w * 0.30 + offset,
          h * 0.84,
        );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * (0.11 - layer * 0.014)
        ..shader = LinearGradient(
          colors: [
            Color.lerp(StradioColors.sonicCoral, StradioColors.rhythmViolet, t)!,
            Color.lerp(
              StradioColors.rhythmViolet,
              StradioColors.sonicCoral,
              t * 0.7,
            )!,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(rect);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StradioRibbonFallbackPainter oldDelegate) =>
      false;
}

class _MiniWaveBadgePainter extends CustomPainter {
  const _MiniWaveBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (var layer = 0; layer < 2; layer++) {
      final path = Path();
      final phase = layer * 0.9;
      final amplitude = size.height * (layer == 0 ? 0.36 : 0.24);
      final midY = size.height / 2;
      for (var x = 0.0; x <= size.width; x += 1.5) {
        final norm = x / size.width;
        final y = midY + math.sin(norm * math.pi * 2.2 + phase) * amplitude;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = layer == 0 ? 2.4 : 1.6
        ..shader = const LinearGradient(
          colors: [StradioColors.sonicCoral, StradioColors.rhythmViolet],
        ).createShader(rect);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveBadgePainter oldDelegate) => false;
}

