import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/export_service.dart';
import '../../services/posthog_service.dart';
import '../../services/recording_repository.dart';
import '../../services/recording_service.dart';
import '../../theme/stradio_theme.dart';
import '../../widgets/stradio_logo_widget.dart';
import 'active_run_screen.dart';
import 'sensor_labs_sheet.dart';

/// Screen 1: STRADIO Minimalist Splash Screen.
///
/// Pure minimalist dark theme with deep midnight background (#191923).
/// In the exact center of the screen, displays the fluid 3D ribbon "S" monogram
/// logo (`assets/images/stradio-logo.png`) with a subtle ambient glow and the
/// bold wordmark "STRADIO" in Warm Ivory (#F5F0E8) using Sora font style.
/// No buttons, no clutter, no progress bars.
class StradioSplashScreen extends StatefulWidget {
  const StradioSplashScreen({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1400),
    this.store,
    this.recordingService,
    this.exportService,
    this.postHogService,
    this.initialLabSettings = const StradioLabSettings(),
  });

  final Duration splashDuration;
  final RecordingStore? store;
  final RecordingService? recordingService;
  final ExportService? exportService;
  final PostHogTelemetryService? postHogService;
  final StradioLabSettings initialLabSettings;

  @override
  State<StradioSplashScreen> createState() => _StradioSplashScreenState();
}

class _StradioSplashScreenState extends State<StradioSplashScreen> {
  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(widget.splashDuration, _proceedToActiveRun);
  }

  void _proceedToActiveRun() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigationTimer?.cancel();

    final postHog = widget.postHogService ?? PostHogTelemetryService();
    unawaited(
      postHog.captureAppOpened(
        distinctId: widget.initialLabSettings.participantId,
        developerOverlayEnabled:
            widget.initialLabSettings.developerOverlayEnabled,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ActiveRunScreen(
              store: widget.store,
              recordingService: widget.recordingService,
              exportService: widget.exportService,
              postHogService: postHog,
              initialLabSettings: widget.initialLabSettings,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return child;
          }
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StradioColors.midnight,
      body: Semantics(
        label: 'Stradio launch splash screen. Tap to enter active run.',
        button: true,
        child: GestureDetector(
          key: const Key('splash_screen_tap_area'),
          behavior: HitTestBehavior.opaque,
          onTap: _proceedToActiveRun,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                return StradioLogoWidget(
                  size: isTablet ? 168 : 138,
                  showWordmark: false,
                  showAmbientGlow: false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

