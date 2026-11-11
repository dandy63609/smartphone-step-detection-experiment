import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartphone_step_detection_experiment/l10n/stradio_strings.dart';
import 'package:smartphone_step_detection_experiment/main.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/screens/stradio/root_navigation_shell.dart';
import 'package:smartphone_step_detection_experiment/services/posthog_service.dart';
import 'package:smartphone_step_detection_experiment/services/preferences_service.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';
import 'package:smartphone_step_detection_experiment/services/recording_service.dart';
import 'package:smartphone_step_detection_experiment/theme/stradio_theme.dart';

class _TestRecordingStore implements RecordingStore {
  final List<SavedRecording> saved = [];
  ActiveSessionSnapshot? activeCache;

  @override
  Future<List<SavedRecording>> list() async => List.unmodifiable(saved);

  @override
  Future<void> save(SavedRecording recording) async {
    saved.add(recording);
  }

  @override
  Future<String> nextId(DateTime date) async =>
      nextRecordingId(saved.map((r) => r.recordingId), date);

  @override
  Future<void> clearAll() async {
    saved.clear();
    activeCache = null;
  }

  @override
  Future<void> saveActiveSessionCache(ActiveSessionSnapshot snapshot) async {
    activeCache = snapshot;
  }

  @override
  Future<ActiveSessionSnapshot?> loadActiveSessionCache() async => activeCache;

  @override
  Future<void> clearActiveSessionCache() async {
    activeCache = null;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StradioPreferencesService.init();
  });

  SavedRecording buildTodayRecording({
    required String id,
    required DateTime createdAt,
    required int steps,
    double durationSeconds = 900.0,
    Activity activity = Activity.walking,
  }) {
    return SavedRecording(
      recordingId: id,
      createdAt: createdAt,
      config: ExperimentConfig(
        participantId: 'Raka',
        activity: activity,
        phonePlacement: PhonePlacement.pocket,
        placementDetail: 'Front right pocket',
        trialNumber: 1,
        primaryLiveAlgorithm: ThresholdAlgorithm.adaptiveMidpoint,
        targetSteps: 5000,
      ),
      samples: const [],
      liveStepCount: steps,
      replayDetections: const {},
      summaryDurationSeconds: durationSeconds,
      includeRawSamples: false,
    );
  }

  testWidgets(
    'RootNavigationShell renders 5-slot Floating Island Nav and syncs language live across all tabs',
    (tester) async {
      final store = _TestRecordingStore();
      StradioUserProfile? latestProfile;

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              dailyStepGoal: 5000,
              language: AppLanguage.en,
              hasCompletedOnboarding: true,
            ),
            store: store,
            onProfileChanged: (updated) => latestProfile = updated,
            referenceDate: DateTime(2026, 11, 11, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 5-slot Floating Island labels in English and protruding Run button
      final navBar = find.byKey(const Key('floating_island_nav_bar'));
      expect(navBar, findsOneWidget);
      final runButtonRect = tester.getRect(
        find.byKey(const Key('nav_center_run_button')),
      );
      final homeTabRect = tester.getRect(find.byKey(const Key('nav_tab_home')));
      expect(runButtonRect.top, lessThan(homeTabRect.top));

      expect(
        find.descendant(of: navBar, matching: find.text('Home')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Library')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Run')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Activity')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Settings')),
        findsOneWidget,
      );
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Raka'), findsOneWidget);

      // Navigate to Settings tab and switch language to Bahasa Indonesia
      await tester.tap(find.byKey(const Key('nav_tab_settings')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_lang_id')));
      await tester.pumpAndSettle();

      expect(latestProfile?.language, AppLanguage.id);
      // Verify 5-slot Floating Island labels immediately updated to Bahasa Indonesia
      expect(
        find.descendant(of: navBar, matching: find.text('Beranda')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Koleksi')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Lari')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Aktivitas')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Setelan')),
        findsOneWidget,
      );

      // Navigate back to Home tab and verify Bahasa Indonesia time-aware greeting
      await tester.tap(find.byKey(const Key('nav_tab_home')));
      await tester.pumpAndSettle();
      expect(find.text('Selamat pagi,'), findsOneWidget);
    },
  );

  testWidgets(
    'Center Run button opens Pre-Run Goal Selector Sheet with remaining daily steps and launches ActiveRunScreen full-screen',
    (tester) async {
      final now = DateTime(2026, 11, 11, 8, 30);
      final store = _TestRecordingStore()
        ..saved.add(
          buildTodayRecording(
            id: 'REC_20261111_001',
            createdAt: now,
            steps: 2200,
          ),
        );

      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.1, 0.2, 9.81, DateTime.now()),
        ),
        userSource: (_) => Stream.value(
          UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()),
        ),
      );
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test_shell',
        transport: (uri, payload) async => 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialProfile: const StradioUserProfile(
              nickname: 'Nadia',
              heightCm: 165,
              dailyStepGoal: 5000,
              isOpenGoal: false,
              hasCompletedOnboarding: true,
            ),
            store: store,
            recordingService: recordingService,
            postHogService: postHog,
            referenceDate: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify today's accumulated progress on Home: 2,200 / 5,000 steps
      expect(find.text('2,200 / 5,000 steps'), findsOneWidget);

      // Tap center Run button -> Pre-Run Goal Selector Sheet appears
      await tester.tap(find.byKey(const Key('nav_center_run_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose Session Goal Mode'), findsOneWidget);
      expect(find.text('Continue Daily Target'), findsOneWidget);
      expect(
        find.text('2,800 steps left to reach today\'s goal.'),
        findsOneWidget,
      );
      expect(find.text('Open Goal (Free Run)'), findsOneWidget);

      // Tap Continue Daily Target -> launches ActiveRunScreen full-screen
      await tester.tap(find.byKey(const Key('pre_run_continue_daily_option')));
      await tester.pumpAndSettle();

      // Floating Island Nav Bar is not visible on full-screen ActiveRunScreen
      expect(find.byKey(const Key('floating_island_nav_bar')), findsNothing);
      expect(find.byKey(const Key('active_run_step_count')), findsOneWidget);

      // Saved LabSettings should have targetSteps = 2800
      final lab = StradioPreferencesService.loadLabSettings();
      expect(lab.targetSteps, 2800);
      expect(lab.participantId, 'Nadia');
    },
  );

  testWidgets(
    'Library soundscape selection, Favorites filter, and Settings 7-tap Developer Mode unlock & 1-tap exit work cleanly',
    (tester) async {
      final store = _TestRecordingStore();

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.darkTheme,
          home: RootNavigationShell(
            initialProfile: const StradioUserProfile(
              nickname: 'Andi',
              hasCompletedOnboarding: true,
            ),
            store: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Library tab
      await tester.tap(find.byKey(const Key('nav_tab_library')));
      await tester.pumpAndSettle();

      expect(find.text('Chill Walk'), findsOneWidget);
      expect(find.text('Tempo Jog'), findsOneWidget);

      // Tap preview on Tempo Jog -> shows honest audio coming soon notice
      await tester.ensureVisible(
        find.byKey(const Key('library_preview_tempo_jog')),
      );
      await tester.tap(find.byKey(const Key('library_preview_tempo_jog')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('library_audio_preview_banner')),
        findsOneWidget,
      );

      // Favorite Tempo Jog and filter by Favorites
      await tester.ensureVisible(
        find.byKey(const Key('library_fav_tempo_jog')),
      );
      await tester.tap(find.byKey(const Key('library_fav_tempo_jog')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('library_filter_favorites')),
      );
      await tester.tap(find.byKey(const Key('library_filter_favorites')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('library_select_tempo_jog')),
        findsOneWidget,
      );
      expect(find.text('Chill Walk'), findsNothing);

      // Switch to Settings tab and tap App Version 7 times to unlock Developer Mode
      await tester.tap(find.byKey(const Key('nav_tab_settings')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_developer_tools_card')),
        findsNothing,
      );

      final versionTarget = find.byKey(const Key('settings_version_tap_target'));
      await tester.drag(
        find.byKey(const Key('shell_settings_scroll')),
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        await tester.tap(versionTarget);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_developer_tools_card')),
        findsOneWidget,
      );
      expect(
        StradioPreferencesService.loadUserProfile().developerModeEnabled,
        isTrue,
      );

      // Exit Developer Mode in 1 tap via the top switch
      final devSwitch = find.byKey(const Key('settings_dev_mode_switch'));
      await tester.drag(
        find.byKey(const Key('shell_settings_scroll')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.tap(devSwitch);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_developer_tools_card')),
        findsNothing,
      );
      expect(
        StradioPreferencesService.loadUserProfile().developerModeEnabled,
        isFalse,
      );
    },
  );

  testWidgets(
    'Stage 4D: HomeScreen accumulates multiple same-day sessions, shows goal reached banner, Quick Start hides Labs when Dev Mode OFF, and Back returns cleanly',
    (tester) async {
      final now = DateTime(2026, 11, 11, 16, 0);
      final store = _TestRecordingStore()
        ..saved.addAll([
          buildTodayRecording(
            id: 'REC_20261111_002',
            createdAt: now,
            steps: 3100,
            durationSeconds: 1200,
            activity: Activity.jogging,
          ),
          buildTodayRecording(
            id: 'REC_20261111_001',
            createdAt: now.subtract(const Duration(hours: 6)),
            steps: 2200,
            durationSeconds: 900,
            activity: Activity.walking,
          ),
        ]);

      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.1, 0.2, 9.81, DateTime.now()),
        ),
        userSource: (_) => Stream.value(
          UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              heightCm: 170,
              dailyStepGoal: 5000,
              developerModeEnabled: false,
              hasCompletedOnboarding: true,
            ),
            store: store,
            recordingService: recordingService,
            referenceDate: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Accumulated steps today: 3,100 + 2,200 = 5,300
      expect(find.byKey(const Key('home_daily_goal_hero_card')), findsOneWidget);
      expect(find.byKey(const Key('home_today_steps_value')), findsOneWidget);
      expect(find.text('5,300 / 5,000 steps'), findsOneWidget);
      expect(find.byKey(const Key('home_goal_reached_banner')), findsOneWidget);
      expect(find.byKey(const Key('home_recent_session_card')), findsOneWidget);

      // Tap Quick Start preset (Tempo Jog 145 BPM)
      final tempoPreset = find.byKey(const Key('home_quick_start_tempo_jog'));
      await tester.ensureVisible(tempoPreset);
      await tester.tap(tempoPreset);
      await tester.pumpAndSettle();

      // ActiveRunScreen opens in consumer mode (Developer Mode OFF):
      // - Labs button and technical A1 Midpoint badge are hidden
      // - Back button is visible
      expect(find.byKey(const Key('open_sensor_labs_button')), findsNothing);
      expect(find.text('A1 Midpoint'), findsNothing);
      expect(find.byKey(const Key('active_run_back_button')), findsOneWidget);

      // Tap Back button -> returns cleanly to HomeScreen
      await tester.tap(find.byKey(const Key('active_run_back_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_daily_goal_hero_card')), findsOneWidget);

      // Tap Recent Session card -> opens PostRunSummaryScreen in consumer mode
      final recentCard = find.byKey(const Key('home_recent_session_card'));
      await tester.ensureVisible(recentCard);
      await tester.tap(recentCard);
      await tester.pumpAndSettle();

      expect(find.text('POST-RUN INSIGHTS'), findsOneWidget);
      expect(find.text('3,100 STEPS'), findsOneWidget);
      // Research-only benchmark badge & 4-Algorithm Scoreboard are hidden in consumer mode
      expect(find.text('100 Steps Benchmark'), findsNothing);
      expect(find.text('4-Algorithm Replay Scoreboard'), findsNothing);
    },
  );

  testWidgets(
    'Stage 4D: StradioApp with enableConsumerShell transitions from OnboardingScreen to RootNavigationShell and HomeScreen',
    (tester) async {
      final store = _TestRecordingStore();

      await tester.pumpWidget(
        StradioApp(
          store: store,
          enableConsumerShell: true,
          initialUserProfile: const StradioUserProfile(
            hasCompletedOnboarding: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on Step 1 of OnboardingScreen
      expect(find.text('Find Your Stride Rhythm'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      // Skip nickname on Step 2 -> transitions directly to RootNavigationShell & HomeScreen
      await tester.tap(find.byKey(const Key('onboarding_skip_nickname_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('floating_island_nav_bar')), findsOneWidget);
      expect(find.byKey(const Key('home_daily_goal_hero_card')), findsOneWidget);
      expect(find.byKey(const Key('home_empty_history_card')), findsOneWidget);
      expect(find.text('Runner'), findsOneWidget);
    },
  );
}

