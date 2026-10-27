# Smartphone Step Detection Experiment

A research-grade Flutter application comparing two adaptive-threshold step-detection algorithms (**Adaptive Midpoint** and **Mean + k·SD**) for smartphone accelerometers across walking and jogging activities and phone placements (hand vs. pocket).

Every trial is calibrated against a standardized **100 physical steps** ground truth ($N_{\text{true}} = 100$).

---

## Installation

Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Dart `^3.13.5`).

Clone the repository and install dependencies:

```bash
git clone https://github.com/dandy63609/smartphone-step-detection-experiment.git
cd smartphone-step-detection-experiment
flutter pub get
```

Run on a physical Android device:

```bash
flutter run
```

---

## Usage

### 1. In-App Experimental Workflow

1. **Dashboard:** Displays progress across the 8 experimental conditions (**E1–E8**), targeting 5 repetitions per condition (40 physical recordings total).
2. **Setup:** Select participant ID, activity (`walking` / `jogging`), placement (`hand` / `pocket`), and the primary live algorithm.
3. **Live Recording:**
   - 3-second preparation countdown.
   - Real-time step counter, visual pulse animation, and progress toward 100 steps.
   - Live waveform chart rendering acceleration magnitude, dynamic threshold, and detected step peaks.
   - Manual **"Stop (100 Steps Completed)"** trigger.
4. **Trial Results & Replay:** Side-by-side comparison of **Adaptive Midpoint** vs. **Mean + k·SD** with absolute error, margin of error (%), and accuracy (%). Live results are automatically verified against offline replay.
5. **Export:** One-tap native sharing of `sensor_data.csv` and `evaluation_summary.csv`.

---

### 2. Dart API & Algorithmic Signal Processing

```dart
import 'package:smartphone_step_detection_experiment/algorithms/step_detector.dart';
import 'package:smartphone_step_detection_experiment/evaluation/step_count_evaluation.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';

// Shared algorithm parameters (AGENTS.md §3)
const params = AlgorithmParameters(
  smoothingSamples: 3,        // causal moving-average window
  windowDurationMs: 1000,     // rolling threshold window duration
  minimumStepIntervalMs: 250, // refractory lockout
  k: 1.5,                     // used by Mean + k·SD algorithm
);

// Instantiate streaming detector for live acceleration events
final detector = StepDetector(
  algorithm: ThresholdAlgorithm.adaptiveMidpoint,
  parameters: params,
);

// Feed samples in real time (returns output with step event when confirmed)
for (final sample in sensorStream) {
  final output = detector.addSample(sample);
  if (output.step != null) {
    print('Step detected at ${output.step!.peakTimestampNs} ns!');
  }
}

// Replay offline over exact recorded sample sequence
final replayDetections = StepDetector.replay(
  recordedSamples,
  algorithm: ThresholdAlgorithm.meanStd,
  parameters: params,
);

// Compute 100-step ground-truth error metrics
final evaluation = StepCountResult(
  recordingId: 'REC_20261027_001',
  trialNumber: 1,
  activity: Activity.walking,
  phonePlacement: PhonePlacement.hand,
  algorithm: ThresholdAlgorithm.meanStd,
  groundTruthSteps: 100,
  predictedSteps: replayDetections.length,
);

print('Margin of Error: ${evaluation.marginOfErrorPercent.toStringAsFixed(2)}%');
print('Accuracy: ${evaluation.accuracyPercent.toStringAsFixed(2)}%');
```

---

## Running Tests

Run the test suite including vector magnitude checks, rolling window statistics, peak detection state machine, exact CSV schema tests, and the synthetic 100-peak signal fixture:

```bash
flutter test
```

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

---

## License

[MIT](https://choosealicense.com/licenses/mit/)
