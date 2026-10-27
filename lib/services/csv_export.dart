import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';

const sensorDataHeader =
    'recording_id,sample_index,timestamp_ns,activity,phone_placement,'
    'ax_mps2,ay_mps2,az_mps2,magnitude_mps2';

const evaluationSummaryHeader =
    'recording_id,trial_number,activity,phone_placement,algorithm,'
    'ground_truth_steps,predicted_steps,absolute_error_steps,'
    'percentage_margin_of_error';

String csvCell(Object? value) {
  final text = '${value ?? ''}';
  return text.contains(',') || text.contains('"') || text.contains('\n')
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

/// `sensor_data.csv`: raw samples for every recording (AGENTS.md §11.1).
String sensorDataCsv(Iterable<SavedRecording> recordings) {
  final buffer = StringBuffer('$sensorDataHeader\n');
  for (final recording in recordings) {
    final activity = recording.config.activity.value;
    final placement = recording.config.phonePlacement.value;
    for (final sample in recording.samples) {
      buffer.writeln(
        [
          recording.recordingId,
          sample.sampleIndex,
          sample.timestampNs,
          activity,
          placement,
          sample.axMps2,
          sample.ayMps2,
          sample.azMps2,
          sample.magnitudeMps2.toStringAsFixed(3),
        ].map(csvCell).join(','),
      );
    }
  }
  return buffer.toString();
}

/// `evaluation_summary.csv`: one row per recording × algorithm
/// (AGENTS.md §11.2).
String evaluationSummaryCsv(Iterable<StepCountResult> results) {
  final buffer = StringBuffer('$evaluationSummaryHeader\n');
  for (final r in results) {
    buffer.writeln(
      [
        r.recordingId,
        r.trialNumber,
        r.activity.value,
        r.phonePlacement.value,
        r.algorithm.value,
        r.groundTruthSteps,
        r.predictedSteps,
        r.absoluteErrorSteps,
        r.marginOfErrorPercent.toStringAsFixed(2),
      ].map(csvCell).join(','),
    );
  }
  return buffer.toString();
}
