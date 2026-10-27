import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:smartphone_step_detection_experiment/main.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/services/recording_repository.dart';
import 'package:smartphone_step_detection_experiment/services/recording_service.dart';

class MockRecordingStore implements RecordingStore {
  final List<SavedRecording> _items = [];

  @override
  Future<List<SavedRecording>> list() async => List.unmodifiable(_items);

  @override
  Future<void> save(SavedRecording recording) async => _items.add(recording);

  @override
  Future<String> nextId(DateTime date) async => nextRecordingId(
        _items.map((r) => r.recordingId),
        date,
      );
}

void main() {
  testWidgets('renders Dashboard with E1–E8 conditions and opens Setup',
      (WidgetTester tester) async {
    final mockStore = MockRecordingStore();
    final mockService = RecordingService(
      source: (_) => Stream.value(
        AccelerometerEvent(0, 0, 9.8, DateTime.now()),
      ),
    );

    await tester.pumpWidget(
      StepDetectionApp(
        store: mockStore,
        recordingService: mockService,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard title & conditions
    expect(find.text('Step Detection Experiment'), findsOneWidget);
    expect(find.text('Pilot Progress'), findsOneWidget);
    expect(find.text('E1'), findsOneWidget);

    // Scroll to verify E8 condition is in the list
    await tester.scrollUntilVisible(
      find.text('E8'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('E8'), findsOneWidget);

    // Tap the Floating Action Button to start a trial
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify Setup Screen is opened
    expect(find.text('Setup Experiment Trial'), findsOneWidget);
    expect(find.text('Participant ID'), findsOneWidget);
    expect(find.text('Factor C: Activity'), findsOneWidget);
  });
}
