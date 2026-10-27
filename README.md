# Smartphone Step Detection Experiment

Smartphone Step Detection Experiment is a Flutter app that records accelerometer
data and counts steps in real time. It compares two adaptive-threshold
step-detection algorithms, **adaptive midpoint** and **mean + k·standard
deviation**, for walking and jogging with the phone held in the hand or carried
in a pocket.

## Installation

Use the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.13.5`)
to install the dependencies and run the app on a physical Android device.

```bash
git clone https://github.com/dandy63609/smartphone-step-detection-experiment.git
cd smartphone-step-detection-experiment
flutter pub get
flutter run
```

## Usage

```dart
import 'package:smartphone_step_detection_experiment/algorithms/step_detector.dart';
import 'package:smartphone_step_detection_experiment/evaluation/event_matcher.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';

// Shared parameters for both algorithms
const params = AlgorithmParameters(
  smoothingSamples: 3,        // causal moving-average window
  windowDurationMs: 1000,     // adaptive threshold window
  minimumStepIntervalMs: 250, // refractory period
  k: 1.5,                     // used by mean + k·SD only
);

// T(t) = (max(window) + min(window)) / 2
final midpoint = StepDetector(
  algorithm: ThresholdAlgorithm.adaptiveMidpoint,
  parameters: params,
);

// T(t) = mean(window) + k · std(window)
final meanStd = StepDetector(
  algorithm: ThresholdAlgorithm.meanPlusStandardDeviation,
  parameters: params,
);

// returns the detected steps for the recorded samples
final List<DetectionEvent> steps = midpoint.process(samples);

// returns precision, recall, F1, count error and latency
final result = evaluateDetections(
  recordingId: 'REC_20261027_001',
  algorithm: 'adaptive_midpoint',
  detections: steps,
  groundTruth: groundTruthEvents,
  matchingToleranceMs: 200,
);
print(result.percentageCountError); // e.g. 2.0 -> 98 of 100 steps
```

In the app, each trial covers **100 physical steps** across eight conditions
(E1–E8: walking/jogging × hand/pocket × two algorithms). When a trial ends, both
algorithms run again on the same recorded samples, and you can export
`sensor_data.csv` and `evaluation_summary.csv`.

Run the tests with:

```bash
flutter test
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
