import 'dart:convert';

enum Activity { walking, jogging }

enum PhonePlacement { handHeld, pocket }

extension ActivityLabel on Activity {
  String get value => this == Activity.walking ? 'walking' : 'jogging';
}

extension PhonePlacementLabel on PhonePlacement {
  String get value => this == PhonePlacement.handHeld ? 'hand-held' : 'pocket';
}

class ExperimentConfig {
  const ExperimentConfig({
    required this.participantId,
    required this.activity,
    required this.phonePlacement,
    required this.placementDetail,
    required this.trialNumber,
    required this.durationSeconds,
    this.notes = '',
    this.requestedSamplingRateHz = 100,
    this.parameters = const AlgorithmParameters(),
  });

  final String participantId;
  final Activity activity;
  final PhonePlacement phonePlacement;
  final String placementDetail;
  final int trialNumber;
  final int durationSeconds;
  final String notes;
  final double requestedSamplingRateHz;
  final AlgorithmParameters parameters;

  List<String> validate() => [
    if (!RegExp(r'^P[0-9]+$').hasMatch(participantId))
      'Participant ID must look like P01.',
    if (placementDetail.trim().isEmpty) 'Placement detail is required.',
    if (trialNumber < 1) 'Trial number must be positive.',
    if (durationSeconds < 1) 'Duration must be positive.',
    if (requestedSamplingRateHz <= 0)
      'Requested sampling rate must be positive.',
    if (parameters.smoothingSamples < 1) 'Smoothing window must be positive.',
    if (parameters.windowDurationMs < 1) 'Adaptive window must be positive.',
    if (parameters.minimumStepIntervalMs < 1)
      'Minimum step interval must be positive.',
    if (parameters.k < 0) 'k must not be negative.',
  ];
}

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

  double get magnitudeMps2 =>
      _sqrt(axMps2 * axMps2 + ayMps2 * ayMps2 + azMps2 * azMps2);
}

double _sqrt(double value) {
  if (value == 0) return 0;
  var x = value;
  for (var i = 0; i < 12; i++) {
    x = (x + value / x) / 2;
  }
  return x;
}

class DetectionEvent {
  const DetectionEvent({
    required this.detectionId,
    required this.peakTimestampNs,
    required this.outputTimestampNs,
    required this.thresholdMps2,
    required this.sampleIndex,
    required this.processingDurationMicros,
  });

  final int detectionId;
  final int peakTimestampNs;
  final int outputTimestampNs;
  final double thresholdMps2;
  final int sampleIndex;
  final int processingDurationMicros;
}

class GroundTruthEvent {
  const GroundTruthEvent({
    required this.id,
    required this.timestampNs,
    this.notes = '',
  });

  final int id;
  final int timestampNs;
  final String notes;
}

class EvaluationResult {
  const EvaluationResult({
    required this.recordingId,
    required this.algorithm,
    required this.groundTruthCount,
    required this.predictedCount,
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.matchingToleranceMs,
    required this.latenciesMs,
  });

  final String recordingId;
  final String algorithm;
  final int groundTruthCount;
  final int predictedCount;
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final int matchingToleranceMs;
  final List<double> latenciesMs;

  double? get precision => truePositives + falsePositives == 0
      ? null
      : truePositives / (truePositives + falsePositives);
  double? get recall => truePositives + falseNegatives == 0
      ? null
      : truePositives / (truePositives + falseNegatives);
  double? get f1 =>
      precision == null || recall == null || precision! + recall! == 0
      ? null
      : 2 * precision! * recall! / (precision! + recall!);
  int get signedCountError => predictedCount - groundTruthCount;
  int get absoluteCountError => signedCountError.abs();
  double? get percentageCountError => groundTruthCount == 0
      ? null
      : absoluteCountError / groundTruthCount * 100;
  double? get meanLatencyMs => latenciesMs.isEmpty
      ? null
      : latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
  double? get medianLatencyMs => _percentile(latenciesMs, 50);
  double? get p95LatencyMs => _percentile(latenciesMs, 95);
}

double? _percentile(List<double> values, int percentile) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final index = ((percentile / 100) * (sorted.length - 1)).round();
  return sorted[index];
}

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

  String get json => jsonEncode({
    'smoothing_samples': smoothingSamples,
    'window_duration_ms': windowDurationMs,
    'minimum_step_interval_ms': minimumStepIntervalMs,
    'k': k,
  });

  Map<String, Object> toMap() => {
    'smoothing_samples': smoothingSamples,
    'window_duration_ms': windowDurationMs,
    'minimum_step_interval_ms': minimumStepIntervalMs,
    'k': k,
  };
}

class SavedRecording {
  const SavedRecording({
    required this.recordingId,
    required this.participantId,
    required this.activity,
    required this.phonePlacement,
    required this.placementDetail,
    required this.trialNumber,
    required this.durationSeconds,
    required this.samples,
    required this.detections,
  });

  final String recordingId;
  final String participantId;
  final String activity;
  final String phonePlacement;
  final String placementDetail;
  final int trialNumber;
  final int durationSeconds;
  final List<SensorSample> samples;
  final Map<String, List<DetectionEvent>> detections;
}
