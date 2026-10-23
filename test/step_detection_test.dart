import 'package:flutter_test/flutter_test.dart';
import 'package:smartphone_step_detection_experiment/algorithms/step_detector.dart';
import 'package:smartphone_step_detection_experiment/evaluation/event_matcher.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/services/csv_export.dart';
import 'package:smartphone_step_detection_experiment/services/ground_truth_csv.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';

void main() {
  test('calculates acceleration magnitude', () {
    final sample = SensorSample(
      recordingId: 'r1',
      sampleIndex: 0,
      timestampNs: 0,
      axMps2: 3,
      ayMps2: 4,
      azMps2: 12,
    );
    expect(sample.magnitudeMps2, closeTo(13, 0.0001));
  });

  test('validates experiment configuration', () {
    const config = ExperimentConfig(
      participantId: 'P01',
      activity: Activity.walking,
      phonePlacement: PhonePlacement.pocket,
      placementDetail: 'front-right',
      trialNumber: 1,
      durationSeconds: 60,
    );
    expect(config.validate(), isEmpty);
  });

  test('rejects invalid requested rate and detector settings', () {
    const config = ExperimentConfig(
      participantId: 'P01',
      activity: Activity.walking,
      phonePlacement: PhonePlacement.pocket,
      placementDetail: 'front-right',
      trialNumber: 1,
      durationSeconds: 60,
      requestedSamplingRateHz: 0,
      parameters: AlgorithmParameters(smoothingSamples: 0, k: -1),
    );
    expect(
      config.validate(),
      contains('Requested sampling rate must be positive.'),
    );
    expect(config.validate(), contains('Smoothing window must be positive.'));
    expect(config.validate(), contains('k must not be negative.'));
  });

  test('detector emits no event during warm-up', () {
    final samples = [
      for (var i = 0; i < 3; i++)
        SensorSample(
          recordingId: 'r1',
          sampleIndex: i,
          timestampNs: i * 100000000,
          axMps2: 0,
          ayMps2: 0,
          azMps2: 9.8,
        ),
    ];
    expect(
      StepDetector(algorithm: ThresholdAlgorithm.adaptiveMidpoint)
          .process(samples),
      isEmpty,
    );
  });

  test('escapes CSV cells', () {
    expect(csvCell('a,b'), '"a,b"');
    expect(csvCell('a"b'), '"a""b"');
  });

  test('matches each prediction and ground-truth event at most once', () {
    final detections = [
      const DetectionEvent(
        detectionId: 0,
        peakTimestampNs: 1000000000,
        outputTimestampNs: 1030000000,
        thresholdMps2: 10,
        sampleIndex: 1,
        processingDurationMicros: 10,
      ),
      const DetectionEvent(
        detectionId: 1,
        peakTimestampNs: 1100000000,
        outputTimestampNs: 1130000000,
        thresholdMps2: 10,
        sampleIndex: 2,
        processingDurationMicros: 10,
      ),
    ];
    final result = evaluateDetections(
      recordingId: 'r1',
      algorithm: 'midpoint',
      detections: detections,
      groundTruth: const [GroundTruthEvent(id: 0, timestampNs: 1020000000)],
      matchingToleranceMs: 150,
    );
    expect(result.truePositives, 1);
    expect(result.falsePositives, 1);
    expect(result.falseNegatives, 0);
    expect(result.meanLatencyMs, 10);
  });

  test('returns null metrics where denominators are undefined', () {
    const result = EvaluationResult(
      recordingId: 'r1',
      algorithm: 'midpoint',
      groundTruthCount: 0,
      predictedCount: 0,
      truePositives: 0,
      falsePositives: 0,
      falseNegatives: 0,
      matchingToleranceMs: 100,
      latenciesMs: [],
    );
    expect(result.precision, isNull);
    expect(result.recall, isNull);
    expect(result.f1, isNull);
    expect(result.percentageCountError, isNull);
  });

  test('parses valid ground-truth CSV and preserves quoted notes', () {
    final imported = parseGroundTruthCsv('''
recording_id,ground_truth_step_id,ground_truth_timestamp_ns,annotation_notes
r1,1,1000000000,"heel strike, clear"
''');
    expect(imported.errors, isEmpty);
    expect(imported.events['r1'], hasLength(1));
    expect(imported.events['r1']!.single.notes, 'heel strike, clear');
  });

  test('rejects ground-truth CSV with missing required columns', () {
    final imported = parseGroundTruthCsv(
      'recording_id,ground_truth_step_id\nr1,1',
    );
    expect(imported.isValid, isFalse);
    expect(imported.errors.single, contains('ground_truth_timestamp_ns'));
  });

  test('loads persisted recordings with samples and detector results', () {
    final recording = RecordingRepository().fromJson('''
{
  "recording_id":"r1",
  "participant_id":"P01",
  "activity":"walking",
  "phone_placement":"pocket",
  "placement_detail":"front-right",
  "trial_number":1,
  "duration_seconds":60,
  "samples":[{"sample_index":0,"timestamp_ns":1,"ax_mps2":1.0,"ay_mps2":2.0,"az_mps2":3.0}],
  "algorithm_results":{"adaptive_midpoint":[{"detection_id":0,"peak_timestamp_ns":1,"output_timestamp_ns":2,"threshold_mps2":9.0,"sample_index":0,"processing_duration_micros":5}]}
}
''');
    expect(recording.recordingId, 'r1');
    expect(recording.samples.single.magnitudeMps2, closeTo(3.741657, 0.00001));
    expect(recording.detections['adaptive_midpoint'], hasLength(1));
  });
}
