import '../models/experiment_models.dart';

/// Greedily matches each prediction to the nearest unmatched ground-truth
/// event within tolerance. Inputs are sorted to make ties deterministic.
EvaluationResult evaluateDetections({
  required String recordingId,
  required String algorithm,
  required List<DetectionEvent> detections,
  required List<GroundTruthEvent> groundTruth,
  required int matchingToleranceMs,
}) {
  final predictions = [...detections]
    ..sort((a, b) => a.peakTimestampNs.compareTo(b.peakTimestampNs));
  final references = [...groundTruth]
    ..sort((a, b) => a.timestampNs.compareTo(b.timestampNs));
  final usedReferenceIds = <int>{};
  final latencies = <double>[];
  var matches = 0;
  final toleranceNs = matchingToleranceMs * 1000000;

  for (final prediction in predictions) {
    GroundTruthEvent? nearest;
    var nearestDistance = toleranceNs + 1;
    for (final reference in references) {
      if (usedReferenceIds.contains(reference.id)) continue;
      final distance = (prediction.peakTimestampNs - reference.timestampNs)
          .abs();
      if (distance <= toleranceNs && distance < nearestDistance) {
        nearest = reference;
        nearestDistance = distance;
      }
    }
    if (nearest != null) {
      usedReferenceIds.add(nearest.id);
      matches++;
      latencies.add(
        (prediction.outputTimestampNs - nearest.timestampNs) / 1000000,
      );
    }
  }

  return EvaluationResult(
    recordingId: recordingId,
    algorithm: algorithm,
    groundTruthCount: references.length,
    predictedCount: predictions.length,
    truePositives: matches,
    falsePositives: predictions.length - matches,
    falseNegatives: references.length - matches,
    matchingToleranceMs: matchingToleranceMs,
    latenciesMs: latencies,
  );
}
