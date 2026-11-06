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

## Glossary & Biomechanical-Audio Concepts

A comprehensive reference for developers, researchers, and collaborators explaining all technical terms, biomechanical metrics, signal processing pipelines, and audio-stride engine concepts used in the repository:

### 1. Biomechanical & Motion Dynamics

- **SPM (Steps Per Minute / Cadence):**
  The physical frequency of foot strikes per minute executed by the runner or walker. Calculated in real time over rolling time windows from peak-to-peak step intervals.
  $$\text{SPM} = \frac{60}{\Delta t_{\text{step}}(\text{seconds})}$$
- **Ground Truth 100 Steps ($N_{\text{true}} = 100$):**
  The fixed physical benchmark used for all trials. The participant performs exactly 100 physical steps counted manually and confirmed upon stopping. Because $N_{\text{true}} = 100$, any error count translates directly to a percentage without scaling:
  $$\text{Margin of Error (\%)} = |N_{\text{predicted}} - 100|\%$$
- **Phone Placement (`hand` vs. `pocket`):**
  Standardized carrying locations. Hand-held simulates typical smartphone use with arm swing dynamics; pocket placement isolates hip and leg translation while damping rotational noise.
- **Estimated Running Speed:**
  Cadence-driven instantaneous velocity approximation ($v = \text{SPM} \times \text{stride\_length}$) calibrated for walking ($\approx 0.65\ \text{m/step}$) and jogging ($\approx 0.90\ \text{m/step}$).

### 2. Audio-Stride & Music Engine

- **BPM (Beats Per Minute / Music Tempo):**
  The musical tempo of the synthesizer or audio track. Stradio couples BPM to physical cadence so music tempo tracks runner stride.
- **Audio-Stride Reactive Engine:**
  The proprietary closed-loop system where IMU sensor step events dynamically synchronize audio tempo, triggering reactive drum beats and synthesizer pulses locked to foot-strike impacts ($\text{BPM} \approx \text{SPM}$).
- **Soundscape Presets:**
  Pre-composed reactive audio environments calibrated to specific cadence envelopes:
  - **Lo-Fi Pace (118 BPM):** Relaxed cadence for warm-ups and brisk walking (110–125 SPM).
  - **Tempo Jog (145 BPM):** Mid-intensity endurance jogging (140–155 SPM).
  - **Neon Stride (165 BPM):** High-cadence rhythmic running preset (160–175 SPM).
  - **Cyber Cadence (180 BPM):** High-efficiency athletic cadence for 5K/10K pacing.

### 3. Signal Processing & Sensor Telemetry

- **3-Axis Raw Accelerometer ($a_x, a_y, a_z$):**
  Tri-axial acceleration in $\text{m/s}^2$ including gravity vector ($\approx 9.81\ \text{m/s}^2$ when stationary).
- **Linear / User Accelerometer ($u_x, u_y, u_z$):**
  Acceleration in $\text{m/s}^2$ with earth gravity computationally removed via device sensor-fusion algorithms.
- **Euclidean Vector Norm / Magnitude ($m(t)$):**
  Orientation-independent scalar total acceleration:
  $$m(t) = \sqrt{a_x(t)^2 + a_y(t)^2 + a_z(t)^2}$$
- **Causal Moving-Average Filter:**
  Low-pass smoothing filter using strictly past and present samples (3-sample window) to remove high-frequency MEMS jitter without introducing look-ahead bias:
  $$s(t) = \frac{1}{N}\sum_{i=0}^{N-1} m(t - i)$$
- **Rolling Threshold Window ($T_w = 1000\ \text{ms}$):**
  A 1-second sliding memory buffer of smoothed magnitude values used to calculate the real-time threshold $T(t)$.
- **Stationary Noise Gate (`minWindowSpreadMps2 = 1.2` $\text{m/s}^2$):**
  Safety threshold spread ($\max - \min$). If acceleration variation inside the 1-second window is less than $1.2\ \text{m/s}^2$ (e.g. resting on a desk or holding still), step detection is locked and the waveform renders as a flat line to eliminate false counts from micro-vibrations.
- **Refractory Lockout Period (250 ms):**
  Minimum physiological duration between consecutive foot strikes ($\le 240\ \text{SPM}$). Peaks occurring within 250 ms of an accepted step are rejected as secondary bounces or arm swings.
- **Valley Confirmation & Hysteresis:**
  Before a new peak can be accepted, the smoothed magnitude signal must drop below a valley threshold, ensuring the gait cycle enters the swing/flight phase before the next foot impact.

### 4. 4-Algorithm Matrix (A1, A2, B1, B2)

- **A1 — Adaptive Midpoint (Raw):**
  $$T(t) = \frac{\max(\text{window}) + \min(\text{window})}{2}$$
  Computed over raw accelerometer magnitude ($+g$). Rapidly adapts to changes in vertical amplitude.
- **A2 — Adaptive Midpoint (Linear):**
  Same midpoint formula applied to linear acceleration ($-g$). Evaluates whether eliminating gravity baseline reduces posture-tilt artifacts.
- **B1 — Mean + $k\cdot\text{SD}$ (Raw):**
  $$T(t) = \mu(\text{window}) + k \cdot \sigma(\text{window}),\quad k = 1.5$$
  Statistical threshold requiring foot strikes to exceed the mean by $1.5$ standard deviations. Resilient against gradual drift.
- **B2 — Mean + $k\cdot\text{SD}$ (Linear):**
  Statistical deviation threshold on pure linear acceleration.

### 5. Evaluation Metrics & Classifications

- **Absolute Step Error:**
  $$\text{Absolute Error} = |N_{\text{predicted}} - N_{\text{true}}| = |N_{\text{predicted}} - 100|$$
- **Percentage Margin of Error:**
  $$\text{Margin of Error (\%)} = \left(\frac{|N_{\text{predicted}} - 100|}{100}\right) \times 100\% = |N_{\text{predicted}} - 100|\%$$
- **Step Count Accuracy:**
  $$\text{Accuracy (\%)} = \max\left(0, 100\% - \text{Margin of Error (\%)}\right)$$
- **Scoreboard Performance Classification:**
  - **`Akurat` (Accurate):** $\text{Margin of Error} \le 3.0\%$ (97 to 103 detected steps).
  - **`Overcounting`:** $N_{\text{predicted}} > 103$ steps (detector too sensitive or counting bounces).
  - **`Undercounting`:** $N_{\text{predicted}} < 97$ steps (threshold too high or missed foot strikes).

### 6. Telemetry & Export Schema

- **PostHog Cloud Telemetry:**
  Structured product events (`run_started`, `run_paused`, `run_resumed`, `step_milestone_reached`, `run_completed`) providing cohort tracking and latency metrics.
- **`sensor_data.csv`:**
  High-frequency 100 Hz timeseries logging `recording_id`, `sample_index`, `timestamp_ns`, `activity`, `phone_placement`, raw axes ($a_x, a_y, a_z$), and Euclidean magnitude.
- **`evaluation_summary.csv`:**
  Trial-level performance benchmark comparing predicted steps against 100 ground truth steps for each algorithm variant.

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
