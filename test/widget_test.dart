import 'package:flutter_test/flutter_test.dart';
import 'package:smartphone_step_detection_experiment/main.dart';

void main() {
  testWidgets('shows the experiment scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const StepDetectionApp());

    expect(find.text('Step Detection Experiment'), findsOneWidget);
    expect(find.text('Adaptive midpoint'), findsOneWidget);
    expect(find.text('Mean + k standard deviation'), findsOneWidget);
  });
}
