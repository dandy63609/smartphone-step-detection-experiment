import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartphone_step_detection_experiment/l10n/stradio_strings.dart';
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

  testWidgets(
    'LibraryScreen renders Active Soundscape Hero Card, filters categories, and shows Empty Favorites state with reset action',
    (tester) async {
      final store = _TestRecordingStore();
      StradioUserProfile? latestProfile;
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test_library',
        transport: (uri, payload) async => 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialTabIndex: 1,
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              dailyStepGoal: 5000,
              language: AppLanguage.en,
              hasCompletedOnboarding: true,
              activeSoundscapeId: 'neon_stride',
              favoriteSoundscapeIds: <String>{},
            ),
            store: store,
            postHogService: postHog,
            onProfileChanged: (profile) => latestProfile = profile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Active Soundscape Hero Card shows Neon Stride (165 BPM)
      expect(find.byKey(const Key('library_active_hero_card')), findsOneWidget);
      expect(
        find.byKey(const Key('library_start_active_theme_button')),
        findsOneWidget,
      );
      expect(find.textContaining('158-172 SPM'), findsWidgets);

      // 2. Filter by Chill -> only Chill Walk & Lo-Fi Pace in track list
      await tester.tap(find.byKey(const Key('library_filter_chill')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('library_select_chill_walk')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('library_select_lofi_pace')), findsOneWidget);
      expect(find.byKey(const Key('library_select_tempo_jog')), findsNothing);

      // 3. Filter by Favorites when empty -> Honest Empty Favorites card
      await tester.tap(find.byKey(const Key('library_filter_favorites')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('library_empty_favorites_card')),
        findsOneWidget,
      );
      expect(find.text('No favorite themes yet'), findsOneWidget);

      // 4. Tap Reset button inside Empty Favorites card -> returns to All
      await tester.drag(
        find.byKey(const Key('shell_library_scroll')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('library_empty_favorites_reset_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('library_empty_favorites_card')),
        findsNothing,
      );
      expect(find.byKey(const Key('library_select_tempo_jog')), findsOneWidget);

      // 5. Favorite Tempo Jog and verify it appears under Favorites filter
      await tester.ensureVisible(
        find.byKey(const Key('library_fav_tempo_jog')),
      );
      await tester.tap(find.byKey(const Key('library_fav_tempo_jog')));
      await tester.pumpAndSettle();
      expect(
        latestProfile?.favoriteSoundscapeIds.contains('tempo_jog'),
        isTrue,
      );

      await tester.ensureVisible(
        find.byKey(const Key('library_filter_favorites')),
      );
      await tester.tap(find.byKey(const Key('library_filter_favorites')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library_select_tempo_jog')), findsOneWidget);
      expect(find.byKey(const Key('library_select_chill_walk')), findsNothing);
    },
  );

  testWidgets(
    'LibraryScreen shows honest audio preview banner and Run This Tempo launches ActiveRunScreen with selected soundscape title and BPM',
    (tester) async {
      final store = _TestRecordingStore();
      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.1, 0.2, 9.81, DateTime.now()),
        ),
        userSource: (_) => Stream.value(
          UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()),
        ),
      );
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test_library_run',
        transport: (uri, payload) async => 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: StradioTheme.lightTheme,
          home: RootNavigationShell(
            initialTabIndex: 1,
            initialProfile: const StradioUserProfile(
              nickname: 'Raka',
              dailyStepGoal: 5000,
              language: AppLanguage.id,
              hasCompletedOnboarding: true,
              activeSoundscapeId: 'neon_stride',
            ),
            store: store,
            recordingService: recordingService,
            postHogService: postHog,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap preview on Tempo Jog (145 BPM) -> updates Active Hero Card and shows Indonesian audio notice banner
      final previewButton = find.byKey(const Key('library_preview_tempo_jog'));
      await tester.ensureVisible(previewButton);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('library_audio_preview_banner')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Integrasi file audio segera hadir'),
        findsOneWidget,
      );
      expect(find.text('Pratinjau Tempo'), findsOneWidget);

      // 2. Tap Goal Selector button inside Active Soundscape Hero Card -> opens Pre-Run Goal Selector Sheet
      final chooseGoalBtn = find.byKey(
        const Key('library_choose_goal_active_theme_button'),
      );
      await tester.ensureVisible(chooseGoalBtn);
      await tester.tap(chooseGoalBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pilih Mode Target Sesi'), findsOneWidget);
      expect(find.text('Tempo Jog · 145 BPM'), findsOneWidget);
      // Close the sheet and test direct 1-tap Run This Tempo CTA
      Navigator.of(tester.element(find.text('Pilih Mode Target Sesi'))).pop();
      await tester.pumpAndSettle();

      // 3. Tap "Lari dengan Tempo Ini" CTA inside the Active Soundscape Hero Card
      final startHeroButton = find.byKey(
        const Key('library_start_active_theme_button'),
      );
      await tester.ensureVisible(startHeroButton);
      await tester.tap(startHeroButton);
      await tester.pumpAndSettle();

      // Verify ActiveRunScreen displays "Tempo Jog · Adaptive Stride" and "145 BPM"
      expect(find.byKey(const Key('soundscape_title_text')), findsOneWidget);
      expect(find.text('Tempo Jog · Adaptive Stride'), findsOneWidget);
      expect(find.text('145 BPM'), findsOneWidget);
    },
  );

  testWidgets(
    'LibraryScreen layout adapts cleanly across compact 360x640 and tablet 768x1024 viewports without overflow',
    (tester) async {
      final store = _TestRecordingStore();
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test_library_responsive',
        transport: (uri, payload) async => 200,
      );

      for (final size in const [Size(360, 640), Size(768, 1024)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: StradioTheme.darkTheme,
            home: RootNavigationShell(
              initialTabIndex: 1,
              initialProfile: const StradioUserProfile(
                nickname: 'Raka',
                dailyStepGoal: 5000,
                language: AppLanguage.en,
                hasCompletedOnboarding: true,
              ),
              store: store,
              postHogService: postHog,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('library_active_hero_card')),
          findsOneWidget,
        );
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );
}
