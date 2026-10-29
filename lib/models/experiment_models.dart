import 'dart:math' as math;

/// Factor C: activity performed during a trial.
enum Activity { walking, jogging }

/// Factor B: where the phone is carried during a trial.
enum PhonePlacement { hand, pocket }

/// Factor A: the adaptive-threshold algorithm.
enum ThresholdAlgorithm { adaptiveMidpoint, meanStd }

/// The 4 simultaneous algorithm + sensor stream combinations defined in PLANNING.md:
/// - A1: Adaptive Midpoint + Raw Accelerometer (with gravity)
/// - A2: Adaptive Midpoint + User Accelerometer (linear / without gravity)
/// - B1: Mean + k·SD + Raw Accelerometer (with gravity)
/// - B2: Mean + k·SD + User Accelerometer (linear / without gravity)
enum AlgorithmVariant {
  a1MidpointRaw,
  a2MidpointLinear,
  b1MeanSdRaw,
  b2MeanSdLinear,
}

extension ActivityLabel on Activity {
  /// Exported label (`walking` / `jogging`).
  String get value => name;

  static Activity parse(String value) =>
      Activity.values.firstWhere((a) => a.value == value);
}

extension PhonePlacementLabel on PhonePlacement {
  /// Exported label (`hand` / `pocket`).
  String get value => name;

  static PhonePlacement parse(String value) =>
      PhonePlacement.values.firstWhere((p) => p.value == value);
}

extension ThresholdAlgorithmLabel on ThresholdAlgorithm {
  /// Exported label (`adaptive_midpoint` / `mean_std`).
  String get value => switch (this) {
    ThresholdAlgorithm.adaptiveMidpoint => 'adaptive_midpoint',
    ThresholdAlgorithm.meanStd => 'mean_std',
  };

  /// Human-readable name shown in the UI.
  String get displayName => switch (this) {
    ThresholdAlgorithm.adaptiveMidpoint => 'Adaptive midpoint',
    ThresholdAlgorithm.meanStd => 'Mean + k·SD',
  };

  static ThresholdAlgorithm parse(String value) =>
      ThresholdAlgorithm.values.firstWhere((a) => a.value == value);
}

extension AlgorithmVariantLabel on AlgorithmVariant {
  /// Matrix code (`A1`, `A2`, `B1`, `B2`).
  String get code => switch (this) {
    AlgorithmVariant.a1MidpointRaw => 'A1',
    AlgorithmVariant.a2MidpointLinear => 'A2',
    AlgorithmVariant.b1MeanSdRaw => 'B1',
    AlgorithmVariant.b2MeanSdLinear => 'B2',
  };

  /// Exported CSV / JSON identifier.
  String get value => switch (this) {
    AlgorithmVariant.a1MidpointRaw => 'adaptive_midpoint',
    AlgorithmVariant.a2MidpointLinear => 'adaptive_midpoint_linear',
    AlgorithmVariant.b1MeanSdRaw => 'mean_std',
    AlgorithmVariant.b2MeanSdLinear => 'mean_sd_linear',
  };

  /// Human-readable name shown on the Scoreboard.
  String get displayName => switch (this) {
    AlgorithmVariant.a1MidpointRaw => 'Adaptive Midpoint (Raw +G)',
    AlgorithmVariant.a2MidpointLinear => 'Adaptive Midpoint (Linear -G)',
    AlgorithmVariant.b1MeanSdRaw => 'Mean + k·SD (Raw +G)',
    AlgorithmVariant.b2MeanSdLinear => 'Mean + k·SD (Linear -G)',
  };

  /// Sensor stream label.
  String get sensorLabel =>
      usesLinearAcceleration ? 'User Accel (No Gravity)' : 'Raw Accel (+Gravity)';

  ThresholdAlgorithm get thresholdAlgorithm => switch (this) {
    AlgorithmVariant.a1MidpointRaw ||
    AlgorithmVariant.a2MidpointLinear => ThresholdAlgorithm.adaptiveMidpoint,
    AlgorithmVariant.b1MeanSdRaw ||
    AlgorithmVariant.b2MeanSdLinear => ThresholdAlgorithm.meanStd,
  };

  bool get usesLinearAcceleration => switch (this) {
    AlgorithmVariant.a1MidpointRaw || AlgorithmVariant.b1MeanSdRaw => false,
    AlgorithmVariant.a2MidpointLinear || AlgorithmVariant.b2MeanSdLinear => true,
  };

  static AlgorithmVariant parse(String value) =>
      AlgorithmVariant.values.firstWhere(
        (v) => v.value == value || v.code == value,
        orElse: () => AlgorithmVariant.a1MidpointRaw,
      );
}

/// Returns the experiment condition ID (E1–E8) from the AGENTS.md table.
String conditionId(
  Activity activity,
  PhonePlacement placement,
  ThresholdAlgorithm algorithm,
) {
  final base = placement == PhonePlacement.hand ? 0 : 4;
  final activityOffset = activity == Activity.walking ? 0 : 2;
  final algorithmOffset = algorithm == ThresholdAlgorithm.adaptiveMidpoint
      ? 1
      : 2;
  return 'E${base + activityOffset + algorithmOffset}';
}

/// Signal-processing parameters shared by all algorithms in the comparison.
class AlgorithmParameters {
  const AlgorithmParameters({
    this.smoothingSamples = 3,
    this.windowDurationMs = 1000,
    this.minimumStepIntervalMs = 250,
    this.k = 1.5,
    this.minWindowSpreadMps2 = 1.2,
  });

  final int smoothingSamples;
  final int windowDurationMs;
  final int minimumStepIntervalMs;
  final double k;

  /// Minimum dynamic range (`max(window) - min(window)`) in m/s² required in
  /// the rolling window to accept a candidate step. Prevents thermal/MEMS
  /// micro-noise from triggering false steps when the phone rests stationary
  /// on a table (~0.01–0.15 m/s² spread).
  final double minWindowSpreadMps2;

  Map<String, Object> toMap() => {
    'smoothing_samples': smoothingSamples,
    'window_duration_ms': windowDurationMs,
    'minimum_step_interval_ms': minimumStepIntervalMs,
    'k': k,
    'min_window_spread_mps2': minWindowSpreadMps2,
  };

  factory AlgorithmParameters.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AlgorithmParameters();
    return AlgorithmParameters(
      smoothingSamples: (map['smoothing_samples'] as num?)?.toInt() ?? 3,
      windowDurationMs: (map['window_duration_ms'] as num?)?.toInt() ?? 1000,
      minimumStepIntervalMs:
          (map['minimum_step_interval_ms'] as num?)?.toInt() ?? 250,
      k: (map['k'] as num?)?.toDouble() ?? 1.5,
      minWindowSpreadMps2:
          (map['min_window_spread_mps2'] as num?)?.toDouble() ?? 1.2,
    );
  }
}

/// Settings captured on the setup screen. The settings are fixed when the
/// recording starts, so editing the form afterwards cannot change them.
class ExperimentConfig {
  const ExperimentConfig({
    required this.participantId,
    required this.activity,
    required this.phonePlacement,
    required this.placementDetail,
    required this.trialNumber,
    this.primaryLiveAlgorithm = ThresholdAlgorithm.adaptiveMidpoint,
    this.targetSteps = defaultTargetSteps,
    this.fallbackTimeoutSeconds = 0,
    this.notes = '',
    this.requestedSamplingRateHz = 100,
    this.parameters = const AlgorithmParameters(),
  });

  static const defaultTargetSteps = 100;

  final String participantId;
  final Activity activity;
  final PhonePlacement phonePlacement;
  final String placementDetail;
  final int trialNumber;
  final ThresholdAlgorithm primaryLiveAlgorithm;

  /// Ground-truth physical steps in the trial (fixed at 100 by protocol).
  final int targetSteps;

  /// Optional safety stop in seconds; `0` disables it. The normal stop is the
  /// manual "Stop (100 Steps Completed)" button.
  final int fallbackTimeoutSeconds;
  final String notes;
  final double requestedSamplingRateHz;
  final AlgorithmParameters parameters;

  List<String> validate() => [
    if (!RegExp(r'^P[0-9]+$').hasMatch(participantId))
      'Participant ID must look like P01.',
    if (placementDetail.trim().isEmpty) 'Placement detail is required.',
    if (trialNumber < 1) 'Trial number must be positive.',
    if (targetSteps < 1) 'Target steps must be positive.',
    if (fallbackTimeoutSeconds < 0) 'Fallback timeout must not be negative.',
    if (requestedSamplingRateHz <= 0)
      'Requested sampling rate must be positive.',
    if (parameters.smoothingSamples < 1) 'Smoothing window must be positive.',
    if (parameters.windowDurationMs < 1) 'Adaptive window must be positive.',
    if (parameters.minimumStepIntervalMs < 1)
      'Minimum step interval must be positive.',
    if (parameters.k < 0) 'k must not be negative.',
    if (parameters.minWindowSpreadMps2 < 0)
      'Stationary noise floor must not be negative.',
  ];

  Map<String, Object> toMap() => {
    'participant_id': participantId,
    'activity': activity.value,
    'phone_placement': phonePlacement.value,
    'placement_detail': placementDetail,
    'trial_number': trialNumber,
    'primary_live_algorithm': primaryLiveAlgorithm.value,
    'target_steps': targetSteps,
    'fallback_timeout_seconds': fallbackTimeoutSeconds,
    'notes': notes,
    'requested_sampling_rate_hz': requestedSamplingRateHz,
    'algorithm_parameters': parameters.toMap(),
  };

  factory ExperimentConfig.fromMap(Map<String, dynamic> map) =>
      ExperimentConfig(
        participantId: map['participant_id']?.toString() ?? '',
        activity: ActivityLabel.parse(map['activity'].toString()),
        phonePlacement: PhonePlacementLabel.parse(
          map['phone_placement'].toString(),
        ),
        placementDetail: map['placement_detail']?.toString() ?? '',
        trialNumber: (map['trial_number'] as num?)?.toInt() ?? 0,
        primaryLiveAlgorithm: ThresholdAlgorithmLabel.parse(
          map['primary_live_algorithm']?.toString() ?? 'adaptive_midpoint',
        ),
        targetSteps:
            (map['target_steps'] as num?)?.toInt() ?? defaultTargetSteps,
        fallbackTimeoutSeconds:
            (map['fallback_timeout_seconds'] as num?)?.toInt() ?? 0,
        notes: map['notes']?.toString() ?? '',
        requestedSamplingRateHz:
            (map['requested_sampling_rate_hz'] as num?)?.toDouble() ?? 100,
        parameters: AlgorithmParameters.fromMap(
          map['algorithm_parameters'] as Map<String, dynamic>?,
        ),
      );
}

/// Synchronized accelerometer reading containing both Stream A (Raw with gravity)
/// and Stream B (User/Linear without gravity).
class SensorSample {
  const SensorSample({
    required this.recordingId,
    required this.sampleIndex,
    required this.timestampNs,
    required this.axMps2,
    required this.ayMps2,
    required this.azMps2,
    this.uxMps2 = 0.0,
    this.uyMps2 = 0.0,
    this.uzMps2 = 0.0,
  });

  final String recordingId;
  final int sampleIndex;
  final int timestampNs;

  /// Raw accelerometer axes (includes Earth gravity ~9.81 m/s²).
  final double axMps2;
  final double ayMps2;
  final double azMps2;

  /// Linear/User accelerometer axes (gravity removed, ~0.0 m/s² at rest).
  final double uxMps2;
  final double uyMps2;
  final double uzMps2;

  /// Stream A norm: m_raw(t) = sqrt(ax² + ay² + az²)
  double get magnitudeMps2 =>
      math.sqrt(axMps2 * axMps2 + ayMps2 * ayMps2 + azMps2 * azMps2);

  /// Stream B norm: m_user(t) = sqrt(ux² + uy² + uz²)
  double get userMagnitudeMps2 =>
      math.sqrt(uxMps2 * uxMps2 + uyMps2 * uyMps2 + uzMps2 * uzMps2);

  /// True when non-zero linear accelerometer readings are present on this sample.
  bool get hasLinearReading =>
      uxMps2 != 0.0 || uyMps2 != 0.0 || uzMps2 != 0.0;

  Map<String, Object> toMap() => {
    'sample_index': sampleIndex,
    'timestamp_ns': timestampNs,
    'ax_mps2': axMps2,
    'ay_mps2': ayMps2,
    'az_mps2': azMps2,
    'magnitude_mps2': magnitudeMps2,
    'ux_mps2': uxMps2,
    'uy_mps2': uyMps2,
    'uz_mps2': uzMps2,
    'user_magnitude_mps2': userMagnitudeMps2,
  };

  factory SensorSample.fromMap(String recordingId, Map<String, dynamic> map) =>
      SensorSample(
        recordingId: recordingId,
        sampleIndex: (map['sample_index'] as num?)?.toInt() ?? 0,
        timestampNs: (map['timestamp_ns'] as num?)?.toInt() ?? 0,
        axMps2: (map['ax_mps2'] as num?)?.toDouble() ?? 0,
        ayMps2: (map['ay_mps2'] as num?)?.toDouble() ?? 0,
        azMps2: (map['az_mps2'] as num?)?.toDouble() ?? 0,
        uxMps2: (map['ux_mps2'] as num?)?.toDouble() ?? 0,
        uyMps2: (map['uy_mps2'] as num?)?.toDouble() ?? 0,
        uzMps2: (map['uz_mps2'] as num?)?.toDouble() ?? 0,
      );
}

/// A confirmed step emitted by a detector.
class DetectionEvent {
  const DetectionEvent({
    required this.detectionId,
    required this.sampleIndex,
    required this.peakTimestampNs,
    required this.outputTimestampNs,
    required this.thresholdMps2,
  });

  final int detectionId;

  /// Index of the sample at the peak.
  final int sampleIndex;
  final int peakTimestampNs;

  /// Timestamp of the sample that confirmed the peak (the decision time).
  final int outputTimestampNs;
  final double thresholdMps2;

  Map<String, Object> toMap() => {
    'detection_id': detectionId,
    'sample_index': sampleIndex,
    'peak_timestamp_ns': peakTimestampNs,
    'output_timestamp_ns': outputTimestampNs,
    'threshold_mps2': thresholdMps2,
  };

  factory DetectionEvent.fromMap(Map<String, dynamic> map) => DetectionEvent(
    detectionId: (map['detection_id'] as num?)?.toInt() ?? 0,
    sampleIndex: (map['sample_index'] as num?)?.toInt() ?? 0,
    peakTimestampNs: (map['peak_timestamp_ns'] as num?)?.toInt() ?? 0,
    outputTimestampNs: (map['output_timestamp_ns'] as num?)?.toInt() ?? 0,
    thresholdMps2: (map['threshold_mps2'] as num?)?.toDouble() ?? 0,
  );
}

/// A finished trial. Raw samples are never changed after saving.
class SavedRecording {
  const SavedRecording({
    required this.recordingId,
    required this.createdAt,
    required this.config,
    required this.samples,
    required this.liveStepCount,
    required this.replayDetections,
    this.replayVariantDetections = const {},
  });

  final String recordingId;
  final DateTime createdAt;
  final ExperimentConfig config;
  final List<SensorSample> samples;

  /// Steps counted live by [ExperimentConfig.primaryLiveAlgorithm].
  final int liveStepCount;

  /// Offline replay results for the primary 2 algorithms (Raw stream: A1 & B1).
  final Map<ThresholdAlgorithm, List<DetectionEvent>> replayDetections;

  /// Offline replay results across all 4 combinations (A1, A2, B1, B2).
  final Map<AlgorithmVariant, List<DetectionEvent>> replayVariantDetections;

  int replayCount(ThresholdAlgorithm algorithm) =>
      replayDetections[algorithm]?.length ?? 0;

  int replayVariantCount(AlgorithmVariant variant) {
    final direct = replayVariantDetections[variant];
    if (direct != null) return direct.length;
    if (!variant.usesLinearAcceleration) {
      return replayCount(variant.thresholdAlgorithm);
    }
    return 0;
  }

  /// True when the live count equals the replay count of the same algorithm.
  bool get liveMatchesReplay =>
      liveStepCount == replayCount(config.primaryLiveAlgorithm);

  double get durationSeconds => samples.length < 2
      ? 0
      : (samples.last.timestampNs - samples.first.timestampNs) / 1e9;
}
