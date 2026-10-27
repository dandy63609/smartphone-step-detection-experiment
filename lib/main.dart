import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'services/recording_repository.dart';
import 'services/recording_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StepDetectionApp());
}

class StepDetectionApp extends StatelessWidget {
  const StepDetectionApp({
    super.key,
    this.store,
    this.recordingService,
  });

  final RecordingStore? store;
  final RecordingService? recordingService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Detection Experiment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: DashboardScreen(
        store: store,
        recordingService: recordingService,
      ),
    );
  }
}
