# Smartphone Step Detection Experiment

A research-grade Flutter application comparing adaptive-threshold step-detection algorithms (**Adaptive Midpoint** and **Mean + $k\cdot\text{SD}$**) across both **Raw Accelerometer (with gravity)** and **User/Linear Accelerometer (without gravity)** streams for walking and jogging activities under different phone placements (hand vs. pocket).

Every trial is calibrated against a standardized **100 physical steps** ground truth ($N_{\text{true}} = 100$).

---

## Key Features

- **4-Algorithm Simultaneous Benchmark (A1, A2, B1, B2):**
  One physical 100-step session records synchronized dual sensor streams at 100 Hz and evaluates all 4 algorithm combinations side-by-side:
  | Code | Threshold Algorithm | Sensor Input Stream | Description |
  | :---: | :--- | :--- | :--- |
  | **A1** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | Raw Accelerometer (+Gravity) | Baseline adaptive midpoint with gravity ($\approx 9.8\ \text{m/s}^2$). |
  | **A2** | **Adaptive Midpoint** $\frac{\max + \min}{2}$ | User Accelerometer (Linear -Gravity) | Tests whether gravity removal stabilizes the dynamic midpoint. |
  | **B1** | **Mean + $k\cdot\text{SD}$** ($\mu + k\sigma$) | Raw Accelerometer (+Gravity) | Statistical deviation threshold on raw magnitude. |
  | **B2** | **Mean + $k\cdot\text{SD}$** ($\mu + k\sigma$) | User Accelerometer (Linear -Gravity) | Statistical deviation threshold on pure linear acceleration. |
- **Stationary Noise Gate (`minWindowSpreadMps2 = 1.2` $\text{m/s}^2$):**
  Prevents thermal/MEMS micro-noise ($\approx \pm 0.03\ \text{m/s}^2$) from triggering false step counts when the smartphone rests stationary on a table, while locking the live chart's minimum vertical span (`6.0` $\text{m/s}^2$) so idle signals appear as a steady flat line.
- **Google Material Design 3 UI (Google Fit / Health Connect Style):**
  Clean tonal surfaces, `SegmentedButton` factor controls, circular step progress gauge with pulse animation, real-time $m(t)$ & $T(t)$ telemetry, and an instant 4-way **Scoreboard** classifying each detector (`Akurat`, `Overcounting`, `Undercounting`).
- **Complete CSV Dataset Export:**
  One-tap native sharing of `sensor_data.csv`, `sensor_linear_data.csv`, and `evaluation_summary.csv`.
- **Automated CI/CD & Slim APK Releases:**
  GitHub Actions workflows for Gitleaks secret scanning, `flutter analyze`, `flutter test`, and automatic `--split-per-abi` slim APK (~15 MB) publishing to GitHub Releases.

---

## Installation

Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Dart `^3.11.0+`).

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

Or download the latest pre-built **`step-detection-v*-arm64-v8a.apk`** directly from the repository's **GitHub Releases** page.

---

## In-App Experimental Workflow

1. **Dashboard:** Displays pilot progress across the 8 factorial conditions (**E1–E8**), targeting 5 repetitions per condition (40 physical recordings total).
2. **Setup:** Select participant ID (`P01`), activity (`walking` / `jogging`), placement (`hand` / `pocket`), and the primary live algorithm using Material 3 segmented controls.
3. **Live Recording:**
   - 3-second preparation countdown.
   - Google Fit-style circular step counter gauge, visual pulse animation, and progress toward 100 steps.
   - Live waveform chart rendering acceleration magnitude $m(t)$, dynamic threshold $T(t)$, motion status (`Stationary (Idle)` vs `Motion Active`), and confirmed step peaks.
   - Manual **"Stop (100 Steps Completed)"** trigger.
4. **Trial Evaluation & 4-Algorithm Scoreboard:**
   - Automatic verification that live step counts match offline replay.
   - **4-Algorithm Scoreboard (A1, A2, B1, B2)** comparing detected steps, signed step difference, Margin of Error (%), and status (`Akurat`, `Overcounting`, `Undercounting`).
5. **Export Datasets:** One-tap native sharing of `sensor_data.csv`, `sensor_linear_data.csv`, and `evaluation_summary.csv`.

---

## Dart API & Algorithmic Signal Processing

```dart
import 'package:smartphone_step_detection_experiment/algorithms/step_detector.dart';
import 'package:smartphone_step_detection_experiment/evaluation/step_count_evaluation.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';

// Shared algorithm parameters
const params = AlgorithmParameters(
  smoothingSamples: 3,         // causal moving-average window
  windowDurationMs: 1000,      // rolling threshold window duration
  minimumStepIntervalMs: 250,  // refractory lockout
  k: 1.5,                      // used by Mean + k·SD algorithm
  minWindowSpreadMps2: 1.2,    // stationary MEMS noise gate
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

// Replay all 4 combinations (A1, A2, B1, B2) offline over recorded samples
final allFourDetections = StepDetector.replayAllFour(recordedSamples, params);
for (final entry in allFourDetections.entries) {
  print('${entry.key.code} (${entry.key.displayName}): ${entry.value.length} steps');
}
```

---

## Running Tests

Run the test suite including vector magnitude checks (raw & linear), rolling window statistics, peak detection state machine, 30-second stationary table noise test, exact CSV schema tests, and the synthetic 100-peak signal fixture across all 4 variants:

```bash
flutter analyze
flutter test
```

---

## License

This project is licensed under the [MIT License](LICENSE).
