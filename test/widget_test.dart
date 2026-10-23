import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartphone_step_detection_experiment/main.dart';

void main() {
  testWidgets('shows the recording workflow', (WidgetTester tester) async {
    await tester.pumpWidget(const StepDetectionApp());

    expect(find.text('Step Detection Experiment'), findsOneWidget);
    expect(find.text('Recording baseline'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Import ground-truth CSV'), findsOneWidget);
  });
}
