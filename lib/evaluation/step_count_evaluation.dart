import '../models/experiment_models.dart';

/// Scoreboard classification status (PLANNING.md §3 Fase 3).
enum DetectionStatus { accurate, undercounting, overcounting }

extension DetectionStatusLabel on DetectionStatus {
  String get label => switch (this) {
    DetectionStatus.accurate => 'Akurat',
    DetectionStatus.undercounting => 'Undercounting',
    DetectionStatus.overcounting => 'Overcounting',
  };
}

/// Step-count result for one recording and one algorithm/variant, compared with
/// the fixed ground truth (AGENTS.md §10 & PLANNING.md §3).
class StepCountResult {
  const StepCountResult({
    required this.recordingId,
    required this.trialNumber,
    required this.activity,
    required this.phonePlacement,
    required this.algorithm,
    required this.groundTruthSteps,
    required this.predictedSteps,
    this.variant,
  });

  final String recordingId;
  final int trialNumber;
  final Activity activity;
  final PhonePlacement phonePlacement;
  final ThresholdAlgorithm algorithm;

  /// Optional 4-pathway variant (A1, A2, B1, B2).
  final AlgorithmVariant? variant;

  /// N_true, 100 by protocol.
  final int groundTruthSteps;

  /// N_predicted, the steps counted by the algorithm.
  final int predictedSteps;

  /// Exported algorithm identifier (`adaptive_midpoint`, `mean_std`,
  /// `adaptive_midpoint_linear`, `mean_sd_linear`).
  String get algorithmValue => variant?.value ?? algorithm.value;

  /// Matrix code (`A1`, `A2`, `B1`, `B2`).
  String get variantCode =>
      variant?.code ??
      (algorithm == ThresholdAlgorithm.adaptiveMidpoint ? 'A1' : 'B1');

  /// Display name for Scoreboard.
  String get variantDisplayName => variant?.displayName ?? algorithm.displayName;

  String get condition => conditionId(activity, phonePlacement, algorithm);

  /// |N_predicted − N_true|
  int get absoluteErrorSteps => (predictedSteps - groundTruthSteps).abs();

  /// Signed error (positive = overcount, negative = undercount).
  int get signedErrorSteps => predictedSteps - groundTruthSteps;

  /// |N_predicted − N_true| / N_true × 100 %. With N_true = 100 this equals
  /// the absolute error in steps.
  double get marginOfErrorPercent =>
      groundTruthSteps > 0 ? absoluteErrorSteps / groundTruthSteps * 100 : 0.0;

  /// max(0, 100 % − margin of error)
  double get accuracyPercent {
    final accuracy = 100 - marginOfErrorPercent;
    return accuracy < 0 ? 0 : accuracy;
  }

  /// Scoreboard status classification (within ±2% is Akurat).
  DetectionStatus get status {
    if (marginOfErrorPercent <= 2.0) return DetectionStatus.accurate;
    return signedErrorSteps > 0
        ? DetectionStatus.overcounting
        : DetectionStatus.undercounting;
  }
}

/// Evaluates the primary 2 algorithms' replay results for a saved recording.
List<StepCountResult> evaluateRecording(SavedRecording recording) => [
  for (final algorithm in ThresholdAlgorithm.values)
    StepCountResult(
      recordingId: recording.recordingId,
      trialNumber: recording.config.trialNumber,
      activity: recording.config.activity,
      phonePlacement: recording.config.phonePlacement,
      algorithm: algorithm,
      groundTruthSteps: recording.config.targetSteps,
      predictedSteps: recording.replayCount(algorithm),
    ),
];

/// Evaluates all 4 algorithm combinations (A1, A2, B1, B2) for the Scoreboard
/// and full CSV export (PLANNING.md §2 & §3).
List<StepCountResult> evaluateRecordingAllFour(SavedRecording recording) => [
  for (final variant in AlgorithmVariant.values)
    StepCountResult(
      recordingId: recording.recordingId,
      trialNumber: recording.config.trialNumber,
      activity: recording.config.activity,
      phonePlacement: recording.config.phonePlacement,
      algorithm: variant.thresholdAlgorithm,
      variant: variant,
      groundTruthSteps: recording.config.targetSteps,
      predictedSteps: recording.replayVariantCount(variant),
    ),
];

/// Summary of one E1–E8 condition across its trials.
class ConditionSummary {
  const ConditionSummary(this.condition, this.results);

  final String condition;
  final List<StepCountResult> results;

  int get trials => results.length;

  double? get meanMarginOfErrorPercent => results.isEmpty
      ? null
      : results.map((r) => r.marginOfErrorPercent).reduce((a, b) => a + b) /
            results.length;
}

/// Groups results into E1–E8 (an empty summary for conditions not run yet).
List<ConditionSummary> summarizeConditions(List<StepCountResult> results) {
  final summaries = <ConditionSummary>[];
  for (final placement in PhonePlacement.values) {
    for (final activity in Activity.values) {
      for (final algorithm in ThresholdAlgorithm.values) {
        final id = conditionId(activity, placement, algorithm);
        summaries.add(
          ConditionSummary(id, [
            for (final r in results)
              if (r.condition == id) r,
          ]),
        );
      }
    }
  }
  summaries.sort((a, b) => a.condition.compareTo(b.condition));
  return summaries;
}
