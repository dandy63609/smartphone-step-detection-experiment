import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:smartphone_step_detection_experiment/main.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/screens/dashboard_screen.dart';
import 'package:smartphone_step_detection_experiment/services/posthog_service.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';
import 'package:smartphone_step_detection_experiment/services/recording_service.dart';

class InMemoryRecordingStore implements RecordingStore {
  final List<SavedRecording> saved = [];

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
  }
}

void main() {
  testWidgets(
    'STRADIO full 4-screen flow: Active Run -> Sensor Labs -> Developer Overlay -> Post-Run Summary -> Legacy Experiment',
    (WidgetTester tester) async {
      final store = InMemoryRecordingStore();
      final postHog = PostHogTelemetryService(
        apiKey: 'phc_test_stradio',
        transport: (uri, payload) async => 200,
      );
      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.1, 0.2, 9.81, DateTime.now()),
        ),
        userSource: (_) => Stream.value(
          UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()),
        ),
      );

      await tester.pumpWidget(
        StradioApp(
          store: store,
          recordingService: recordingService,
          postHogService: postHog,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Active Run & Reactive Music Screen (launches directly, native splash handles pre-render)
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.byKey(const Key('status_indicator_dot')), findsOneWidget);
      expect(find.text('STEPS'), findsOneWidget);
      expect(find.byKey(const Key('active_run_step_count')), findsOneWidget);
      expect(find.text('Neon Stride · Adaptive Stride'), findsOneWidget);
      expect(find.text('Finish Run'), findsOneWidget);

      // Verify Milestone 1 additions: Center Rhythm Core Emblem & Segmented Utility Bar
      expect(find.byKey(const Key('hero_rhythm_core_emblem')), findsOneWidget);
      expect(find.byKey(const Key('utility_bpm_selector_button')), findsOneWidget);
      expect(find.text('A1 Midpoint'), findsOneWidget);

      // Start step detection by tapping bottom deck Play button (thumb zone)
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);

      // 3. Open Screen 4: Sensor Labs & Diagnostics Bottom Sheet
      await tester.tap(find.byKey(const Key('open_sensor_labs_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sensor Labs & Diagnostics'), findsOneWidget);
      expect(find.text('Developer Mode Overlay (OFF)'), findsOneWidget);
      expect(find.text('SensorManager Active (100 Hz)'), findsOneWidget);
      expect(find.text('Export Full Sensor Dataset (CSV)'), findsOneWidget);
      expect(find.text('Open Legacy Experiment Screen'), findsOneWidget);

      // Toggle Developer Mode Overlay ON
      await tester.tap(find.byKey(const Key('developer_overlay_switch')));
      await tester.pumpAndSettle();
      expect(find.text('Developer Mode Overlay (ON)'), findsOneWidget);

      // Close Sensor Labs sheet
      await tester.tap(find.byKey(const Key('sensor_labs_close_button')));
      await tester.pumpAndSettle();

      // Verify Developer Telemetry Overlay is now visible over ActiveRunScreen
      expect(
        find.byKey(const Key('developer_telemetry_overlay')),
        findsOneWidget,
      );
      expect(
        find.text('LIVE 100HZ TELEMETRY & 4-ALGORITHM MATRIX'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('live_variant_count_A1')), findsOneWidget);
      expect(find.byKey(const Key('live_variant_count_A2')), findsOneWidget);
      expect(find.byKey(const Key('live_variant_count_B1')), findsOneWidget);
      expect(find.byKey(const Key('live_variant_count_B2')), findsOneWidget);

      // Simulate 3 strides via Developer Overlay and verify ALL 4 variants (A1, A2, B1, B2) increment
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('overlay_simulate_stride_button')));
        await tester.pump();
      }
      expect(find.text('A1: 3 steps'), findsOneWidget);
      expect(find.text('A2: 3 steps'), findsOneWidget);
      expect(find.text('B1: 3 steps'), findsOneWidget);
      expect(find.text('B2: 3 steps'), findsOneWidget);

      // Pause and Resume run
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('PAUSED'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);

      // 4. Finish Run -> Navigate to Screen 3: Post-Run Summary Screen
      await tester.tap(find.byKey(const Key('finish_run_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Run Complete! : You Found Your Rhythm'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('summary_back_button')), findsOneWidget);
      expect(find.byKey(const Key('summary_top_share_button')), findsOneWidget);
      expect(find.byKey(const Key('summary_steps_headline')), findsOneWidget);
      expect(find.byKey(const Key('rhythm_score_headline')), findsOneWidget);
      expect(
        find.text('Cadence Consistency Across Run (SPM)'),
        findsOneWidget,
      );
      expect(
        find.text('4-ALGORITHM EVALUATION BENCHMARK'),
        findsOneWidget,
      );
      expect(find.text('Save & Finish Workout'), findsOneWidget);
      expect(find.text('Share Workout'), findsOneWidget);

      // Exercise Share Workout button
      await tester.tap(find.byKey(const Key('share_workout_button')));
      await tester.pumpAndSettle();
      expect(
        find.text('Workout summary prepared for sharing.'),
        findsOneWidget,
      );

      // Save & Finish Workout -> persists recording & sends PostHog telemetry
      await tester.tap(find.byKey(const Key('save_finish_workout_button')));
      await tester.pumpAndSettle();

      expect(store.saved.length, 1);
      final eventNames = postHog.recordedEvents.map((e) => e.event).toList();
      expect(eventNames, contains('run_completed'));
      expect(
        eventNames.where((e) => e == 'algorithm_benchmark_evaluated').length,
        4,
      );

      // 5. Open Sensor Labs -> Navigate to Legacy Experiment Screen (DashboardScreen)
      await tester.tap(find.byKey(const Key('open_sensor_labs_button')));
      await tester.pumpAndSettle();

      final legacyBtn = find.byKey(const Key('open_legacy_experiment_button'));
      await tester.ensureVisible(legacyBtn);
      await tester.tap(legacyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step Detection Experiment'), findsOneWidget);
      expect(find.text('E1'), findsOneWidget);

      // Verify LegacyExperimentShell applies StepDetectionApp.lightTheme (not dark Midnight background)
      final dashboardScaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(Scaffold),
        ),
      );
      final dashboardTheme = Theme.of(
        tester.element(find.byType(DashboardScreen)),
      );
      expect(dashboardScaffold.backgroundColor, isNull);
      expect(
        dashboardTheme.scaffoldBackgroundColor,
        StepDetectionApp.googleSurface,
      );

      // Navigate back from Legacy Experiment Screen to ActiveRunScreen
      await tester.tap(find.byKey(const Key('legacy_dashboard_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Finish Run'), findsOneWidget);
    },
  );

  testWidgets(
    'Exercises Sensor Error fallback (repeated Simulate Stride taps), Tempo BPM selector, Sensor Labs benchmark inputs, Mean+SD chip, PostHog sync, and Empty CSV state',
    (WidgetTester tester) async {
      final store = InMemoryRecordingStore();
      final postHog = PostHogTelemetryService(
        apiKey: '',
        transport: (uri, payload) async => 200,
      );
      // Stream.empty() triggers sensor unavailable error state cleanly
      final unavailableService = RecordingService(
        source: (_) => const Stream<AccelerometerEvent>.empty(),
      );

      await tester.pumpWidget(
        StradioApp(
          store: store,
          recordingService: unavailableService,
          postHogService: postHog,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sensor Standby / Error state banner and Simulate Stride (+1) action stays visible across repeated taps
      expect(find.text('STANDBY'), findsOneWidget);
      expect(
        find.byKey(const Key('simulate_stride_banner_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('simulate_stride_banner_button')));
      await tester.pump();
      // Banner must still be visible for a second tap while sensor remains in standby
      expect(find.text('STANDBY'), findsOneWidget);
      expect(
        find.byKey(const Key('simulate_stride_banner_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('simulate_stride_banner_button')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // Exercise Tempo BPM PopupSelector (118 BPM)
      await tester.tap(find.byKey(const Key('tempo_bpm_selector_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('118 BPM (Brisk Walk)'));
      await tester.pumpAndSettle();
      expect(find.text('Neon Stride · Adaptive Stride'), findsOneWidget);

      // Open Sensor Labs and exercise benchmark config, Mean+SD (B1) chip, PostHog sync, and empty CSV export
      await tester.tap(find.byKey(const Key('open_sensor_labs_button')));
      await tester.pumpAndSettle();

      final meanSdChip = find.text('Mean+SD (B1)');
      await tester.ensureVisible(meanSdChip);
      await tester.tap(meanSdChip);
      await tester.pump();

      final targetField = find.byKey(const Key('target_ground_truth_input'));
      await tester.ensureVisible(targetField);
      await tester.enterText(targetField, '100');

      final participantField = find.byKey(const Key('participant_id_input'));
      await tester.ensureVisible(participantField);
      await tester.enterText(participantField, 'P05');

      final applyBtn = find.byKey(const Key('apply_benchmark_button'));
      await tester.ensureVisible(applyBtn);
      await tester.pumpAndSettle();
      await tester.tap(applyBtn);
      await tester.pump();
      expect(
        find.text('Benchmark target updated: 100 Steps (P05).'),
        findsOneWidget,
      );

      // Sync PostHog key at runtime
      final keyField = find.byKey(const Key('posthog_api_key_input'));
      await tester.ensureVisible(keyField);
      await tester.enterText(keyField, 'phc_runtime_key');
      final syncBtn = find.byKey(const Key('sync_posthog_button'));
      await tester.ensureVisible(syncBtn);
      await tester.pumpAndSettle();
      await tester.tap(syncBtn);
      await tester.pumpAndSettle();
      expect(postHog.isConfigured, isTrue);

      // Tap Export Full Sensor Dataset (CSV) when 0 recordings are saved -> honest empty feedback
      final exportBtn = find.byKey(const Key('export_full_csv_button'));
      await tester.ensureVisible(exportBtn);
      await tester.pumpAndSettle();
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No saved recordings yet'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Responsive layout holds across narrow mobile (360px), tablet (768px), and wide (1024px) widths without overflow',
    (WidgetTester tester) async {
      final store = InMemoryRecordingStore();
      final postHog = PostHogTelemetryService(apiKey: '');
      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.0, 0.0, 9.81, DateTime.now()),
        ),
      );

      for (final size in const [
        Size(360, 740),
        Size(768, 1024),
        Size(1024, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          StradioApp(
            store: store,
            recordingService: recordingService,
            postHogService: postHog,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PAUSED'), findsOneWidget);
        expect(find.text('STRIDE GOAL'), findsOneWidget);
        expect(find.text('Finish Run'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      // Verify Warm Ivory Light -> Deep Obsidian Dark Mode toggle (Point 7.3) & Monogram Avatar
      await tester.binding.setSurfaceSize(const Size(412, 892));
      await tester.pumpWidget(
        StradioApp(
          store: store,
          recordingService: recordingService,
          postHogService: postHog,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stradio_header_logo')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_toggle_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('theme_mode_toggle_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Sprint 1: Sensor stream auto-recovers after Save & Finish, Discard, and changing algorithm in Sensor Labs without getting stuck',
    (WidgetTester tester) async {
      final store = InMemoryRecordingStore();
      final recordingService = RecordingService(
        source: (_) => Stream.value(
          AccelerometerEvent(0.1, 9.8, 1.2, DateTime.now()),
        ),
        userSource: (_) => Stream.value(
          UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()),
        ),
      );
      final postHog = PostHogTelemetryService(
        apiKey: '',
        transport: (uri, payload) async => 200,
      );

      await tester.pumpWidget(
        StradioApp(
          store: store,
          recordingService: recordingService,
          postHogService: postHog,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Start run -> Pause
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('PAUSED'), findsOneWidget);

      // 2. Open Sensor Labs -> switch algorithm to Mean+SD (B1) -> close sheet
      await tester.tap(find.byKey(const Key('open_sensor_labs_button')));
      await tester.pumpAndSettle();

      final meanSdChip = find.text('Mean+SD (B1)');
      await tester.ensureVisible(meanSdChip);
      await tester.tap(meanSdChip);
      await tester.pumpAndSettle();

      final closeButton = find.byKey(const Key('sensor_labs_close_button'));
      await tester.ensureVisible(closeButton);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // 3. Resume run -> must transition to RUNNING smoothly and keep recording
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);
      expect(recordingService.isRecording, isTrue);

      // 4. Finish run -> Save & Finish
      await tester.tap(find.byKey(const Key('finish_run_button')));
      await tester.pumpAndSettle();
      expect(find.text('Save & Finish Workout'), findsOneWidget);

      await tester.tap(find.byKey(const Key('save_finish_workout_button')));
      await tester.pumpAndSettle();

      // Back on ActiveRunScreen: trial count incremented, in Standby/Paused, ready to run again
      expect(find.text('PAUSED'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);
      expect(recordingService.isRecording, isTrue);

      // 5. Finish run -> Discard (Back button)
      await tester.tap(find.byKey(const Key('finish_run_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary_back_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('summary_back_button')));
      await tester.pumpAndSettle();

      // Back on ActiveRunScreen: must auto-reconnect stream and resume without freeze
      expect(find.text('PAUSED'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pause_resume_run_button')));
      await tester.pump();
      expect(find.text('RUNNING'), findsOneWidget);
      expect(recordingService.isRecording, isTrue);
    },
  );
}
