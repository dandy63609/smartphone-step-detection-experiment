import 'package:flutter_test/flutter_test.dart';
import 'package:smartphone_step_detection_experiment/evaluation/run_metrics_calculator.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/services/posthog_service.dart';

void main() {
  group('PostHogTelemetryService', () {
    test('queues events locally when API key is empty and flushes on configure', () async {
      final sentPayloads = <Map<String, Object?>>[];
      final service = PostHogTelemetryService(
        apiKey: '',
        host: 'https://us.i.posthog.com',
        transport: (uri, payload) async {
          expect(uri.toString(), 'https://us.i.posthog.com/capture/');
          sentPayloads.add(payload);
          return 200;
        },
      );

      expect(service.isConfigured, isFalse);
      await service.captureAppOpened(
        distinctId: 'P01',
        developerOverlayEnabled: false,
      );
      expect(service.queuedCount, 1);
      expect(service.deliveredCount, 0);
      expect(sentPayloads, isEmpty);

      // Configure key at runtime -> automatically flushes queued events
      await service.configure(apiKey: 'phc_test_key_123');
      expect(service.isConfigured, isTrue);
      expect(service.queuedCount, 0);
      expect(service.deliveredCount, 1);
      expect(sentPayloads.length, 1);
      expect(sentPayloads.first['api_key'], 'phc_test_key_123');
      expect(sentPayloads.first['event'], 'stradio_app_opened');
    });

    test('dispatches run_completed and 4 algorithm_benchmark_evaluated events', () async {
      final sentPayloads = <Map<String, Object?>>[];
      final service = PostHogTelemetryService(
        apiKey: 'phc_live_key',
        transport: (uri, payload) async {
          sentPayloads.add(payload);
          return 200;
        },
      );

      const config = ExperimentConfig(
        participantId: 'P02',
        activity: Activity.jogging,
        phonePlacement: PhonePlacement.pocket,
        placementDetail: 'Front-right pocket',
        trialNumber: 3,
        targetSteps: 100,
      );

      final fakeEvents = [
        for (var i = 0; i < 98; i++)
          DetectionEvent(
            detectionId: i,
            sampleIndex: i * 30,
            peakTimestampNs: i * 350000000,
            outputTimestampNs: i * 350000000 + 10000000,
            thresholdMps2: 11.2,
          ),
      ];

      final recording = SavedRecording(
        recordingId: 'REC_20261106_001',
        createdAt: DateTime.utc(2026, 11, 6),
        config: config,
        samples: const [],
        liveStepCount: 98,
        replayDetections: {
          ThresholdAlgorithm.adaptiveMidpoint: fakeEvents,
          ThresholdAlgorithm.meanStd: fakeEvents,
        },
        replayVariantDetections: {
          AlgorithmVariant.a1MidpointRaw: fakeEvents,
          AlgorithmVariant.a2MidpointLinear: fakeEvents,
          AlgorithmVariant.b1MeanSdRaw: fakeEvents,
          AlgorithmVariant.b2MeanSdLinear: fakeEvents,
        },
      );

      const metrics = RunSummaryMetrics(
        totalSteps: 98,
        activeDurationSeconds: 36.0,
        liveCadenceSpm: 163.3,
        averageCadenceSpm: 163.3,
        distanceKm: 0.093,
        speedKmh: 9.3,
        targetBpm: 165,
        rhythmScorePercent: 99.0,
        cadenceBucketsSpm: [162, 164, 163, 164],
      );

      const health = SensorHealthReport(
        sampleCount: 3600,
        requestedRateHz: 100,
        effectiveRateHz: 100,
        sampleDrops: 0,
        latestTimestampNs: 36000000000,
      );

      final records = await service.captureWorkoutAndBenchmarks(
        recording: recording,
        metrics: metrics,
        health: health,
      );

      // 1 run_completed + 4 algorithm_benchmark_evaluated (A1, A2, B1, B2)
      expect(records.length, 5);
      expect(sentPayloads.length, 5);
      expect(sentPayloads.first['event'], 'run_completed');

      final benchmarkVariants = sentPayloads
          .skip(1)
          .map((p) => (p['properties'] as Map<String, Object?>)['variant_code'])
          .toList();
      expect(benchmarkVariants, ['A1', 'A2', 'B1', 'B2']);
    });
  });
}

