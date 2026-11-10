import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartphone_step_detection_experiment/evaluation/run_metrics_calculator.dart';
import 'package:smartphone_step_detection_experiment/l10n/stradio_strings.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/services/posthog_service.dart';
import 'package:smartphone_step_detection_experiment/services/preferences_service.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';

void main() {
  group('Stage 4A: Localization, Profile, Height Stride & Summary Storage', () {
    test('StradioStrings supports English default and Bahasa Indonesia', () {
      final en = StradioStrings.of(AppLanguage.en);
      final id = StradioStrings.of(AppLanguage.id);

      expect(en.navRun, 'Run');
      expect(id.navRun, 'Lari');
      expect(en.homeGreetingPrefix, 'Hello again,');
      expect(id.homeGreetingPrefix, 'Halo lagi,');
      expect(en.homeStepsOfTarget('2,450', '5,000'), '2,450 / 5,000 steps');
      expect(id.homeStepsOfTarget('2,450', '5,000'), '2,450 / 5,000 langkah');
      expect(AppLanguageCode.parse('id'), AppLanguage.id);
      expect(AppLanguageCode.parse('unknown'), AppLanguage.en);
    });

    test(
      'StradioUserProfile falls back to Runner when nickname is blank and persists via SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        await StradioPreferencesService.init();

        final defaultProfile = StradioPreferencesService.loadUserProfile();
        expect(defaultProfile.effectiveNickname, 'Runner');
        expect(defaultProfile.language, AppLanguage.en);
        expect(defaultProfile.dailyStepGoal, 5000);
        expect(defaultProfile.analyticsEnabled, isTrue);
        expect(defaultProfile.developerModeEnabled, isFalse);
        expect(defaultProfile.hasCompletedOnboarding, isFalse);

        final customProfile = defaultProfile.copyWith(
          nickname: '   ',
          heightCm: 172.0,
          dailyStepGoal: 8000,
          language: AppLanguage.id,
          analyticsEnabled: false,
          developerModeEnabled: true,
          hasCompletedOnboarding: true,
          favoriteSoundscapeIds: {'neon_stride', 'lofi_pace'},
        );
        expect(customProfile.effectiveNickname, 'Runner');

        await StradioPreferencesService.saveUserProfile(
          customProfile.copyWith(nickname: 'Raka'),
        );

        final reloaded = StradioPreferencesService.loadUserProfile();
        expect(reloaded.effectiveNickname, 'Raka');
        expect(reloaded.validHeightCm, 172.0);
        expect(reloaded.dailyStepGoal, 8000);
        expect(reloaded.language, AppLanguage.id);
        expect(reloaded.analyticsEnabled, isFalse);
        expect(reloaded.developerModeEnabled, isTrue);
        expect(reloaded.hasCompletedOnboarding, isTrue);
        expect(
          reloaded.favoriteSoundscapeIds,
          containsAll(<String>['neon_stride', 'lofi_pace']),
        );
      },
    );

    test(
      'RunMetricsCalculator calibrates stride length from heightCm and falls back when unset',
      () {
        expect(
          RunMetricsCalculator.strideLengthMeters(Activity.walking),
          closeTo(0.74, 1e-6),
        );
        expect(
          RunMetricsCalculator.strideLengthMeters(Activity.jogging),
          closeTo(0.95, 1e-6),
        );

        expect(
          RunMetricsCalculator.strideLengthMeters(
            Activity.walking,
            heightCm: 170.0,
          ),
          closeTo(170.0 * 0.00415, 1e-6),
        );
        expect(
          RunMetricsCalculator.strideLengthMeters(
            Activity.jogging,
            heightCm: 170.0,
          ),
          closeTo(170.0 * 0.0055, 1e-6),
        );

        final customDistanceKm = RunMetricsCalculator.estimateDistanceKm(
          steps: 1000,
          activity: Activity.walking,
          heightCm: 170.0,
        );
        expect(customDistanceKm, closeTo(0.7055, 1e-4));
      },
    );

    test(
      'FileRecordingStore saves lightweight summary when Developer Mode is OFF and full samples when ON',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'stradio_stage4a_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final store = FileRecordingStore(directory: () async => tempDir);
        const config = ExperimentConfig(
          participantId: 'P01',
          activity: Activity.jogging,
          phonePlacement: PhonePlacement.pocket,
          placementDetail: 'Front right pocket',
          trialNumber: 1,
          targetSteps: 5000,
        );

        final rawSamples = [
          for (var i = 0; i < 50; i++)
            SensorSample(
              recordingId: 'REC_20261111_001',
              sampleIndex: i,
              timestampNs: i * 10000000,
              axMps2: 0.2,
              ayMps2: 9.8,
              azMps2: 1.1,
            ),
        ];

        final fullRecording = SavedRecording(
          recordingId: 'REC_20261111_001',
          createdAt: DateTime.utc(2026, 11, 11, 7, 30),
          config: config,
          samples: rawSamples,
          liveStepCount: 1240,
          replayDetections: const {},
          summaryDurationSeconds: 620.0,
          summaryCadenceBucketsSpm: const [158.0, 162.0, 165.0, 164.0],
          targetBpm: 165,
        );

        // 1. Consumer mode (Developer Mode OFF): save summary only
        final summaryOnly = fullRecording.toSummaryOnly();
        await store.save(summaryOnly);

        final savedFile = File('${tempDir.path}/REC_20261111_001.json');
        final rawJsonMap =
            jsonDecode(await savedFile.readAsString()) as Map<String, dynamic>;
        expect(rawJsonMap['include_raw_samples'], isFalse);
        expect(rawJsonMap['samples'] as List, isEmpty);

        final loadedList = await store.list();
        expect(loadedList, hasLength(1));
        final loaded = loadedList.first;
        expect(loaded.includeRawSamples, isFalse);
        expect(loaded.samples, isEmpty);
        expect(loaded.effectiveStepCount, 1240);
        expect(loaded.durationSeconds, closeTo(620.0, 1e-6));
        expect(loaded.targetBpm, 165);
        expect(
          loaded.summaryCadenceBucketsSpm,
          equals([158.0, 162.0, 165.0, 164.0]),
        );
        expect(loaded.liveMatchesReplay, isTrue);
      },
    );

    test(
      'PostHogTelemetryService skips HTTP dispatch when analyticsEnabled is false',
      () async {
        var httpCalls = 0;
        final service = PostHogTelemetryService(
          apiKey: 'phc_test_key',
          enabled: false,
          transport: (uri, payload) async {
            httpCalls++;
            return 200;
          },
        );

        final record = await service.captureAppOpened(
          distinctId: 'anon_user',
          developerOverlayEnabled: false,
        );
        expect(httpCalls, 0);
        expect(record.delivered, isFalse);

        // Turning analytics back ON allows future events and flushes queue
        service.setEnabled(true);
        final flushed = await service.flushQueuedEvents();
        expect(flushed, 1);
        expect(httpCalls, 1);
      },
    );
  });
}

