import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:smartphone_step_detection_experiment/algorithms/step_detector.dart';
import 'package:smartphone_step_detection_experiment/evaluation/step_count_evaluation.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/services/csv_export.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';

void main() {
  group('Sensor Models & Magnitude', () {
    test('calculates 3D Euclidean magnitude norm', () {
      const sample = SensorSample(
        recordingId: 'REC_20261027_001',
        sampleIndex: 0,
        timestampNs: 0,
        axMps2: 2.0,
        ayMps2: 3.0,
        azMps2: 6.0,
      );
      // sqrt(4 + 9 + 36) = sqrt(49) = 7.0
      expect(sample.magnitudeMps2, closeTo(7.0, 1e-6));
    });

    test('validates experiment configuration', () {
      const valid = ExperimentConfig(
        participantId: 'P01',
        activity: Activity.walking,
        phonePlacement: PhonePlacement.hand,
        placementDetail: 'right hand',
        trialNumber: 1,
        targetSteps: 100,
      );
      expect(valid.validate(), isEmpty);

      const invalid = ExperimentConfig(
        participantId: 'bad_id',
        activity: Activity.walking,
        phonePlacement: PhonePlacement.hand,
        placementDetail: '',
        trialNumber: 0,
        targetSteps: 0,
        parameters: AlgorithmParameters(k: -1),
      );
      final errors = invalid.validate();
      expect(errors, contains('Participant ID must look like P01.'));
      expect(errors, contains('Placement detail is required.'));
      expect(errors, contains('Trial number must be positive.'));
      expect(errors, contains('Target steps must be positive.'));
      expect(errors, contains('k must not be negative.'));
    });
  });

  group('Rolling Window Statistics', () {
    test('computes adaptive midpoint threshold', () {
      final window = [10.0, 12.0, 16.0, 8.0, 14.0];
      // min = 8.0, max = 16.0 -> (8 + 16) / 2 = 12.0
      expect(midpointThreshold(window), closeTo(12.0, 1e-6));
    });

    test('computes adaptive mean plus standard deviation threshold', () {
      // Data: 2, 4, 4, 4, 5, 5, 7, 9
      // Mean = 40 / 8 = 5.0
      // Variance = (9 + 1 + 1 + 1 + 0 + 0 + 4 + 16) / 8 = 32 / 8 = 4.0
      // SD = 2.0
      // For k = 1.5, T = 5.0 + 1.5 * 2.0 = 8.0
      final window = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      expect(meanStdThreshold(window, 1.5), closeTo(8.0, 1e-6));
    });
  });

  group('Peak Detection State Machine & Lockout', () {
    test('enforces minimum step interval lockout (refractory period)', () {
      final detector = StepDetector(
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        parameters: const AlgorithmParameters(
          smoothingSamples: 1,
          windowDurationMs: 1000,
          minimumStepIntervalMs: 250, // 250 ms lockout
        ),
      );

      // Create a peak at t = 100 ms
      // and another candidate peak at t = 200 ms (only 100 ms later -> within refractory lockout)
      final samples = [
        // baseline
        _sample(0, 0, 9.8),
        _sample(1, 50, 10.0),
        _sample(2, 100, 15.0), // peak 1
        _sample(3, 150, 9.0),  // valley confirms peak 1
        _sample(4, 200, 14.0), // candidate peak within 250ms of peak 1
        _sample(5, 230, 9.0),
        // peak at t = 400 ms (> 250 ms after peak 1)
        _sample(6, 400, 14.0), // peak 2
        _sample(7, 450, 9.0),
      ];

      final detections = <DetectionEvent>[];
      for (final s in samples) {
        final out = detector.addSample(s);
        if (out.step != null) detections.add(out.step!);
      }

      // Candidate at 200ms must be rejected by refractory period.
      expect(detections.length, 2);
      expect(detections[0].peakTimestampNs, 100 * 1000000);
      expect(detections[1].peakTimestampNs, 400 * 1000000);
    });

    test('valley confirmation prevents double-triggering without signal dip', () {
      final detector = StepDetector(
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        parameters: const AlgorithmParameters(
          smoothingSamples: 1,
          windowDurationMs: 2000,
          minimumStepIntervalMs: 100,
        ),
      );

      // Two peaks high above threshold without the signal dipping below threshold in-between
      final samples = [
        _sample(0, 0, 9.0),
        _sample(1, 100, 15.0), // Peak 1
        _sample(2, 200, 13.0), // Stays well above threshold (~11.0), not a true valley
        _sample(3, 400, 16.0), // Second peak candidate, but detector not re-armed
        _sample(4, 500, 12.0),
        _sample(5, 600, 8.0),  // Dips below threshold -> now re-arms
        _sample(6, 800, 15.0), // Peak 2 accepted
        _sample(7, 900, 8.0),
      ];

      final detections = <DetectionEvent>[];
      for (final s in samples) {
        final out = detector.addSample(s);
        if (out.step != null) detections.add(out.step!);
      }

      expect(detections.length, 2);
      expect(detections[0].peakTimestampNs, 100 * 1000000);
      expect(detections[1].peakTimestampNs, 800 * 1000000);
    });
  });

  group('Ground Truth & Error Metrics (§10)', () {
    test('computes error and accuracy out of 100 steps', () {
      const result = StepCountResult(
        recordingId: 'REC_20261027_001',
        trialNumber: 1,
        activity: Activity.walking,
        phonePlacement: PhonePlacement.hand,
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        groundTruthSteps: 100,
        predictedSteps: 98,
      );

      expect(result.absoluteErrorSteps, 2);
      expect(result.signedErrorSteps, -2);
      expect(result.marginOfErrorPercent, closeTo(2.0, 1e-4));
      expect(result.accuracyPercent, closeTo(98.0, 1e-4));
      expect(result.condition, 'E1');
    });

    test('clamps accuracy to zero if error exceeds 100%', () {
      const result = StepCountResult(
        recordingId: 'REC_20261027_001',
        trialNumber: 1,
        activity: Activity.jogging,
        phonePlacement: PhonePlacement.pocket,
        algorithm: ThresholdAlgorithm.meanStd,
        groundTruthSteps: 100,
        predictedSteps: 220, // 120 steps error -> 120% margin of error
      );

      expect(result.absoluteErrorSteps, 120);
      expect(result.marginOfErrorPercent, closeTo(120.0, 1e-4));
      expect(result.accuracyPercent, 0.0);
      expect(result.condition, 'E8');
    });
  });

  group('CSV Export Exact Schemas (§11)', () {
    test('sensor_data.csv matches exact 9-column schema', () {
      const config = ExperimentConfig(
        participantId: 'P01',
        activity: Activity.walking,
        phonePlacement: PhonePlacement.hand,
        placementDetail: 'right hand',
        trialNumber: 1,
      );
      final recording = SavedRecording(
        recordingId: 'REC_20261027_001',
        createdAt: DateTime(2026, 10, 27),
        config: config,
        samples: [
          const SensorSample(
            recordingId: 'REC_20261027_001',
            sampleIndex: 0,
            timestampNs: 1000000,
            axMps2: 0.12,
            ayMps2: 9.81,
            azMps2: 1.45,
          ),
        ],
        liveStepCount: 0,
        replayDetections: const {},
      );

      final csv = sensorDataCsv([recording]);
      final lines = csv.trim().split('\n');

      expect(
        lines[0],
        'recording_id,sample_index,timestamp_ns,activity,phone_placement,'
        'ax_mps2,ay_mps2,az_mps2,magnitude_mps2',
      );
      expect(
        lines[1],
        'REC_20261027_001,0,1000000,walking,hand,0.12,9.81,1.45,9.917',
      );
    });

    test('evaluation_summary.csv matches exact 9-column schema', () {
      const result = StepCountResult(
        recordingId: 'REC_20261027_001',
        trialNumber: 1,
        activity: Activity.walking,
        phonePlacement: PhonePlacement.hand,
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        groundTruthSteps: 100,
        predictedSteps: 98,
      );

      final csv = evaluationSummaryCsv([result]);
      final lines = csv.trim().split('\n');

      expect(
        lines[0],
        'recording_id,trial_number,activity,phone_placement,algorithm,'
        'ground_truth_steps,predicted_steps,absolute_error_steps,'
        'percentage_margin_of_error',
      );
      expect(
        lines[1],
        'REC_20261027_001,1,walking,hand,adaptive_midpoint,100,98,2,2.00',
      );
    });
  });

  group('Synthetic 100-Peak Signal Fixture (§14)', () {
    test('deterministically detects exactly 100 steps in live and offline replay', () {
      // Generate a synthetic accelerometer signal containing exactly 100 steps.
      // Cadence: 2 steps per second (period = 500 ms per step).
      // Sampling rate: 100 Hz (sample every 10 ms).
      // Total samples = 100 steps * 50 samples/step = 5000 samples (+ buffer).
      const stepPeriodMs = 500;
      const totalSteps = 100;
      final samples = <SensorSample>[];

      var sampleIdx = 0;
      for (var s = 0; s < totalSteps; s++) {
        for (var i = 0; i < 50; i++) {
          final tMs = s * stepPeriodMs + i * 10;
          final tNs = tMs * 1000000;
          // One clear acceleration pulse per step (e.g. heel strike impact)
          // Raised-cosine pulse: 0 at i=0, max=1.0 at i=25, 0 at i=50
          final phase = (i / 50.0) * 2 * math.pi;
          final pulse = (1.0 - math.cos(phase)) / 2.0;
          final az = 9.8 + 4.0 * pulse; // baseline = 9.8, peak = 13.8 m/s^2

          samples.add(
            SensorSample(
              recordingId: 'SYNTH_100',
              sampleIndex: sampleIdx++,
              timestampNs: tNs,
              axMps2: 0.0,
              ayMps2: 0.0,
              azMps2: az,
            ),
          );
        }
      }

      // Add a brief resting tail
      for (var i = 0; i < 20; i++) {
        final tMs = totalSteps * stepPeriodMs + i * 10;
        samples.add(
          SensorSample(
            recordingId: 'SYNTH_100',
            sampleIndex: sampleIdx++,
            timestampNs: tMs * 1000000,
            axMps2: 0.0,
            ayMps2: 0.0,
            azMps2: 9.8,
          ),
        );
      }

      const params = AlgorithmParameters(
        smoothingSamples: 3,
        windowDurationMs: 1000,
        minimumStepIntervalMs: 250,
        k: 1.0,
      );

      // 1. Live streaming detection
      final liveDetector = StepDetector(
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        parameters: params,
      );
      final liveDetections = <DetectionEvent>[];
      for (final sample in samples) {
        final out = liveDetector.addSample(sample);
        if (out.step != null) liveDetections.add(out.step!);
      }

      // 2. Offline replay detection
      final replayMidpoint = StepDetector.replay(
        samples,
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        parameters: params,
      );
      final replayMeanStd = StepDetector.replay(
        samples,
        algorithm: ThresholdAlgorithm.meanStd,
        parameters: params,
      );

      // Verify exact count of 100 steps
      expect(
        liveDetections.length,
        totalSteps,
        reason: 'Live detector must count exactly 100 steps',
      );
      expect(
        replayMidpoint.length,
        totalSteps,
        reason: 'Offline replay midpoint must count exactly 100 steps',
      );
      expect(
        replayMeanStd.length,
        totalSteps,
        reason: 'Offline replay mean+std must count exactly 100 steps',
      );

      // Verify integrity: live outputs match offline replay exactly
      for (var i = 0; i < totalSteps; i++) {
        expect(
          liveDetections[i].peakTimestampNs,
          replayMidpoint[i].peakTimestampNs,
        );
      }
    });
  });

  group('Recording Store & ID Generation', () {
    test('generates sequential REC_YYYYMMDD_NNN format IDs', () {
      final date = DateTime(2026, 10, 27);
      expect(nextRecordingId([], date), 'REC_20261027_001');

      final existing = [
        'REC_20261027_001',
        'REC_20261027_002',
        'REC_20261026_099', // from previous day
      ];
      expect(nextRecordingId(existing, date), 'REC_20261027_003');
    });
  });
}

SensorSample _sample(int index, int ms, double magnitude) {
  return SensorSample(
    recordingId: 'test',
    sampleIndex: index,
    timestampNs: ms * 1000000,
    axMps2: 0,
    ayMps2: 0,
    azMps2: magnitude,
  );
}
