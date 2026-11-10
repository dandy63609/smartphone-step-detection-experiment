import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../algorithms/step_detector.dart';
import '../../evaluation/run_metrics_calculator.dart';
import '../../models/experiment_models.dart';
import '../../services/export_service.dart';
import '../../services/foreground_notification_service.dart';
import '../../services/posthog_service.dart';
import '../../services/preferences_service.dart';
import '../../services/recording_repository.dart';
import '../../services/recording_service.dart';
import '../../theme/stradio_theme.dart';
import 'post_run_summary_screen.dart';
import 'sensor_labs_sheet.dart';

enum _RunStreamState { connecting, running, paused, sensorError }
enum _RecoveryAction { reviewAndSave, discard }

/// Screen 2: STRADIO Active Run & Reactive Music Screen (Point 7 Revamp).
///
/// Implements the "Unified Stride Deck" architecture:
/// - Zero-Scroll single-viewport layout on mobile, tablet, and desktop.
/// - 100% Borderless cards using Deep Organic Squircle radii (28px Hero,
///   20px Squircle Deck, 999px Stadium Pills) and diffused 2-stage shadows.
/// - Editorial Header ("Find Your Stride") with runner profile, live status,
///   Light/Dark theme toggle, and Sensor Labs access.
/// - Vertical Rhythm Equalizer Bars visualizer (Reference 2) reactive to
///   real-time 100 Hz foot-strike accelerometer magnitudes.
/// - Unified Stride Goal & 3-Column Metrics Deck (Steps, Cadence SPM, Time).
/// - Thumb-Zone Bottom Control Deck with circular Pause/Resume and Stadium Finish CTA.
class ActiveRunScreen extends StatefulWidget {
  const ActiveRunScreen({
    super.key,
    this.store,
    this.recordingService,
    this.exportService,
    this.postHogService,
    this.foregroundService,
    this.initialLabSettings = const StradioLabSettings(),
    this.onToggleThemeMode,
    this.isConsumerMode = false,
    this.developerModeEnabled = true,
    this.userHeightCm,
  });

  final RecordingStore? store;
  final RecordingService? recordingService;
  final ExportService? exportService;
  final PostHogTelemetryService? postHogService;
  final ForegroundNotificationService? foregroundService;
  final StradioLabSettings initialLabSettings;
  final VoidCallback? onToggleThemeMode;
  final bool isConsumerMode;
  final bool developerModeEnabled;
  final double? userHeightCm;

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen>
    with SingleTickerProviderStateMixin {
  late final RecordingStore _store;
  late final RecordingService _recordingService;
  late final ExportService _exportService;
  late final PostHogTelemetryService _postHogService;
  late final ForegroundNotificationService _foregroundService;
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
  late List<double> _smoothedBarHeights;
  late List<double> _targetBarHeights;
  final ValueNotifier<int> _waveformRepaintNotifier = ValueNotifier<int>(0);
  late final Ticker _waveformTicker;
  Timer? _stepFlashTimer;
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
    _foregroundService =
        widget.foregroundService ?? FlutterForegroundNotificationService();
    _labSettings = widget.initialLabSettings;

    _waveformTicker = createTicker(_onWaveformTick);
    _foregroundService.addActionListener(_handleNotificationAction);

    _resetDetectors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnfinishedSessionAndInitialize();
    });
  }

  void _syncWaveformTicker() {
    if (!mounted) return;
    if (_streamState == _RunStreamState.running) {
      if (!_waveformTicker.isActive) {
        _waveformTicker.start();
      }
    } else {
      if (_waveformTicker.isActive) {
        _waveformTicker.stop();
      }
    }
  }

  void _onWaveformTick(Duration elapsed) {
    if (!mounted || _streamState != _RunStreamState.running) {
      if (_waveformTicker.isActive) _waveformTicker.stop();
      return;
    }
    const barCount = 28;
    const attackAlpha = 0.36;
    const decayAlpha = 0.14;
    var changed = false;

    for (var i = 0; i < barCount; i++) {
      final target = _targetBarHeights[i];
      final current = _smoothedBarHeights[i];
      final diff = target - current;
      if (diff.abs() > 0.002) {
        final alpha = diff >= 0 ? attackAlpha : decayAlpha;
        _smoothedBarHeights[i] = current + diff * alpha;
        changed = true;
      } else if (current != target) {
        _smoothedBarHeights[i] = target;
        changed = true;
      }
    }

    if (changed) {
      _waveformRepaintNotifier.value++;
    } else {
      _waveformTicker.stop();
    }
  }

  void _handleNotificationAction(String action) {
    if (!mounted) return;
    if (action == 'pause_resume') {
      _togglePauseResume();
    } else if (action == 'finish') {
      _finishRun();
    }
  }

  Future<void> _checkUnfinishedSessionAndInitialize() async {
    if (!mounted) return;
    try {
      final cached = await _store.loadActiveSessionCache();
      if (cached != null && cached.samples.isNotEmpty && mounted) {
        final action = await _promptCrashRecoveryDialog(cached);
        if (!mounted) return;
        if (action == _RecoveryAction.reviewAndSave) {
          await _recoverAndReviewSession(cached);
          return;
        } else if (action == _RecoveryAction.discard) {
          await _store.clearActiveSessionCache();
        }
      }
    } catch (_) {
      // Ignore cache recovery errors and start fresh session.
    }
    if (!mounted) return;
    await _initializeRunSession();
  }

  void _flushActiveSessionCache() {
    if (_activeSamples.isEmpty) return;
    final snapshot = ActiveSessionSnapshot(
      recordingId: _recordingId,
      createdAt: DateTime.now(),
      config: _labSettings.toExperimentConfig(),
      targetBpm: _labSettings.targetBpm,
      activeDurationSeconds: _activeDurationSeconds,
      samples: List<SensorSample>.from(_activeSamples),
    );
    unawaited(_store.saveActiveSessionCache(snapshot));
  }

  Future<_RecoveryAction?> _promptCrashRecoveryDialog(
    ActiveSessionSnapshot snapshot,
  ) async {
    final palette = StradioPalette.of(context);
    final count = snapshot.samples.length;
    final durSec = snapshot.activeDurationSeconds.round();
    final durFormatted =
        '${(durSec ~/ 60).toString().padLeft(2, '0')}:${(durSec % 60).toString().padLeft(2, '0')}';

    return showDialog<_RecoveryAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StradioRadii.squircle),
          ),
          title: Text(
            'Unfinished Run Detected',
            style: StradioTypography.soraHeading(
              fontSize: 18,
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Stradio found an unsaved run session ($count sensor samples, $durFormatted duration). Would you like to review and save it to your workout history?',
            style: StradioTypography.interBody(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          actionsPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          actions: [
            TextButton(
              key: const Key('discard_recovered_session_button'),
              onPressed: () => Navigator.of(ctx).pop(_RecoveryAction.discard),
              style: TextButton.styleFrom(
                foregroundColor: palette.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              key: const Key('review_recovered_session_button'),
              onPressed: () =>
                  Navigator.of(ctx).pop(_RecoveryAction.reviewAndSave),
              style: ElevatedButton.styleFrom(
                backgroundColor: StradioColors.sonicCoral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Review & Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recoverAndReviewSession(ActiveSessionSnapshot cached) async {
    final immutableSamples = List<SensorSample>.unmodifiable(cached.samples);
    final config = cached.config;
    final replayBoth = StepDetector.replayBoth(
      immutableSamples,
      config.parameters,
    );
    final replayAllFour = StepDetector.replayAllFour(
      immutableSamples,
      config.parameters,
    );

    final primaryVariant =
        config.primaryLiveAlgorithm == ThresholdAlgorithm.adaptiveMidpoint
            ? AlgorithmVariant.a1MidpointRaw
            : AlgorithmVariant.b1MeanSdRaw;
    final primaryDetections = replayAllFour[primaryVariant] ?? const [];

    final recording = SavedRecording(
      recordingId: cached.recordingId,
      createdAt: cached.createdAt,
      config: config,
      samples: immutableSamples,
      liveStepCount: primaryDetections.length,
      replayDetections: replayBoth,
      replayVariantDetections: replayAllFour,
    );

    final metrics = RunMetricsCalculator.computeSummary(
      detections: primaryDetections,
      samples: immutableSamples,
      activity: config.activity,
      activeDurationSeconds: math.max(
        cached.activeDurationSeconds,
        recording.durationSeconds,
      ),
      targetBpm: cached.targetBpm,
    );

    final health = RunMetricsCalculator.analyzeSensorHealth(
      samples: immutableSamples,
      requestedRateHz: config.requestedSamplingRateHz,
    );

    if (!mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostRunSummaryScreen(
          recording: recording,
          metrics: metrics,
          sensorHealth: health,
          store: _store,
          postHogService: _postHogService,
          developerModeEnabled:
              !widget.isConsumerMode || widget.developerModeEnabled,
        ),
      ),
    );

    await _store.clearActiveSessionCache();

    if (!mounted) return;
    _resetDetectors();
    await _initializeRunSession();
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
    _smoothedBarHeights = List<double>.from(
      _VerticalRhythmBarsPainter.restingEnvelope,
    );
    _targetBarHeights = List<double>.from(
      _VerticalRhythmBarsPainter.restingEnvelope,
    );
    _waveformRepaintNotifier.value++;
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
      await _startSensorStream(preserveErrorState: true);
      return;
    }

    await _startSensorStream();
  }

  Future<void> _startSensorStream({bool preserveErrorState = false}) async {
    if (_recordingService.isRecording) {
      await _recordingService.stop();
    }
    if (!mounted) return;

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
          _syncWaveformTicker();
        },
      );

      if (!mounted) return;
      setState(() {
        if (!preserveErrorState) {
          _streamState = _RunStreamState.paused;
          _sensorErrorText = null;
        }
      });
      _syncWaveformTicker();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _streamState = _RunStreamState.sensorError;
        _sensorErrorText = 'Could not start accelerometer stream: $error';
      });
      _syncWaveformTicker();
    }
  }

  void _startElapsedTicker() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _streamState != _RunStreamState.running) return;
      setState(() {
        _activeDurationSeconds += 1.0;
      });
      if (_activeSamples.isNotEmpty) {
        _sensorHealthNotifier.value = RunMetricsCalculator.analyzeSensorHealth(
          samples: _activeSamples,
          requestedRateHz: 100.0,
        );
      }
      if (_foregroundService.isServiceActive) {
        unawaited(
          _foregroundService.updateWorkoutService(
            steps: _primaryDetections.length,
            targetSteps: _labSettings.targetSteps,
            activeDurationSeconds: _activeDurationSeconds,
            targetBpm: _labSettings.targetBpm,
            algorithmName: _labSettings.primaryAlgorithm.displayName,
            isRunning: true,
          ),
        );
      }
    });
  }

  void _handleIncomingSample(SensorSample sample) {
    if (!mounted || _streamState != _RunStreamState.running) return;

    _activeSamples.add(sample);
    _latestSample = sample;

    if (_activeSamples.length % 100 == 0) {
      _flushActiveSessionCache();
    }

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
        _stepFlashTimer?.cancel();
        _stepFlashTimer = Timer(const Duration(milliseconds: 240), () {
          if (mounted) setState(() {});
        });
        if (_foregroundService.isServiceActive) {
          unawaited(
            _foregroundService.updateWorkoutService(
              steps: _primaryDetections.length,
              targetSteps: _labSettings.targetSteps,
              activeDurationSeconds: _activeDurationSeconds,
              targetBpm: _labSettings.targetBpm,
              algorithmName: _labSettings.primaryAlgorithm.displayName,
              isRunning: true,
            ),
          );
        }
      }
      if (primaryOut.step != null || sample.sampleIndex % 3 == 0) {
        _updateTargetWaveformBars(
          stepConfirmed: primaryOut.step != null,
          isStationary: primaryOut.isStationary,
        );
      }
    }

    if (primaryOut?.step != null) {
      setState(() {});
    }
  }

  void _simulateSingleStride() {
    final baseTs = _activeSamples.isEmpty
        ? DateTime.now().microsecondsSinceEpoch * 1000
        : _activeSamples.last.timestampNs + 350000000;

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
        timestampNs: baseTs + i * 25000000,
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
    for (var i = 0; i < _smoothedBarHeights.length; i++) {
      _smoothedBarHeights[i] = _targetBarHeights[i];
    }
    _waveformRepaintNotifier.value++;
    _sensorHealthNotifier.value = RunMetricsCalculator.analyzeSensorHealth(
      samples: _activeSamples,
      requestedRateHz: 100.0,
    );
    setState(() {});
  }

  Future<void> _togglePauseResume() async {
    if (_streamState == _RunStreamState.running) {
      _flushActiveSessionCache();
      setState(() {
        _streamState = _RunStreamState.paused;
      });
      _syncWaveformTicker();
      unawaited(
        _foregroundService.updateWorkoutService(
          steps: _primaryDetections.length,
          targetSteps: _labSettings.targetSteps,
          activeDurationSeconds: _activeDurationSeconds,
          targetBpm: _labSettings.targetBpm,
          algorithmName: _labSettings.primaryAlgorithm.displayName,
          isRunning: false,
        ),
      );
      unawaited(
        _postHogService.captureRunPaused(
          recordingId: _recordingId,
          participantId: _labSettings.participantId,
          elapsedSeconds: _activeDurationSeconds,
          currentSteps: _primaryDetections.length,
        ),
      );
    } else {
      if (!_recordingService.isRecording) {
        await _startSensorStream();
      }
      final isFirstStart = !_hasStartedRun;
      _hasStartedRun = true;
      setState(() {
        _streamState = _RunStreamState.running;
        _sensorErrorText = null;
      });
      _syncWaveformTicker();
      _startElapsedTicker();
      unawaited(_foregroundService.requestNotificationPermission());
      unawaited(
        _foregroundService.startWorkoutService(
          steps: _primaryDetections.length,
          targetSteps: _labSettings.targetSteps,
          activeDurationSeconds: _activeDurationSeconds,
          targetBpm: _labSettings.targetBpm,
          algorithmName: _labSettings.primaryAlgorithm.displayName,
          isRunning: true,
        ),
      );
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
    if (_waveformTicker.isActive) {
      _waveformTicker.stop();
    }
    unawaited(_recordingService.stop());
    unawaited(_foregroundService.stopWorkoutService());

    final palette = StradioPalette.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.squircle),
              boxShadow: palette.cardShadow,
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
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

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

    final fullRecording = SavedRecording(
      recordingId: _recordingId,
      createdAt: DateTime.now(),
      config: config,
      samples: immutableSamples,
      liveStepCount: _primaryDetections.length,
      replayDetections: replayBoth,
      replayVariantDetections: replayAllFour,
      targetBpm: _labSettings.targetBpm,
    );

    final metrics = RunMetricsCalculator.computeSummary(
      detections: _primaryDetections,
      samples: immutableSamples,
      activity: config.activity,
      activeDurationSeconds: math.max(
        _activeDurationSeconds,
        fullRecording.durationSeconds,
      ),
      targetBpm: _labSettings.targetBpm,
      heightCm: widget.userHeightCm,
    );

    final recording = (widget.isConsumerMode && !widget.developerModeEnabled)
        ? fullRecording.toSummaryOnly(
            activeDurationSeconds: metrics.activeDurationSeconds,
            cadenceBucketsSpm: metrics.cadenceBucketsSpm,
            sessionTargetBpm: _labSettings.targetBpm,
          )
        : fullRecording;

    final health = RunMetricsCalculator.analyzeSensorHealth(
      samples: immutableSamples,
      requestedRateHz: config.requestedSamplingRateHz,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final savedAndFinished = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostRunSummaryScreen(
          recording: recording,
          metrics: metrics,
          sensorHealth: health,
          store: _store,
          postHogService: _postHogService,
          developerModeEnabled:
              !widget.isConsumerMode || widget.developerModeEnabled,
        ),
      ),
    );

    if (!mounted) return;
    if (savedAndFinished == true) {
      unawaited(_store.clearActiveSessionCache());
      if (widget.isConsumerMode && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _labSettings = _labSettings.copyWith(
          trialNumber: _labSettings.trialNumber + 1,
        );
        _resetDetectors();
      });
      await _initializeRunSession();
    } else {
      setState(() {
        _streamState = _RunStreamState.paused;
      });
      if (!_recordingService.isRecording) {
        await _startSensorStream();
      }
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
          if (_streamState == _RunStreamState.running ||
              _recordingService.isRecording) {
            unawaited(_recordingService.stop());
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
          unawaited(StradioPreferencesService.saveLabSettings(updated));
          if (_foregroundService.isServiceActive) {
            unawaited(
              _foregroundService.updateWorkoutService(
                steps: _primaryDetections.length,
                targetSteps: _labSettings.targetSteps,
                activeDurationSeconds: _activeDurationSeconds,
                targetBpm: _labSettings.targetBpm,
                algorithmName: _labSettings.primaryAlgorithm.displayName,
                isRunning: _streamState == _RunStreamState.running,
              ),
            );
          }
        },
      ),
    );

    if (!mounted) return;
    if (!_recordingService.isRecording &&
        _streamState != _RunStreamState.sensorError) {
      await _startSensorStream();
    }
  }

  void _updateTargetBpm(int bpm) {
    setState(() {
      _labSettings = _labSettings.copyWith(targetBpm: bpm);
    });
    unawaited(StradioPreferencesService.saveLabSettings(_labSettings));
    if (_foregroundService.isServiceActive) {
      unawaited(
        _foregroundService.updateWorkoutService(
          steps: _primaryDetections.length,
          targetSteps: _labSettings.targetSteps,
          activeDurationSeconds: _activeDurationSeconds,
          targetBpm: _labSettings.targetBpm,
          algorithmName: _labSettings.primaryAlgorithm.displayName,
          isRunning: _streamState == _RunStreamState.running,
        ),
      );
    }
  }

  /// Computes target heights for the 28 vertical equalizer bars directly from
  /// recent magnitude samples with zero intermediate list allocation, letting
  /// `_waveformTicker` interpolate them at smooth 60 FPS inside a RepaintBoundary.
  void _updateTargetWaveformBars({
    required bool stepConfirmed,
    required bool isStationary,
  }) {
    const barCount = 28;
    final len = _recentMagnitudes.length;
    if (len == 0) return;

    var minV = _recentMagnitudes.first;
    var maxV = _recentMagnitudes.first;
    for (final v in _recentMagnitudes) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final rawSpan = maxV - minV;
    final isActuallyStill = isStationary || len < 2 || rawSpan < 0.35;

    if (isActuallyStill) {
      for (var i = 0; i < barCount; i++) {
        final envelopeWeight = _VerticalRhythmBarsPainter.restingEnvelope[i];
        _targetBarHeights[i] = (envelopeWeight * 0.35).clamp(0.10, 0.35);
      }
    } else {
      final span = math.max(5.0, rawSpan);
      final boost = stepConfirmed ? 1.18 : 1.0;
      var idx = 0;
      var nextTargetBar = 0;

      for (final sampleVal in _recentMagnitudes) {
        while (nextTargetBar < barCount) {
          final desiredIdx =
              ((nextTargetBar / (barCount - 1)) * (len - 1)).round();
          if (desiredIdx != idx) break;
          final envelopeWeight =
              _VerticalRhythmBarsPainter.restingEnvelope[nextTargetBar];
          final dynamicRatio = ((sampleVal - minV) / span).clamp(0.12, 1.0);
          _targetBarHeights[nextTargetBar] =
              ((dynamicRatio * 0.72 + envelopeWeight * 0.28) * boost).clamp(
                0.14,
                0.98,
              );
          nextTargetBar++;
        }
        if (nextTargetBar >= barCount) break;
        idx++;
      }
    }

    if (_streamState == _RunStreamState.running && !_waveformTicker.isActive) {
      _waveformTicker.start();
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _stepFlashTimer?.cancel();
    _waveformTicker.dispose();
    _waveformRepaintNotifier.dispose();
    _sensorHealthNotifier.dispose();
    _foregroundService.removeActionListener(_handleNotificationAction);
    unawaited(_foregroundService.stopWorkoutService());
    unawaited(_recordingService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final primarySteps = _primaryDetections.length;
    final formattedSteps = formatStepCount(primarySteps);

    final metrics = RunMetricsCalculator.computeSummary(
      detections: _primaryDetections,
      samples: _activeSamples,
      activity: _labSettings.activity,
      activeDurationSeconds: _activeDurationSeconds,
      targetBpm: _labSettings.targetBpm,
      heightCm: widget.userHeightCm,
    );

    final stepFlashActive =
        _lastStepFlashAt != null &&
        DateTime.now().difference(_lastStepFlashAt!) <
            const Duration(milliseconds: 240);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPad = isWide ? 40.0 : (isTablet ? 28.0 : 20.0);
            final isCompactHeight = constraints.maxHeight < 760;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    // 1. Editorial Top Bar (Profile + Status | Theme Toggle + Labs)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        isCompactHeight ? 8 : 12,
                        horizontalPad,
                        4,
                      ),
                      child: _ActiveRunTopBar(
                        streamState: _streamState,
                        participantId: _labSettings.participantId,
                        isDark: palette.isDark,
                        showBackButton:
                            widget.isConsumerMode &&
                            Navigator.of(context).canPop(),
                        showLabsButton:
                            !widget.isConsumerMode ||
                            widget.developerModeEnabled,
                        onToggleTheme: widget.onToggleThemeMode,
                        onOpenLabs: _openSensorLabsDrawer,
                      ),
                    ),

                    // 2. Main Content Area (Zero-Scroll Unified Stride Deck in normal mode)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: isCompactHeight ? 6 : 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Editorial Greeting & Tempo Header (Point 7.1)
                            _EditorialRunHeader(
                              targetBpm: _labSettings.targetBpm,
                              algorithmCode: _primaryVariant.code,
                              showAlgorithmBadge:
                                  !widget.isConsumerMode ||
                                  widget.developerModeEnabled,
                              onSelectBpm: _updateTargetBpm,
                            ),
                            SizedBox(height: isCompactHeight ? 10 : 14),

                            // State Banners (Loading / Error / Standby fallback)
                            if (_streamState == _RunStreamState.connecting)
                              _StatusStateBanner(
                                icon: Icons.sensors,
                                accentColor: palette.accentViolet,
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

                            // Developer Mode Live Overlay (Only when toggled ON in Sensor Labs)
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
                              const SizedBox(height: 12),
                            ],

                            // 3. Hero Waveform Card (28px Deep Pebble, Vertical Rhythm Bars)
                            _AudioStrideVisualizerCard(
                              smoothedBarHeights: _smoothedBarHeights,
                              waveformRepaint: _waveformRepaintNotifier,
                              isRunning:
                                  _streamState == _RunStreamState.running,
                              isStationary:
                                  _latestPrimaryOutput?.isStationary ?? true,
                              stepFlashActive: stepFlashActive,
                              targetBpm: _labSettings.targetBpm,
                              cadenceSpm: metrics.liveCadenceSpm.round(),
                              height: isTablet
                                  ? 215
                                  : (isCompactHeight ? 168 : 188),
                              onCenterPlayTap: _togglePauseResume,
                            ),
                            SizedBox(height: isCompactHeight ? 12 : 16),

                            // 4. Unified Stride Goal & 3-Column Metrics Deck (20px Squircle)
                            _UnifiedStrideDeck(
                              formattedSteps: formattedSteps,
                              primarySteps: primarySteps,
                              targetSteps: _labSettings.targetSteps,
                              stepFlashActive: stepFlashActive,
                              cadenceText:
                                  '${metrics.liveCadenceSpm.round()} SPM',
                              elapsedText: metrics.formattedDuration,
                              speedText:
                                  '${metrics.speedKmh.toStringAsFixed(1)} km/h',
                              isCompact: isCompactHeight,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. Thumb-Zone Bottom Control Deck (28px Hero + 999px Stadium)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        6,
                        horizontalPad,
                        isCompactHeight ? 10 : 14,
                      ),
                      child: _BottomControlDeck(
                        isRunning: _streamState == _RunStreamState.running,
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
    required this.participantId,
    required this.isDark,
    this.showBackButton = false,
    this.showLabsButton = true,
    required this.onToggleTheme,
    required this.onOpenLabs,
  });

  final _RunStreamState streamState;
  final String participantId;
  final bool isDark;
  final bool showBackButton;
  final bool showLabsButton;
  final VoidCallback? onToggleTheme;
  final VoidCallback onOpenLabs;

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final (statusLabel, dotColor) = switch (streamState) {
      _RunStreamState.running => ('RUNNING', StradioColors.statusLive),
      _RunStreamState.paused => ('PAUSED', StradioColors.statusPaused),
      _RunStreamState.connecting => ('CONNECTING', palette.accentViolet),
      _RunStreamState.sensorError => ('STANDBY', StradioColors.statusPaused),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Optional Back Button + Official Stradio Brand Logo + Dynamic Status Pill
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBackButton) ...[
                IconButton(
                  key: const Key('active_run_back_button'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: palette.surface,
                    minimumSize: const Size(44, 44),
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: palette.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Image.asset(
                'assets/images/stradio-logo.png',
                key: const Key('stradio_header_logo'),
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                  boxShadow: palette.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: const Key('status_indicator_dot'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      overflow: TextOverflow.ellipsis,
                      style: StradioTypography.interLabel(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right: Theme Mode Toggle (Light/Dark) + Sensor Labs Icon (when Developer Mode is enabled)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleTheme != null) ...[
              IconButton(
                key: const Key('theme_mode_toggle_button'),
                onPressed: onToggleTheme,
                tooltip: isDark
                    ? 'Switch to Warm Ivory Light Mode'
                    : 'Switch to Deep Obsidian Dark Mode',
                style: IconButton.styleFrom(
                  backgroundColor: palette.surface,
                  minimumSize: const Size(44, 44),
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: palette.textPrimary,
                  size: 20,
                ),
              ),
              if (showLabsButton) const SizedBox(width: 8),
            ],
            if (showLabsButton)
              Semantics(
                button: true,
                label: 'Open Sensor Labs and Diagnostics',
                child: IconButton(
                  key: const Key('open_sensor_labs_button'),
                  onPressed: onOpenLabs,
                  tooltip: 'Sensor Labs & Diagnostics',
                  style: IconButton.styleFrom(
                    backgroundColor: palette.surface,
                    minimumSize: const Size(48, 48),
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    Icons.science_outlined,
                    color: palette.accentViolet,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EditorialRunHeader extends StatelessWidget {
  const _EditorialRunHeader({
    required this.targetBpm,
    required this.algorithmCode,
    this.showAlgorithmBadge = true,
    required this.onSelectBpm,
  });

  final int targetBpm;
  final String algorithmCode;
  final bool showAlgorithmBadge;
  final ValueChanged<int> onSelectBpm;

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Editorial two-tone headline inspired by Reference 1 & 2
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: StradioTypography.soraHeading(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    const TextSpan(text: 'Run the '),
                    TextSpan(
                      text: 'Vibe',
                      style: TextStyle(color: palette.accentCoral),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Neon Stride · Adaptive Stride',
                      key: const Key('soundscape_title_text'),
                      overflow: TextOverflow.ellipsis,
                      style: StradioTypography.interLabel(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (showAlgorithmBadge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceSubtle,
                        borderRadius: BorderRadius.circular(StradioRadii.pill),
                      ),
                      child: Text(
                        '$algorithmCode Midpoint',
                        style: StradioTypography.interLabel(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Compact Stadium Tempo BPM Selector
        PopupMenuButton<int>(
          key: const Key('tempo_bpm_selector_button'),
          tooltip: 'Select Target Tempo BPM',
          onSelected: onSelectBpm,
          color: palette.surface,
          elevation: 4,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 118, child: Text('118 BPM (Brisk Walk)')),
            PopupMenuItem(value: 145, child: Text('145 BPM (Tempo Jog)')),
            PopupMenuItem(value: 165, child: Text('165 BPM (Neon Stride)')),
          ],
          child: Container(
            key: const Key('utility_bpm_selector_button'),
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.pill),
              boxShadow: palette.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 15,
                  color: palette.accentViolet,
                ),
                const SizedBox(width: 6),
                Text(
                  '$targetBpm BPM',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: palette.textSecondary,
                ),
              ],
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
    final palette = StradioPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
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
                color: palette.textPrimary,
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

/// Hero Waveform Card (28px Deep Pebble Squircle, 100% Borderless).
///
/// Renders vertical stadium-capped rhythm equalizer bars (Reference 2) reactive
/// to real-time 100 Hz foot-strike accelerometer magnitudes.
class _AudioStrideVisualizerCard extends StatelessWidget {
  const _AudioStrideVisualizerCard({
    required this.smoothedBarHeights,
    required this.waveformRepaint,
    required this.isRunning,
    required this.isStationary,
    required this.stepFlashActive,
    required this.targetBpm,
    required this.cadenceSpm,
    required this.height,
    this.onCenterPlayTap,
  });

  final List<double> smoothedBarHeights;
  final Listenable waveformRepaint;
  final bool isRunning;
  final bool isStationary;
  final bool stepFlashActive;
  final int targetBpm;
  final int cadenceSpm;
  final double height;
  final VoidCallback? onCenterPlayTap;

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label:
          'Audio-stride reactive waveform visualizer, ${isRunning ? "active" : "paused"}',
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(StradioRadii.hero),
          boxShadow: [
            ...palette.cardShadow,
            if (stepFlashActive)
              BoxShadow(
                color: StradioColors.sonicCoral.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'AUDIO-STRIDE WAVEFORM',
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 10,
                      color: palette.textSecondary,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$targetBpm BPM TARGET',
                  style: StradioTypography.interLabel(
                    fontSize: 10,
                    color: isRunning
                        ? palette.accentViolet
                        : palette.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vertical Rhythm Equalizer Bars + Standby Center Trigger
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _VerticalRhythmBarsPainter(
                          smoothedBarHeights: smoothedBarHeights,
                          repaint: waveformRepaint,
                          isRunning: isRunning,
                          isStationary: isStationary,
                          stepFlashActive: stepFlashActive && !reduceMotion,
                          primaryColor: palette.accentCoral,
                          secondaryColor: palette.accentViolet,
                          restingColor: palette.textMuted.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),

                  // Center Rhythm Core Emblem (Non-button: pulses with tempo & foot-strike impact)
                  Semantics(
                    label: 'Rhythm Core Status Indicator',
                    child: Container(
                      key: const Key('hero_rhythm_core_emblem'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surface.withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(
                            color: (stepFlashActive
                                    ? palette.accentCoral
                                    : palette.accentViolet)
                                .withValues(alpha: stepFlashActive ? 0.38 : 0.22),
                            blurRadius: stepFlashActive ? 20 : 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 24,
                          color: stepFlashActive
                              ? palette.accentCoral
                              : (isRunning
                                  ? palette.accentViolet
                                  : palette.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Card Footer: Cadence Sync & Reactive State
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Cadence Sync: $cadenceSpm SPM',
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning
                              ? StradioColors.sonicCoral
                              : palette.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isRunning ? 'Live Reactive' : 'Standby Preview',
                          overflow: TextOverflow.ellipsis,
                          style: StradioTypography.interLabel(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isRunning
                                ? palette.accentCoral
                                : palette.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile vertical rhythm equalizer bars (Reference 2 aesthetic).
///
/// Renders 28 stadium-capped vertical bars whose amplitudes are driven by real
/// accelerometer magnitude samples when moving, or rest in a composed symmetric
/// envelope when paused/stationary.
class _VerticalRhythmBarsPainter extends CustomPainter {
  const _VerticalRhythmBarsPainter({
    required this.smoothedBarHeights,
    required Listenable repaint,
    required this.isRunning,
    required this.isStationary,
    required this.stepFlashActive,
    required this.primaryColor,
    required this.secondaryColor,
    required this.restingColor,
  }) : super(repaint: repaint);

  final List<double> smoothedBarHeights;
  final bool isRunning;
  final bool isStationary;
  final bool stepFlashActive;
  final Color primaryColor;
  final Color secondaryColor;
  final Color restingColor;

  // Symmetric Reference-2-inspired resting equalizer envelope (normalized 0.14..0.72)
  static const List<double> restingEnvelope = [
    0.16,
    0.24,
    0.34,
    0.22,
    0.46,
    0.60,
    0.38,
    0.54,
    0.70,
    0.48,
    0.64,
    0.76,
    0.58,
    0.42,
    0.42,
    0.58,
    0.76,
    0.64,
    0.48,
    0.70,
    0.54,
    0.38,
    0.60,
    0.46,
    0.22,
    0.34,
    0.24,
    0.16,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = restingEnvelope.length;
    final midY = size.height / 2;
    final maxHalfHeight = size.height * 0.44;

    final spacing = size.width / barCount;
    final strokeWidth = (spacing * 0.46).clamp(3.0, 6.5);

    // Pre-allocate paints and colors once per frame (zero heap churn per bar)
    final trackPaint = Paint()
      ..color = restingColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final baseOuterColor = Color.lerp(primaryColor, secondaryColor, 0.65)!;
    final innerColor = isRunning
        ? primaryColor
        : primaryColor.withValues(alpha: 0.72);
    final outerColor = isRunning
        ? baseOuterColor
        : baseOuterColor.withValues(alpha: 0.72);

    final activePaint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final centerIndex = (barCount - 1) / 2;
    final halfSpan = barCount / 2;

    for (var i = 0; i < barCount; i++) {
      final x = (i + 0.5) * spacing;
      final envelopeWeight = restingEnvelope[i];

      final normalizedHeight = !isRunning
          ? envelopeWeight
          : (i < smoothedBarHeights.length
                ? smoothedBarHeights[i]
                : envelopeWeight * 0.35);

      final halfBar = math.max(4.0, normalizedHeight * maxHalfHeight);
      final distanceFromCenter = ((i - centerIndex).abs()) / halfSpan;

      // Background subtle track bar
      final trackHalf = math.max(halfBar + 4.0, envelopeWeight * maxHalfHeight);
      canvas.drawLine(
        Offset(x, midY - trackHalf),
        Offset(x, midY + trackHalf),
        trackPaint,
      );

      // Foreground active rhythm bar with spring inertia
      activePaint.color = distanceFromCenter < 0.55 ? innerColor : outerColor;
      canvas.drawLine(
        Offset(x, midY - halfBar),
        Offset(x, midY + halfBar),
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalRhythmBarsPainter oldDelegate) =>
      oldDelegate.smoothedBarHeights != smoothedBarHeights ||
      oldDelegate.isRunning != isRunning ||
      oldDelegate.isStationary != isStationary ||
      oldDelegate.stepFlashActive != stepFlashActive ||
      oldDelegate.primaryColor != primaryColor;
}

/// Unified Stride Goal & 3-Column Metrics Deck (20px Squircle, 100% Borderless).
///
/// Combines the session goal progress bar (`84 / 100`) and the 3 primary runner
/// readouts (`STEPS`, `CADENCE`, `TIME ELAPSED`) into one cohesive, zero-scroll card.
class _UnifiedStrideDeck extends StatelessWidget {
  const _UnifiedStrideDeck({
    required this.formattedSteps,
    required this.primarySteps,
    required this.targetSteps,
    required this.stepFlashActive,
    required this.cadenceText,
    required this.elapsedText,
    required this.speedText,
    required this.isCompact,
  });

  final String formattedSteps;
  final int primarySteps;
  final int targetSteps;
  final bool stepFlashActive;
  final String cadenceText;
  final String elapsedText;
  final String speedText;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final safeTarget = targetSteps > 0 ? targetSteps : 100;
    final progress = (primarySteps / safeTarget).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Stride Goal Header + Progress Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'STRIDE GOAL',
                  overflow: TextOverflow.ellipsis,
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$primarySteps / $safeTarget ($percentage%)',
                  overflow: TextOverflow.ellipsis,
                  style: StradioTypography.interLabel(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stadium Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(StradioRadii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: palette.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accentCoral),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 18),

          // 3-Column Primary Runner Metrics (Steps | Cadence | Time)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Column 1: Hero Step Count
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedSteps,
                      key: const Key('active_run_step_count'),
                      style: StradioTypography.soraMetric(
                        fontSize: isCompact ? 42 : 48,
                        fontWeight: FontWeight.w800,
                        color: stepFlashActive
                            ? palette.accentCoral
                            : palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'STEPS',
                      style: StradioTypography.soraHeading(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Column 2: Cadence SPM
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      cadenceText,
                      key: const Key('metric_cadence_value'),
                      textAlign: TextAlign.center,
                      style: StradioTypography.soraMetric(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CADENCE',
                      style: StradioTypography.interLabel(
                        fontSize: 10,
                        color: palette.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Column 3: Elapsed Time & Est. Speed
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elapsedText,
                      key: const Key('metric_elapsed_value'),
                      textAlign: TextAlign.right,
                      style: StradioTypography.soraMetric(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TIME · $speedText',
                      key: const Key('metric_speed_value'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StradioTypography.interLabel(
                        fontSize: 10,
                        color: palette.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final palette = StradioPalette.of(context);
    final s = latestSample;
    final out = latestOutput;

    return Container(
      key: const Key('developer_telemetry_overlay'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 16,
                color: palette.accentViolet,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LIVE 100HZ TELEMETRY & 4-ALGORITHM MATRIX',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: palette.accentViolet,
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
                icon: Icon(
                  Icons.directions_run,
                  size: 15,
                  color: palette.accentCoral,
                ),
                label: Text(
                  '+1 Stride',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: palette.accentCoral,
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
              color: palette.textPrimary,
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
              color: palette.textSecondary,
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
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.tag),
                  ),
                  child: Text(
                    '${variant.code}: ${liveCounts[variant] ?? 0} steps',
                    key: Key('live_variant_count_${variant.code}'),
                    style: StradioTypography.interLabel(
                      fontSize: 12,
                      color: palette.textPrimary,
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

/// Thumb-Zone Bottom Control Deck (28px Hero container + 999px Stadium Finish CTA).
class _BottomControlDeck extends StatelessWidget {
  const _BottomControlDeck({
    required this.isRunning,
    required this.onTogglePauseResume,
    required this.onFinishRun,
  });

  final bool isRunning;
  final VoidCallback onTogglePauseResume;
  final VoidCallback onFinishRun;

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          // Circular Pause / Resume CTA in vibrant Sonic Coral
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
                    color: StradioColors.sonicCoral.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                key: const Key('pause_resume_run_button'),
                onPressed: onTogglePauseResume,
                tooltip: isRunning ? 'Pause Run' : 'Resume Run',
                icon: Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Stadium "Finish Run" Accessible Button
          Expanded(
            child: _FinishRunButton(
              onFinishRun: onFinishRun,
            ),
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
    final palette = StradioPalette.of(context);

    return Semantics(
      button: true,
      label: 'Finish Run',
      child: Material(
        color: palette.surfaceSubtle,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const Key('finish_run_button'),
          onTap: onFinishRun,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'Finish Run',
                style: StradioTypography.soraHeading(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
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
