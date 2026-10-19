import 'package:flutter/material.dart';

void main() {
  runApp(const StepDetectionApp());
}

class StepDetectionApp extends StatelessWidget {
  const StepDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Detection Experiment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ExperimentHomePage(),
    );
  }
}

class ExperimentHomePage extends StatelessWidget {
  const ExperimentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Detection Experiment')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Research scaffold', style: TextStyle(fontSize: 24)),
            SizedBox(height: 12),
            Text(
              'The sensor recorder and adaptive-threshold comparison will be built here.',
            ),
            SizedBox(height: 24),
            Text('Initial comparison'),
            Text('• Adaptive midpoint'),
            Text('• Mean + k standard deviation'),
            SizedBox(height: 24),
            Text(
              'Next milestone: configure and save a real accelerometer recording.',
            ),
          ],
        ),
      ),
    );
  }
}
