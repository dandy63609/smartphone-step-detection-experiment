import '../models/experiment_models.dart';

/// Step-count result for one recording and one algorithm, compared with the
/// fixed ground truth (AGENTS.md §10).
class StepCountResult {
  const StepCountResult({
    required this.recordingId,
    required this.trialNumber,
    required this.activity,
    required this.phonePlacement,
    required this.algorithm,
    required this.groundTruthSteps,
    required this.predictedSteps,
  });

  final String recordingId;
  final int trialNumber;
  final Activity activity;
  final PhonePlacement phonePlacement;
  final ThresholdAlgorithm algorithm;

  /// N_true, 100 by protocol.
  final int groundTruthSteps;

  /// N_predicted, the steps counted by the algorithm.
  final int predictedSteps;

  String get condition => conditionId(activity, phonePlacement, algorithm);

  /// |N_predicted − N_true|
  int get absoluteErrorSteps => (predictedSteps - groundTruthSteps).abs();

  /// Signed error (positive = overcount, negative = undercount).
  int get signedErrorSteps => predictedSteps - groundTruthSteps;

  /// |N_predicted − N_true| / N_true × 100 %. With N_true = 100 this equals
  /// the absolute error in steps.
  double get marginOfErrorPercent =>
      absoluteErrorSteps / groundTruthSteps * 100;

  /// max(0, 100 % − margin of error)
  double get accuracyPercent {
    final accuracy = 100 - marginOfErrorPercent;
    return accuracy < 0 ? 0 : accuracy;
  }
}

/// Evaluates both algorithms' replay results for a saved recording.
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
