import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartphone_step_detection_experiment/l10n/stradio_strings.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/screens/stradio/root_navigation_shell.dart';
import 'package:smartphone_step_detection_experiment/services/posthog_service.dart';
import 'package:smartphone_step_detection_experiment/services/preferences_service.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';
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

  SavedRecording buildRecording({
    required String id,
    required DateTime createdAt,
    required int steps,
    required Activity activity,
    double durationSeconds = 900.0,
    int targetBpm = 145,
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
      targetBpm: targetBpm,
      includeRawSamples: false,
    );
  }

  testWidgets(
    'Stage 6A: ActivityScreen renders 7-Day Step Trend card, filters Walking/Jogging sessions, and opens PostRunSummaryScreen on tap',
    (tester) async {
      final now = DateTime(2026, 11, 11, 10, 0);
      final store = _TestRecordingStore()
        ..saved.addAll([
          buildRecording(
            id: 'REC_20261110_001',
            createdAt: now.subtract(const Duration(days: 1)),
            steps: 2000,
            activity: Activity.walking,
            targetBpm: 110,
          ),
          buildRecording(
            id: 'REC_20261111_001',
            createdAt: now,
            steps: 3400,
            activity: Activity.jogging,
            targetBpm: 165,
          ),
        ]);
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test',
        transport: (uri, payload) async => 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialTabIndex: 2,
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              heightCm: 170,
              dailyStepGoal: 5000,
              language: AppLanguage.en,
              hasCompletedOnboarding: true,
            ),
            store: store,
            postHogService: postHog,
            referenceDate: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 7-Day Weekly Summary Card shows 5,400 total steps and 2 sessions
      expect(
        find.byKey(const Key('activity_weekly_summary_card')),
        findsOneWidget,
      );
      expect(find.text('5,400'), findsOneWidget);
      expect(find.text('2 sessions'), findsOneWidget);

      // 2. Both sessions visible initially under All filter
      expect(
        find.byKey(const Key('activity_item_REC_20261110_001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('activity_item_REC_20261111_001')),
        findsOneWidget,
      );

      // 3. Filter by Walking -> only REC_20261110_001 is shown and weekly summary updates to 2,000 steps / 1 session
      await tester.tap(find.byKey(const Key('activity_filter_walking')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('activity_item_REC_20261110_001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('activity_item_REC_20261111_001')),
        findsNothing,
      );
      expect(find.text('2,000'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);

      // 4. Filter by Jogging -> only REC_20261111_001 is shown and weekly summary updates to 3,400 steps / 1 session
      await tester.tap(find.byKey(const Key('activity_filter_jogging')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('activity_item_REC_20261111_001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('activity_item_REC_20261110_001')),
        findsNothing,
      );
      expect(find.text('3,400'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);

      // 5. Tap session card -> opens PostRunSummaryScreen
      await tester.drag(
        find.byKey(const Key('shell_activity_scroll')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('activity_item_REC_20261111_001')));
      await tester.pumpAndSettle();
      expect(find.text('3,400 STEPS'), findsOneWidget);
    },
  );

  testWidgets(
    'Stage 7B: ActivityScreen switches 1W/1M/3M/All ranges, Bar/Line/Split chart types, and opens Frosted Popover on bucket tap',
    (tester) async {
      final now = DateTime(2026, 11, 11, 10, 0);
      final store = _TestRecordingStore()
        ..saved.addAll([
          buildRecording(
            id: 'REC_20261111_001',
            createdAt: now,
            steps: 3400,
            activity: Activity.jogging,
          ),
          buildRecording(
            id: 'REC_20261022_001',
            createdAt: now.subtract(const Duration(days: 20)),
            steps: 2600,
            activity: Activity.walking,
          ),
          buildRecording(
            id: 'REC_20260912_001',
            createdAt: now.subtract(const Duration(days: 60)),
            steps: 4000,
            activity: Activity.jogging,
          ),
        ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialTabIndex: 2,
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              heightCm: 170,
              dailyStepGoal: 5000,
              language: AppLanguage.en,
              hasCompletedOnboarding: true,
            ),
            store: store,
            postHogService: PostHogTelemetryService(apiKey: ''),
            referenceDate: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Default 1W shows only today's 3,400 steps (1 session)
      expect(find.text('3,400'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);

      // 2. Tap today's bar (index 6) -> opens frosted popover with details
      await tester.tap(find.byKey(const Key('activity_chart_bucket_6')));
      await tester.pumpAndSettle();
      final popover = find.byKey(const Key('activity_chart_popover'));
      expect(popover, findsOneWidget);
      expect(
        find.descendant(of: popover, matching: find.text('3,400 steps')),
        findsOneWidget,
      );

      // Close popover
      await tester.tap(find.byKey(const Key('activity_popover_close_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity_chart_popover')), findsNothing);

      // 3. Switch to 1M (30 days) -> includes 20-day-old walk (3,400 + 2,600 = 6,000 steps)
      await tester.tap(find.byKey(const Key('activity_range_month')));
      await tester.pumpAndSettle();
      expect(find.text('6,000'), findsOneWidget);
      expect(find.text('2 sessions'), findsOneWidget);

      // 4. Switch to 3M (90 days) -> includes 60-day-old run (10,000 steps, 3 sessions)
      await tester.tap(find.byKey(const Key('activity_range_quarter')));
      await tester.pumpAndSettle();
      expect(find.text('10,000'), findsOneWidget);
      expect(find.text('3 sessions'), findsOneWidget);

      // 5. Switch to Line Chart & tap last node -> opens popover cleanly
      await tester.tap(find.byKey(const Key('activity_chart_type_line')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('activity_line_chart_canvas')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('activity_chart_bucket_5')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity_chart_popover')), findsOneWidget);

      // 6. Switch to Activity Split Chart -> renders Walking/Jogging legend
      await tester.tap(find.byKey(const Key('activity_chart_type_split')));
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsWidgets);
      expect(find.text('Jogging'), findsWidgets);
    },
  );

  testWidgets(
    'Stage 6B: SettingsScreen edits Runner Profile & Goal, clears workout history with confirmation, and exposes full Developer & Research Tools suite',
    (tester) async {
      final now = DateTime(2026, 11, 11, 10, 0);
      final store = _TestRecordingStore()
        ..saved.add(
          buildRecording(
            id: 'REC_20261111_001',
            createdAt: now,
            steps: 2500,
            activity: Activity.walking,
          ),
        );
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test',
        transport: (uri, payload) async => 200,
      );
      StradioUserProfile? latestProfile;

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialTabIndex: 3,
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              heightCm: 170,
              dailyStepGoal: 5000,
              language: AppLanguage.en,
              hasCompletedOnboarding: true,
            ),
            store: store,
            postHogService: postHog,
            referenceDate: now,
            onProfileChanged: (updated) => latestProfile = updated,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Profile card displays initial nickname, height, and goal
      expect(find.byKey(const Key('settings_profile_card')), findsOneWidget);
      expect(find.text('170 cm · 5,000 steps'), findsOneWidget);
      expect(
        find.byKey(const Key('settings_battery_guide_card')),
        findsOneWidget,
      );

      // 2. Open Edit Profile & Goal sheet, change nickname to Nadia, height to 165, goal to 8,000
      await tester.tap(find.byKey(const Key('settings_edit_profile_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_nickname_input')),
        'Nadia',
      );
      await tester.enterText(
        find.byKey(const Key('settings_height_input')),
        '165',
      );
      await tester.tap(find.byKey(const Key('settings_goal_chip_8000')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('settings_save_profile_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_save_profile_button')));
      await tester.pumpAndSettle();

      expect(latestProfile?.nickname, 'Nadia');
      expect(latestProfile?.heightCm, 165.0);
      expect(latestProfile?.dailyStepGoal, 8000);
      expect(find.text('165 cm · 8,000 steps'), findsOneWidget);

      // 3. Clear Workout History via confirmation dialog
      await tester.drag(
        find.byKey(const Key('shell_settings_scroll')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_clear_history_button')));
      await tester.pumpAndSettle();

      expect(find.text('Clear all workout history?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_clear_history_button')));
      await tester.pumpAndSettle();

      expect(store.saved, isEmpty);
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('floating_island_nav_bar'))),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      // Switch to Activity tab and verify Empty History state is now shown
      await tester.tap(find.byKey(const Key('nav_tab_activity')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('activity_empty_state_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('activity_empty_start_run_button')),
        findsOneWidget,
      );

      // 4. Switch back to Settings, tap App Version 7 times to unlock Developer Mode
      await tester.tap(find.byKey(const Key('nav_tab_settings')));
      await tester.pumpAndSettle();

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
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('floating_island_nav_bar'))),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_developer_tools_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_open_sensor_labs_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_export_csv_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_open_legacy_experiment_button')),
        findsOneWidget,
      );

      // 5. Tap Export Research Dataset (CSV) when store is empty -> shows honest inline status
      await tester.drag(
        find.byKey(const Key('shell_settings_scroll')),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_export_csv_button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('settings_csv_export_status')),
        findsOneWidget,
      );
      expect(find.textContaining('No saved recordings yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Stage 6A & 6B: ActivityScreen and SettingsScreen adapt cleanly across 360x640 and 768x1024 viewports without overflow',
    (tester) async {
      final store = _TestRecordingStore();
      final postHog = PostHogTelemetryService(
        apiKey: '',
        transport: (uri, payload) async => 200,
      );

      for (final size in const [Size(360, 640), Size(768, 1024)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        for (final tabIndex in const [2, 3]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: StradioTheme.darkTheme,
              home: RootNavigationShell(
                initialTabIndex: tabIndex,
                initialProfile: const StradioUserProfile(
                  nickname: 'Raka',
                  heightCm: 170,
                  dailyStepGoal: 5000,
                  language: AppLanguage.id,
                  hasCompletedOnboarding: true,
                  developerModeEnabled: true,
                ),
                store: store,
                postHogService: postHog,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );
}

