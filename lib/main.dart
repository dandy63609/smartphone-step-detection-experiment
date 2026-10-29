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

  static const Color googleBlue = Color(0xFF1A73E8);
  static const Color googleSurface = Color(0xFFF8FAFD);
  static const Color googleCardSurface = Color(0xFFF0F4F9);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: googleBlue,
      brightness: Brightness.light,
      primary: googleBlue,
      surface: googleSurface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF3F6FC),
      surfaceContainer: googleCardSurface,
      surfaceContainerHigh: const Color(0xFFE8EEF7),
      surfaceContainerHighest: const Color(0xFFDDE5F2),
    );

    return MaterialApp(
      title: 'Step Detection Experiment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: googleSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: googleSurface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFF444746)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE1E6EF), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F6FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDADCE0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDADCE0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: googleBlue, width: 2),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF444746),
            fontWeight: FontWeight.w500,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: googleBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: googleBlue,
            side: const BorderSide(color: Color(0xFFDADCE0)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFFD3E3FD),
          foregroundColor: const Color(0xFF041E49),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: DashboardScreen(
        store: store,
        recordingService: recordingService,
      ),
    );
  }
}
