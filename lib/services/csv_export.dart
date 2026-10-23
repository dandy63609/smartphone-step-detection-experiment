import '../models/experiment_models.dart';

String csvCell(Object? value) {
  final text = '${value ?? ''}';
  return text.contains(',') || text.contains('"') || text.contains('\n')
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

String sensorCsv(Iterable<SensorSample> samples) {
  final rows = <String>[
    'recording_id,sample_index,timestamp_ns,ax_mps2,ay_mps2,az_mps2,magnitude_mps2',
  ];
  for (final sample in samples) {
    rows.add(
      [
        sample.recordingId,
        sample.sampleIndex,
        sample.timestampNs,
        sample.axMps2,
        sample.ayMps2,
        sample.azMps2,
        sample.magnitudeMps2,
      ].map(csvCell).join(','),
    );
  }
  return '${rows.join('\n')}\n';
}

String detectedStepsCsv({
  required String recordingId,
  required String algorithm,
  required Iterable<DetectionEvent> detections,
  required AlgorithmParameters parameters,
}) {
  final rows = <String>[
    'recording_id,algorithm,detection_id,peak_timestamp_ns,output_timestamp_ns,threshold_at_detection_mps2,processing_duration_ms,sample_index,algorithm_parameters',
  ];
  for (final detection in detections) {
    rows.add(
      [
        recordingId,
        algorithm,
        detection.detectionId,
        detection.peakTimestampNs,
        detection.outputTimestampNs,
        detection.thresholdMps2,
        detection.processingDurationMicros / 1000,
        detection.sampleIndex,
        parameters.json,
      ].map(csvCell).join(','),
    );
  }
  return '${rows.join('\n')}\n';
}

String evaluationCsv(Iterable<EvaluationResult> results) {
  final rows = <String>[
    'recording_id,algorithm,ground_truth_count,predicted_count,tp,fp,fn,precision,recall,f1_score,absolute_count_error,signed_count_error,percentage_count_error,median_detection_latency_ms,mean_detection_latency_ms,p95_detection_latency_ms,matching_tolerance_ms',
  ];
  for (final result in results) {
    rows.add(
      [
        result.recordingId,
        result.algorithm,
        result.groundTruthCount,
        result.predictedCount,
        result.truePositives,
        result.falsePositives,
        result.falseNegatives,
        result.precision,
        result.recall,
        result.f1,
        result.absoluteCountError,
        result.signedCountError,
        result.percentageCountError,
        result.medianLatencyMs,
        result.meanLatencyMs,
        result.p95LatencyMs,
        result.matchingToleranceMs,
      ].map(csvCell).join(','),
    );
  }
  return '${rows.join('\n')}\n';
}
