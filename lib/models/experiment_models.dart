import 'dart:math' as math;

/// Factor C: activity performed during a trial.
enum Activity { walking, jogging }

/// Factor B: where the phone is carried during a trial.
enum PhonePlacement { hand, pocket }

/// Factor A: the adaptive-threshold algorithm.
enum ThresholdAlgorithm { adaptiveMidpoint, meanStd }

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

/// Signal-processing parameters shared by both algorithms in the primary
/// comparison. The initial `k = 1.5` is a documented starting point, not a
/// claimed optimum; it can be changed for parameter sweeps.
class AlgorithmParameters {
  const AlgorithmParameters({
    this.smoothingSamples = 3,
    this.windowDurationMs = 1000,
    this.minimumStepIntervalMs = 250,
    this.k = 1.5,
  });

  final int smoothingSamples;
  final int windowDurationMs;
  final int minimumStepIntervalMs;
  final double k;

  Map<String, Object> toMap() => {
    'smoothing_samples': smoothingSamples,
    'window_duration_ms': windowDurationMs,
    'minimum_step_interval_ms': minimumStepIntervalMs,
    'k': k,
  };

  factory AlgorithmParameters.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AlgorithmParameters();
    return AlgorithmParameters(
      smoothingSamples: (map['smoothing_samples'] as num?)?.toInt() ?? 3,
      windowDurationMs: (map['window_duration_ms'] as num?)?.toInt() ?? 1000,
      minimumStepIntervalMs:
          (map['minimum_step_interval_ms'] as num?)?.toInt() ?? 250,
      k: (map['k'] as num?)?.toDouble() ?? 1.5,
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

/// One raw accelerometer reading. Gravity is included (no subtraction).
class SensorSample {
  const SensorSample({
    required this.recordingId,
    required this.sampleIndex,
    required this.timestampNs,
    required this.axMps2,
    required this.ayMps2,
    required this.azMps2,
  });

  final String recordingId;
  final int sampleIndex;
  final int timestampNs;
  final double axMps2;
  final double ayMps2;
  final double azMps2;

  /// m(t) = sqrt(ax² + ay² + az²)
  double get magnitudeMps2 =>
      math.sqrt(axMps2 * axMps2 + ayMps2 * ayMps2 + azMps2 * azMps2);

  Map<String, Object> toMap() => {
    'sample_index': sampleIndex,
    'timestamp_ns': timestampNs,
    'ax_mps2': axMps2,
    'ay_mps2': ayMps2,
    'az_mps2': azMps2,
    'magnitude_mps2': magnitudeMps2,
  };

  factory SensorSample.fromMap(String recordingId, Map<String, dynamic> map) =>
      SensorSample(
        recordingId: recordingId,
        sampleIndex: (map['sample_index'] as num?)?.toInt() ?? 0,
        timestampNs: (map['timestamp_ns'] as num?)?.toInt() ?? 0,
        axMps2: (map['ax_mps2'] as num?)?.toDouble() ?? 0,
        ayMps2: (map['ay_mps2'] as num?)?.toDouble() ?? 0,
        azMps2: (map['az_mps2'] as num?)?.toDouble() ?? 0,
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
  });

  final String recordingId;
  final DateTime createdAt;
  final ExperimentConfig config;
  final List<SensorSample> samples;

  /// Steps counted live by [ExperimentConfig.primaryLiveAlgorithm].
  final int liveStepCount;

  /// Offline replay results for both algorithms on the same samples.
  final Map<ThresholdAlgorithm, List<DetectionEvent>> replayDetections;

  int replayCount(ThresholdAlgorithm algorithm) =>
      replayDetections[algorithm]?.length ?? 0;

  /// True when the live count equals the replay count of the same algorithm.
  bool get liveMatchesReplay =>
      liveStepCount == replayCount(config.primaryLiveAlgorithm);

  double get durationSeconds => samples.length < 2
      ? 0
      : (samples.last.timestampNs - samples.first.timestampNs) / 1e9;
}
