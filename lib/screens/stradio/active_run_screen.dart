import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../algorithms/step_detector.dart';
import '../../evaluation/run_metrics_calculator.dart';
import '../../models/experiment_models.dart';
import '../../services/export_service.dart';
import '../../services/posthog_service.dart';
import '../../services/recording_repository.dart';
import '../../services/recording_service.dart';
import '../../theme/stradio_theme.dart';
import 'post_run_summary_screen.dart';
import 'sensor_labs_sheet.dart';

enum _RunStreamState { connecting, running, paused, sensorError }

/// Screen 2: STRADIO Active Run & Reactive Music Screen (With Labs Access).
///
/// Features:
/// - Top App Bar with solid green status indicator (per R-19 & R-37 approval),
///   STRADIO wordmark, and Sensor Labs beaker flask icon.
/// - Center Hero Area with multi-layered audio-stride waveform visualizer,
///   primary Sora tabular step counter, and secondary metrics card (SPM, Time, Speed).
/// - Optional Live Developer Mode Overlay (100 Hz X/Y/Z + 4-algorithm live counts).
/// - Bottom Control Deck with Neon Stride BPM selector, circular Pause/Resume CTA,
///   and accessible Finish Run slider/button.
class ActiveRunScreen extends StatefulWidget {
  const ActiveRunScreen({
    super.key,
    this.store,
    this.recordingService,
    this.exportService,
    this.postHogService,
    this.initialLabSettings = const StradioLabSettings(),
  });

  final RecordingStore? store;
  final RecordingService? recordingService;
  final ExportService? exportService;
  final PostHogTelemetryService? postHogService;
  final StradioLabSettings initialLabSettings;

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen> {
  late final RecordingStore _store;
  late final RecordingService _recordingService;
  late final ExportService _exportService;
  late final PostHogTelemetryService _postHogService;
  late StradioLabSettings _labSettings;

  _RunStreamState _streamState = _RunStreamState.connecting;
  String _recordingId = 'REC_LIVE_001';
  String? _sensorErrorText;

  // 4 simultaneous real-time step detectors (A1, A2, B1, B2)
  late Map<AlgorithmVariant, StepDetector> _detectors;
  late Map<AlgorithmVariant, List<DetectionEvent>> _liveDetections;

  final List<SensorSample> _activeSamples = [];
  final ListQueue<double> _recentMagnitudes = ListQueue<double>();
  final ListQueue<double> _recentThresholds = ListQueue<double>();
  final ValueNotifier<SensorHealthReport> _sensorHealthNotifier = ValueNotifier(
    const SensorHealthReport(
      sampleCount: 0,
      requestedRateHz: 100.0,
      effectiveRateHz: 0.0,
      sampleDrops: 0,
      latestTimestampNs: 0,
    ),
  );

  SensorSample? _latestSample;
  DetectorOutput? _latestPrimaryOutput;
  DateTime? _lastStepFlashAt;

  Timer? _elapsedTimer;
  double _activeDurationSeconds = 0.0;
  bool _hasStartedRun = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _recordingService = widget.recordingService ?? RecordingService();
    _exportService = widget.exportService ?? ExportService();
    _postHogService = widget.postHogService ?? PostHogTelemetryService();
    _labSettings = widget.initialLabSettings;

    _resetDetectors();
    _initializeRunSession();
  }

  void _resetDetectors() {
    const params = AlgorithmParameters();
    _detectors = {
      for (final variant in AlgorithmVariant.values)
        variant: StepDetector(
          algorithm: variant.thresholdAlgorithm,
          parameters: params,
          useLinearAcceleration: variant.usesLinearAcceleration,
        ),
    };
    _liveDetections = {
      for (final variant in AlgorithmVariant.values)
        variant: <DetectionEvent>[],
    };
    _activeSamples.clear();
    _recentMagnitudes.clear();
    _recentThresholds.clear();
    _sensorHealthNotifier.value = const SensorHealthReport(
      sampleCount: 0,
      requestedRateHz: 100.0,
      effectiveRateHz: 0.0,
      sampleDrops: 0,
      latestTimestampNs: 0,
    );
    _latestSample = null;
    _latestPrimaryOutput = null;
    _activeDurationSeconds = 0.0;
    _hasStartedRun = false;
  }

  AlgorithmVariant get _primaryVariant =>
      _labSettings.primaryAlgorithm == ThresholdAlgorithm.adaptiveMidpoint
      ? AlgorithmVariant.a1MidpointRaw
      : AlgorithmVariant.b1MeanSdRaw;

  List<DetectionEvent> get _primaryDetections =>
      _liveDetections[_primaryVariant] ?? const [];

  Future<void> _initializeRunSession() async {
    if (!mounted) return;
    setState(() {
      _streamState = _RunStreamState.connecting;
      _sensorErrorText = null;
    });

    try {
      _recordingId = await _store.nextId(DateTime.now());
    } on Object {
      final now = DateTime.now();
      final day =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      _recordingId = 'REC_${day}_001';
    }

    final available = await _recordingService.isAccelerometerAvailable(
      timeout: const Duration(milliseconds: 1200),
    );
    if (!mounted) return;

    if (!available) {
      setState(() {
        _streamState = _RunStreamState.sensorError;
        _sensorErrorText =
            'Accelerometer stream did not respond within 1.2s. Check device sensor permissions or use Simulate Stride (+1) to test on an emulator.';
      });
      return;
    }

    _startSensorStream();
  }

  void _startSensorStream() {
    if (_recordingService.isRecording) {
      unawaited(_recordingService.stop());
    }

    try {
      _recordingService.start(
        _recordingId,
        samplingRateHz: 100.0,
        onSample: _handleIncomingSample,
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _streamState = _RunStreamState.sensorError;
            _sensorErrorText = 'Sensor stream error: $error';
          });
        },
      );

      setState(() {
        _streamState = _RunStreamState.paused;
        _sensorErrorText = null;
      });
    } on Object catch (error) {
      setState(() {
        _streamState = _RunStreamState.sensorError;
        _sensorErrorText = 'Could not start accelerometer stream: $error';
      });
    }
  }

  void _startElapsedTicker() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _streamState != _RunStreamState.running) return;
      setState(() {
        _activeDurationSeconds += 1.0;
      });
    });
  }

  void _handleIncomingSample(SensorSample sample) {
    if (!mounted || _streamState != _RunStreamState.running) return;

    _activeSamples.add(sample);
    _latestSample = sample;

    DetectorOutput? primaryOut;
    for (final variant in AlgorithmVariant.values) {
      final out = _detectors[variant]!.addSample(sample);
      if (out.step != null) {
        _liveDetections[variant]!.add(out.step!);
      }
      if (variant == _primaryVariant) {
        primaryOut = out;
      }
    }

    if (primaryOut != null) {
      _latestPrimaryOutput = primaryOut;
      _recentMagnitudes.addLast(primaryOut.smoothedMps2);
      _recentThresholds.addLast(primaryOut.thresholdMps2);
      while (_recentMagnitudes.length > 72) {
        _recentMagnitudes.removeFirst();
      }
      while (_recentThresholds.length > 72) {
        _recentThresholds.removeFirst();
      }
      if (primaryOut.step != null) {
        _lastStepFlashAt = DateTime.now();
      }
    }

    // Update UI and live health notifier at a smooth cadence (every 4th sample at 100Hz = 25fps, or immediately on step)
    if (primaryOut?.step != null || sample.sampleIndex % 4 == 0) {
      _sensorHealthNotifier.value = RunMetricsCalculator.analyzeSensorHealth(
        samples: _activeSamples,
        requestedRateHz: 100.0,
      );
      setState(() {});
    }
  }

  /// Injects a realistic synthetic foot-strike gait cycle (stance baseline ->
  /// foot-strike peak -> post-impact valley) so researchers and automated tests
  /// can verify step detection across all 4 variants (A1, A2, B1, B2) on
  /// devices or emulators without physical movement.
  void _simulateSingleStride() {
    final baseTs = _activeSamples.isEmpty
        ? DateTime.now().microsecondsSinceEpoch * 1000
        : _activeSamples.last.timestampNs + 350000000;

    // 12-sample gait cycle (6 baseline stance + 3 foot-strike peak + 3 recovery valley)
    // Ensures mean + 1.5*SD (B1/B2) as well as Midpoint (A1/A2) cleanly confirm
    // exactly 1 peak and re-arm on the trailing valley.
    const rawAzWave = [
      9.5,
      9.5,
      9.5,
      9.5,
      9.5,
      9.5,
      14.2,
      16.8,
      13.8,
      9.1,
      9.1,
      9.1,
    ];
    const linearUzWave = [
      0.1,
      0.1,
      0.1,
      0.1,
      0.1,
      0.1,
      3.5,
      6.8,
      3.2,
      0.1,
      0.1,
      0.1,
    ];

    final previousState = _streamState;
    _streamState = _RunStreamState.running;

    for (var i = 0; i < rawAzWave.length; i++) {
      final sample = SensorSample(
        recordingId: _recordingId,
        sampleIndex: _activeSamples.length,
        timestampNs: baseTs + i * 25000000, // 25ms spacing (300ms stride cycle)
        axMps2: 0.3,
        ayMps2: 1.2,
        azMps2: rawAzWave[i],
        uxMps2: 0.1,
        uyMps2: 0.3,
        uzMps2: linearUzWave[i],
      );
      _handleIncomingSample(sample);
    }

    if (_activeDurationSeconds < 1.0) {
      _activeDurationSeconds = 1.0;
    } else {
      _activeDurationSeconds += 0.5;
    }

    if (previousState == _RunStreamState.paused ||
        previousState == _RunStreamState.sensorError) {
      _streamState = previousState;
    }
    _sensorHealthNotifier.value = RunMetricsCalculator.analyzeSensorHealth(
      samples: _activeSamples,
      requestedRateHz: 100.0,
    );
    setState(() {});
  }

  void _togglePauseResume() {
    if (_streamState == _RunStreamState.running) {
      setState(() {
        _streamState = _RunStreamState.paused;
      });
      unawaited(
        _postHogService.captureRunPaused(
          recordingId: _recordingId,
          participantId: _labSettings.participantId,
          elapsedSeconds: _activeDurationSeconds,
          currentSteps: _primaryDetections.length,
        ),
      );
    } else {
      final isFirstStart = !_hasStartedRun;
      _hasStartedRun = true;
      setState(() {
        _streamState = _RunStreamState.running;
      });
      _startElapsedTicker();
      if (isFirstStart) {
        unawaited(
          _postHogService.captureRunStarted(
            recordingId: _recordingId,
            config: _labSettings.toExperimentConfig(),
            targetBpm: _labSettings.targetBpm,
          ),
        );
      } else {
        unawaited(
          _postHogService.captureRunResumed(
            recordingId: _recordingId,
            participantId: _labSettings.participantId,
            elapsedSeconds: _activeDurationSeconds,
            currentSteps: _primaryDetections.length,
          ),
        );
      }
    }
  }

  Future<void> _finishRun() async {
    _elapsedTimer?.cancel();
    unawaited(_recordingService.stop());

    // Show a smooth non-blocking transition loading overlay while processing large sample batches
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: StradioColors.surfaceDark,
              borderRadius: BorderRadius.circular(StradioRadii.card),
              border: Border.all(color: StradioColors.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: StradioColors.sonicCoral,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Processing Workout Data...',
                  style: StradioTypography.interBody(
                    fontSize: 14,
                    color: StradioColors.warmIvory,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Yield control to UI thread so dialog renders before intensive calculations
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final immutableSamples = List<SensorSample>.unmodifiable(_activeSamples);
    final config = _labSettings.toExperimentConfig();
    final replayBoth = StepDetector.replayBoth(
      immutableSamples,
      config.parameters,
    );
    final replayAllFour = StepDetector.replayAllFour(
      immutableSamples,
      config.parameters,
    );

    final recording = SavedRecording(
      recordingId: _recordingId,
      createdAt: DateTime.now(),
      config: config,
      samples: immutableSamples,
      liveStepCount: _primaryDetections.length,
      replayDetections: replayBoth,
      replayVariantDetections: replayAllFour,
    );

    final metrics = RunMetricsCalculator.computeSummary(
      detections: _primaryDetections,
      samples: immutableSamples,
      activity: config.activity,
      activeDurationSeconds: math.max(
        _activeDurationSeconds,
        recording.durationSeconds,
      ),
      targetBpm: _labSettings.targetBpm,
    );

    final health = RunMetricsCalculator.analyzeSensorHealth(
      samples: immutableSamples,
      requestedRateHz: config.requestedSamplingRateHz,
    );

    if (!mounted) return;
    // Dismiss loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    final savedAndFinished = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostRunSummaryScreen(
          recording: recording,
          metrics: metrics,
          sensorHealth: health,
          store: _store,
          postHogService: _postHogService,
        ),
      ),
    );

    if (!mounted) return;
    if (savedAndFinished == true) {
      setState(() {
        _labSettings = _labSettings.copyWith(
          trialNumber: _labSettings.trialNumber + 1,
        );
        _resetDetectors();
      });
      await _initializeRunSession();
    } else {
      // Resume session if user navigated back without resetting
      setState(() {
        _streamState = _RunStreamState.paused;
      });
    }
  }

  Future<void> _openSensorLabsDrawer() async {
    final health = RunMetricsCalculator.analyzeSensorHealth(
      samples: _activeSamples,
      requestedRateHz: 100.0,
    );
    _sensorHealthNotifier.value = health;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SensorLabsSheet(
        initialSettings: _labSettings,
        sensorHealth: health,
        sensorHealthListenable: _sensorHealthNotifier,
        sensorStreamActive: _streamState == _RunStreamState.running,
        store: _store,
        recordingService: _recordingService,
        exportService: _exportService,
        postHogService: _postHogService,
        onBeforeOpenLegacyExperiment: () {
          if (!mounted) return;
          if (_streamState == _RunStreamState.running) {
            setState(() {
              _streamState = _RunStreamState.paused;
            });
          }
        },
        onSettingsChanged: (updated) {
          if (!mounted) return;
          setState(() {
            _labSettings = updated;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _sensorHealthNotifier.dispose();
    unawaited(_recordingService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primarySteps = _primaryDetections.length;
    final formattedSteps = formatStepCount(primarySteps);

    final metrics = RunMetricsCalculator.computeSummary(
      detections: _primaryDetections,
      samples: _activeSamples,
      activity: _labSettings.activity,
      activeDurationSeconds: _activeDurationSeconds,
      targetBpm: _labSettings.targetBpm,
    );

    final stepFlashActive =
        _lastStepFlashAt != null &&
        DateTime.now().difference(_lastStepFlashAt!) <
            const Duration(milliseconds: 240);

    return Scaffold(
      backgroundColor: StradioColors.midnight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPad = isWide ? 40.0 : (isTablet ? 28.0 : 20.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        12,
                        horizontalPad,
                        8,
                      ),
                      child: _ActiveRunTopBar(
                        streamState: _streamState,
                        onOpenLabs: _openSensorLabsDrawer,
                      ),
                    ),

                    // Scrollable Main Hero + Readouts + Developer Overlay
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // State Banners (Loading / Error / Empty guidance per R-27)
                            if (_streamState == _RunStreamState.connecting)
                              _StatusStateBanner(
                                icon: Icons.sensors,
                                accentColor: StradioColors.rhythmViolet,
                                message:
                                    'Connecting to 100 Hz accelerometer stream...',
                              )
                            else if (_streamState ==
                                    _RunStreamState.sensorError &&
                                _sensorErrorText != null)
                              _StatusStateBanner(
                                icon: Icons.warning_amber_rounded,
                                accentColor: StradioColors.statusError,
                                message: _sensorErrorText!,
                                actionLabel: 'Simulate Stride (+1)',
                                onAction: _simulateSingleStride,
                              ),

                            // Developer Mode Live Overlay (when toggled ON in Sensor Labs)
                            if (_labSettings.developerOverlayEnabled) ...[
                              _DeveloperTelemetryOverlay(
                                latestSample: _latestSample,
                                latestOutput: _latestPrimaryOutput,
                                liveCounts: {
                                  for (final v in AlgorithmVariant.values)
                                    v: _liveDetections[v]?.length ?? 0,
                                },
                                targetSteps: _labSettings.targetSteps,
                                onSimulateStride: _simulateSingleStride,
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Center Hero Area: Multi-layered Audio-Stride Waveform Visualizer
                            _AudioStrideVisualizerCard(
                              magnitudes: _recentMagnitudes.toList(),
                              thresholds: _recentThresholds.toList(),
                              isRunning:
                                  _streamState == _RunStreamState.running,
                              isStationary:
                                  _latestPrimaryOutput?.isStationary ?? true,
                              stepFlashActive: stepFlashActive,
                              targetBpm: _labSettings.targetBpm,
                              height: isTablet ? 200 : 168,
                            ),
                            const SizedBox(height: 20),

                            // Prominent Digital Readouts: Huge Primary Step Metric
                            Column(
                              children: [
                                Text(
                                  formattedSteps,
                                  key: const Key('active_run_step_count'),
                                  style: StradioTypography.soraMetric(
                                    fontSize: isTablet ? 76 : 64,
                                    fontWeight: FontWeight.w800,
                                    color: stepFlashActive
                                        ? StradioColors.sonicCoral
                                        : StradioColors.warmIvory,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'STEPS',
                                  style: StradioTypography.soraHeading(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: StradioColors.warmIvory,
                                    letterSpacing: 3.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  primarySteps == 0
                                      ? 'Walk or jog to begin live step detection (Benchmark target: ${_labSettings.targetSteps} steps)'
                                      : 'Detected: $primarySteps / Target: ${_labSettings.targetSteps} (${_labSettings.activity.value.toUpperCase()} · ${_labSettings.phonePlacement.value.toUpperCase()})',
                                  textAlign: TextAlign.center,
                                  style: StradioTypography.interBody(
                                    fontSize: 12,
                                    color: StradioColors.mutedIvory,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Secondary Runner Metrics Card: SPM, Time Elapsed, Speed km/h
                            _SecondaryMetricsBar(
                              cadenceText:
                                  '${metrics.liveCadenceSpm.round()} SPM',
                              elapsedText: metrics.formattedDuration,
                              speedText:
                                  '${metrics.speedKmh.toStringAsFixed(1)} km/h',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Control Deck
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        8,
                        horizontalPad,
                        14,
                      ),
                      child: _BottomControlDeck(
                        isRunning: _streamState == _RunStreamState.running,
                        targetBpm: _labSettings.targetBpm,
                        onSelectBpm: (bpm) {
                          setState(() {
                            _labSettings = _labSettings.copyWith(
                              targetBpm: bpm,
                            );
                          });
                        },
                        onTogglePauseResume: _togglePauseResume,
                        onFinishRun: _finishRun,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveRunTopBar extends StatelessWidget {
  const _ActiveRunTopBar({
    required this.streamState,
    required this.onOpenLabs,
  });

  final _RunStreamState streamState;
  final VoidCallback onOpenLabs;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, dotColor) = switch (streamState) {
      _RunStreamState.running => ('RUNNING', StradioColors.statusLive),
      _RunStreamState.paused => ('PAUSED', StradioColors.statusPaused),
      _RunStreamState.connecting => ('CONNECTING', StradioColors.rhythmViolet),
      _RunStreamState.sensorError => ('STANDBY', StradioColors.statusPaused),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Activity status with SOLID status dot (no endless pulse per R-19/R-37)
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: StradioColors.surfaceDark,
              borderRadius: BorderRadius.circular(StradioRadii.control),
              border: Border.all(color: StradioColors.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  key: const Key('status_indicator_dot'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusLabel,
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: StradioColors.warmIvory,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Accessible Labs / Experiment beaker flask icon
        Semantics(
          button: true,
          label: 'Open Sensor Labs and Diagnostics',
          child: IconButton(
            key: const Key('open_sensor_labs_button'),
            onPressed: onOpenLabs,
            tooltip: 'Sensor Labs & Diagnostics',
            style: IconButton.styleFrom(
              backgroundColor: StradioColors.surfaceDark,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StradioRadii.control),
                side: const BorderSide(color: StradioColors.borderDark),
              ),
            ),
            icon: const Icon(
              Icons.science_outlined,
              color: StradioColors.rhythmViolet,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusStateBanner extends StatelessWidget {
  const _StatusStateBanner({
    required this.icon,
    required this.accentColor,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color accentColor;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: StradioColors.surfaceDark,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        border: Border.all(color: accentColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: StradioTypography.interBody(
                fontSize: 12,
                color: StradioColors.warmIvory,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              key: const Key('simulate_stride_banner_button'),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioStrideVisualizerCard extends StatelessWidget {
  const _AudioStrideVisualizerCard({
    required this.magnitudes,
    required this.thresholds,
    required this.isRunning,
    required this.isStationary,
    required this.stepFlashActive,
    required this.targetBpm,
    required this.height,
  });

  final List<double> magnitudes;
  final List<double> thresholds;
  final bool isRunning;
  final bool isStationary;
  final bool stepFlashActive;
  final int targetBpm;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label:
          'Audio-stride reactive waveform visualizer, ${isRunning ? "active" : "paused"}',
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StradioColors.surfaceDark,
          borderRadius: BorderRadius.circular(StradioRadii.hero),
          border: Border.all(
            color: stepFlashActive
                ? StradioColors.sonicCoral
                : StradioColors.borderDark,
            width: stepFlashActive ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: StradioColors.sonicCoral.withValues(
                alpha: stepFlashActive ? 0.24 : 0.10,
              ),
              blurRadius: stepFlashActive ? 24 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'AUDIO-STRIDE WAVEFORM',
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      color: StradioColors.mutedIvory,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isRunning ? '$targetBpm BPM TARGET' : 'WAVEFORM PAUSED',
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      color: isRunning
                          ? StradioColors.rhythmViolet
                          : StradioColors.statusPaused,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: CustomPaint(
                painter: _TopographicalWaveformPainter(
                  magnitudes: magnitudes,
                  thresholds: thresholds,
                  isRunning: isRunning,
                  isStationary: isStationary,
                  stepFlashActive: stepFlashActive && !reduceMotion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopographicalWaveformPainter extends CustomPainter {
  const _TopographicalWaveformPainter({
    required this.magnitudes,
    required this.thresholds,
    required this.isRunning,
    required this.isStationary,
    required this.stepFlashActive,
  });

  final List<double> magnitudes;
  final List<double> thresholds;
  final bool isRunning;
  final bool isStationary;
  final bool stepFlashActive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final midY = size.height / 2;

    // Baseline horizon
    final horizonPaint = Paint()
      ..color = StradioColors.borderDark.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), horizonPaint);

    var minV = magnitudes.isNotEmpty ? magnitudes.first : 0.0;
    var maxV = magnitudes.isNotEmpty ? magnitudes.first : 0.0;
    for (final v in magnitudes) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final rawSpan = maxV - minV;
    // When resting on a table (or stationary or paused), signal spread is minimal (< 0.4 m/s²).
    // In that case, render completely still/horizontal straight lines across the horizon.
    final isActuallyStill =
        !isRunning || isStationary || magnitudes.length < 2 || rawSpan < 0.40;

    // Draw 3 layered topographical ribbon waves driven by real sensor samples
    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      final scaleFactor = switch (layer) {
        0 => 1.0,
        1 => 0.68,
        _ => 0.42,
      };

      if (isActuallyStill) {
        path.moveTo(0, midY);
        path.lineTo(size.width, midY);
      } else {
        final span = math.max(6.0, rawSpan);
        final centerVal = (maxV + minV) / 2;

        for (var i = 0; i < magnitudes.length; i++) {
          final x = (i / (magnitudes.length - 1)) * size.width;
          final normalized = ((magnitudes[i] - centerVal) / span).clamp(
            -0.95,
            0.95,
          );
          final boost = stepFlashActive ? 1.15 : 1.0;
          final y =
              midY -
              (normalized * (size.height * 0.40) * scaleFactor * boost);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = layer == 0 ? 3.0 : (layer == 1 ? 2.0 : 1.4)
        ..shader = LinearGradient(
          colors: layer.isEven
              ? [StradioColors.sonicCoral, StradioColors.rhythmViolet]
              : [StradioColors.rhythmViolet, StradioColors.sonicCoral],
        ).createShader(rect);

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopographicalWaveformPainter oldDelegate) =>
      oldDelegate.magnitudes != magnitudes ||
      oldDelegate.thresholds != thresholds ||
      oldDelegate.isRunning != isRunning ||
      oldDelegate.isStationary != isStationary ||
      oldDelegate.stepFlashActive != stepFlashActive;
}

class _SecondaryMetricsBar extends StatelessWidget {
  const _SecondaryMetricsBar({
    required this.cadenceText,
    required this.elapsedText,
    required this.speedText,
  });

  final String cadenceText;
  final String elapsedText;
  final String speedText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: StradioColors.surfaceDark,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        border: Border.all(color: StradioColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SecondaryMetricItem(
              valueKey: const Key('metric_cadence_value'),
              label: 'CADENCE',
              value: cadenceText,
            ),
          ),
          Container(width: 1, height: 34, color: StradioColors.borderDark),
          Expanded(
            child: _SecondaryMetricItem(
              valueKey: const Key('metric_elapsed_value'),
              label: 'TIME ELAPSED',
              value: elapsedText,
            ),
          ),
          Container(width: 1, height: 34, color: StradioColors.borderDark),
          Expanded(
            child: _SecondaryMetricItem(
              valueKey: const Key('metric_speed_value'),
              label: 'SPEED',
              value: speedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetricItem extends StatelessWidget {
  const _SecondaryMetricItem({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final Key valueKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          key: valueKey,
          textAlign: TextAlign.center,
          style: StradioTypography.soraMetric(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: StradioTypography.interLabel(
            fontSize: 10,
            color: StradioColors.mutedIvory,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _DeveloperTelemetryOverlay extends StatelessWidget {
  const _DeveloperTelemetryOverlay({
    required this.latestSample,
    required this.latestOutput,
    required this.liveCounts,
    required this.targetSteps,
    required this.onSimulateStride,
  });

  final SensorSample? latestSample;
  final DetectorOutput? latestOutput;
  final Map<AlgorithmVariant, int> liveCounts;
  final int targetSteps;
  final VoidCallback onSimulateStride;

  @override
  Widget build(BuildContext context) {
    final s = latestSample;
    final out = latestOutput;

    return Container(
      key: const Key('developer_telemetry_overlay'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StradioColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        border: Border.all(color: StradioColors.rhythmViolet, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.terminal_rounded,
                size: 16,
                color: StradioColors.rhythmViolet,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LIVE 100HZ TELEMETRY & 4-ALGORITHM MATRIX',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: StradioColors.rhythmViolet,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('overlay_simulate_stride_button'),
                onPressed: onSimulateStride,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(44, 36),
                ),
                icon: const Icon(
                  Icons.directions_run,
                  size: 15,
                  color: StradioColors.sonicCoral,
                ),
                label: Text(
                  '+1 Stride',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: StradioColors.sonicCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s == null
                ? 'Raw (+G): ax 0.00  ay 0.00  az 9.81 m/s²  |  m(t) 9.81  T(t) ${out?.thresholdMps2.toStringAsFixed(2) ?? "9.81"}'
                : 'Raw (+G): ax ${s.axMps2.toStringAsFixed(2)}  ay ${s.ayMps2.toStringAsFixed(2)}  az ${s.azMps2.toStringAsFixed(2)}  |  m(t) ${out?.smoothedMps2.toStringAsFixed(2) ?? s.magnitudeMps2.toStringAsFixed(2)}  T(t) ${out?.thresholdMps2.toStringAsFixed(2) ?? "--"}',
            style: StradioTypography.interLabel(
              fontSize: 11,
              color: StradioColors.warmIvory,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s == null
                ? 'Linear (-G): ux 0.00  uy 0.00  uz 0.00 m/s²  |  Target Benchmark: $targetSteps steps'
                : 'Linear (-G): ux ${s.uxMps2.toStringAsFixed(2)}  uy ${s.uyMps2.toStringAsFixed(2)}  uz ${s.uzMps2.toStringAsFixed(2)}  |  Target: $targetSteps',
            style: StradioTypography.interLabel(
              fontSize: 11,
              color: StradioColors.mutedIvory,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variant in AlgorithmVariant.values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: StradioColors.surfaceDark,
                    borderRadius: BorderRadius.circular(StradioRadii.tag),
                    border: Border.all(color: StradioColors.borderDark),
                  ),
                  child: Text(
                    '${variant.code}: ${liveCounts[variant] ?? 0} steps',
                    key: Key('live_variant_count_${variant.code}'),
                    style: StradioTypography.interLabel(
                      fontSize: 12,
                      color: StradioColors.warmIvory,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomControlDeck extends StatelessWidget {
  const _BottomControlDeck({
    required this.isRunning,
    required this.targetBpm,
    required this.onSelectBpm,
    required this.onTogglePauseResume,
    required this.onFinishRun,
  });

  final bool isRunning;
  final int targetBpm;
  final ValueChanged<int> onSelectBpm;
  final VoidCallback onTogglePauseResume;
  final VoidCallback onFinishRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StradioColors.surfaceDark,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        border: Border.all(color: StradioColors.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Soundscape Row ("Neon Stride : <BPM> BPM" + Tempo selector)
          Row(
            children: [
              const Icon(
                Icons.graphic_eq,
                color: StradioColors.rhythmViolet,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neon Stride : $targetBpm BPM',
                      key: const Key('soundscape_title_text'),
                      style: StradioTypography.soraHeading(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                key: const Key('tempo_bpm_selector_button'),
                tooltip: 'Select Target Tempo BPM',
                onSelected: onSelectBpm,
                color: StradioColors.surfaceDark,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 118,
                    child: Text('118 BPM (Brisk Walk)'),
                  ),
                  PopupMenuItem(
                    value: 145,
                    child: Text('145 BPM (Tempo Jog)'),
                  ),
                  PopupMenuItem(
                    value: 165,
                    child: Text('165 BPM (Neon Stride)'),
                  ),
                ],
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StradioColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.control),
                    border: Border.all(color: StradioColors.borderDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$targetBpm BPM',
                        style: StradioTypography.interLabel(
                          fontSize: 12,
                          color: StradioColors.rhythmViolet,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: StradioColors.rhythmViolet,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Controls Row: Glowing Circular Pause/Resume Button + Sleek Finish Run Button
          Row(
            children: [
              // Glowing circular Pause / Resume button in vibrant Sonic Coral
              Semantics(
                button: true,
                label: isRunning ? 'Pause Run' : 'Resume Run',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: StradioColors.sonicCoral,
                    boxShadow: [
                      BoxShadow(
                        color: StradioColors.sonicCoral.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    key: const Key('pause_resume_run_button'),
                    onPressed: onTogglePauseResume,
                    tooltip: isRunning ? 'Pause Run' : 'Resume Run',
                    icon: Icon(
                      isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: StradioColors.midnight,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Sleek "Finish Run" Accessible Button (Clean, without inner stop box)
              Expanded(
                child: _FinishRunButton(
                  onFinishRun: onFinishRun,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinishRunButton extends StatelessWidget {
  const _FinishRunButton({
    required this.onFinishRun,
  });

  final VoidCallback onFinishRun;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Finish Run',
      child: Material(
        color: StradioColors.surfaceSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.control),
          side: const BorderSide(color: StradioColors.borderDark),
        ),
        child: InkWell(
          key: const Key('finish_run_button'),
          onTap: onFinishRun,
          borderRadius: BorderRadius.circular(StradioRadii.control),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'Finish Run',
                style: StradioTypography.soraHeading(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: StradioColors.warmIvory,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
