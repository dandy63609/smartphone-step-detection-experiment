# Project Brief: Flutter-Based Smartphone Step Detection Experiment

## 1. Your Role

Act as a senior Flutter/Dart engineer with experience in smartphone sensors, real-time signal processing, experimental design, and data collection for applied research.

Build a working, maintainable Flutter application that collects smartphone accelerometer data, detects steps in real time, and compares two adaptive-threshold step-detection algorithms for walking and jogging.

Do not build only a UI mockup. Implement the actual sensor collection, real-time and offline signal-processing pipelines, live step counter UI, recording management, algorithm execution, and simplified CSV export.

Before changing files, inspect the existing repository and environment. Preserve useful existing code, explain your implementation plan, and then implement the application in small, testable stages. If the repository is empty or incomplete, initialize the missing Flutter project structure correctly.

## 2. Research Objective

The experiment investigates whether two adaptive-threshold methods differ in step-detection performance and margin of error under different physical activities and phone placements.

The research questions are:

1. Which threshold algorithm produces better step-detection performance and a lower margin of error against a fixed 100-step ground truth?
2. Does performance change between walking and jogging?
3. Does performance change between hand-held and pocket phone placement?
4. Which configuration provides a good balance between step-count accuracy and computational reliability?

The experiment is a controlled comparison, not an assumption that either algorithm is already superior.

## 3. Experimental Design

Use a factorial experiment with three factors.

### Factor A: Threshold algorithm

**Algorithm A: Adaptive midpoint**

Calculate acceleration magnitude:

$$m(t) = \sqrt{a_x(t)^2 + a_y(t)^2 + a_z(t)^2}$$

Use the recent rolling window of smoothed magnitude values to calculate:

$$T(t) = \frac{\max(\text{window}) + \min(\text{window})}{2}$$

**Algorithm B: Adaptive mean plus standard deviation**

Use the same smoothed magnitude signal and rolling-window duration:

$$T(t) = \text{mean}(\text{window}) + k \cdot \text{standard\_deviation}(\text{window})$$

Make $k$ configurable. Use a clearly documented initial value, such as $k = 1.5$, but do not claim that this value is optimal. Support later parameter sweeps.

For both algorithms, define precisely whether the current sample is included in the threshold window. Do not use future samples to calculate a threshold for a real-time decision.

Both methods must use the same input recordings, smoothing method, window duration, peak-confirmation logic, and minimum step interval during the primary comparison.

### Factor B: Phone placement

- Hand-held (`hand`)
- Pocket (`pocket`)

Record the specific hand or pocket as additional metadata where needed. Standardize the phone orientation and carrying procedure as much as practical.

### Factor C: Activity

- Walking (`walking`)
- Jogging (`jogging`)

This produces eight combinations:

| ID | Activity | Phone placement | Algorithm |
| :--- | :--- | :--- | :--- |
| **E1** | Walking | Hand | Adaptive midpoint |
| **E2** | Walking | Hand | Mean + $k$ standard deviation |
| **E3** | Jogging | Hand | Adaptive midpoint |
| **E4** | Jogging | Hand | Mean + $k$ standard deviation |
| **E5** | Walking | Pocket | Adaptive midpoint |
| **E6** | Walking | Pocket | Mean + $k$ standard deviation |
| **E7** | Jogging | Pocket | Adaptive midpoint |
| **E8** | Jogging | Pocket | Mean + $k$ standard deviation |

### Trial Protocol: Fixed 100-Step Ground Truth

Each trial is standardized to a **true value of exactly 100 physical steps** taken by the participant. Rather than relying solely on a fixed time limit, the participant performs 100 actual steps per trial and manually stops the recording upon completing the 100th step (with an optional fallback timer if needed).

Target five repetitions per combination for an initial pilot, giving 40 physical recordings. Each recording is processed by both algorithms (live and via offline replay), yielding 80 recording-algorithm evaluations. For each evaluation, the true step count (100 steps) is compared directly against the algorithm's detected step count to compute the margin of error.

### Controlled conditions

Keep these constant during the primary comparison:

- **Target step count:** 100 actual steps per trial.
- **Gravity handling:** gravity included (norm of raw accelerometer axes).
- **Accelerometer magnitude calculation:** $m(t) = \sqrt{a_x^2 + a_y^2 + a_z^2}$.
- **Sampling-rate request.**
- **Smoothing filter and parameters.**
- **Adaptive-window duration.**
- **Peak and valley confirmation rules.**
- **Minimum interval between accepted steps.**

Do not silently subtract gravity or switch to a separate sensor representation.

## 4. Technology and Project Structure

Use Flutter and Dart with a clean, understandable architecture.

Recommended logical modules:

- `models/`: experiment configuration, recording metadata, sensor samples, evaluation results.
- `services/`: accelerometer stream, recording storage, simplified CSV export.
- `algorithms/`: common interface, adaptive midpoint, adaptive mean-standard-deviation, shared peak detector state machine.
- `evaluation/`: step count comparison and margin of error calculations out of 100.
- `screens/`: experiment setup, live recording, recording list, recording detail, algorithm comparison, export.
- `tests/`: unit tests and synthetic signal fixtures.

Use a local persistence solution (e.g., SQLite / Hive / local file store) to store raw readings and evaluations while supporting clean CSV exports.

## 5. Experiment Setup Screen

Collect the following parameters before each recording:

- **Participant ID:** pseudonymous identifier (e.g., P01).
- **Activity:** `walking` or `jogging`.
- **Phone placement:** `hand` or `pocket`.
- **Placement detail:** e.g., right hand, front-right pocket.
- **Primary live algorithm:** select which algorithm is displayed live during the trial.
- **Trial number:** 1 through 5 (or higher).
- **Target ground-truth steps:** default to `100 steps`.
- **Recording stop mode:** manual stop after reaching 100 physical steps.
- **Optional notes:** surface or protocol observations.

Automatically generate a unique `recording_id`.

## 6. Recording Workflow

1. Validate configuration parameters.
2. Verify accelerometer stream availability.
3. Show a preparation countdown (e.g., 3-2-1).
4. Start sensor acquisition and real-time step detection.
5. Record timestamps and raw X, Y, Z coordinates.
6. **Live Step Counter & Telemetry:** Increment the live counter by `+1` on each confirmed step with immediate UI feedback (large display, visual pulse, elapsed time, live magnitude graph).
7. Stop when the user completes 100 physical steps and taps "Stop" (confirming the 100 actual steps).
8. Save raw sensor readings and metadata locally.
9. Run both algorithms on the stored samples (ensuring identical offline replay comparison).
10. Calculate margin of error and accuracy against the 100-step baseline, making the summary available for review and CSV export.

## 7. Sensor Data Requirements

Store the raw readings per sample:

- `recording_id`: unique trial string.
- `sample_index`: incrementing sample counter ($0, 1, 2, \dots$).
- `timestamp_ns`: sensor event timestamp (nanoseconds or monotonic converted).
- `ax_mps2`: acceleration along X-axis ($m/s^2$).
- `ay_mps2`: acceleration along Y-axis ($m/s^2$).
- `az_mps2`: acceleration along Z-axis ($m/s^2$).
- `magnitude_mps2`: calculated Euclidean norm $\sqrt{a_x^2 + a_y^2 + a_z^2}$.

## 8. Signal Processing Pipeline

1. **Vector Norm:** Compute magnitude $m(t) = \sqrt{a_x(t)^2 + a_y(t)^2 + a_z(t)^2}$.
2. **Smoothing Filter:** Apply a causal moving average filter (e.g., 3-sample window) using only past and current values.
3. **Adaptive Threshold Calculation:**
   - Midpoint: $T(t) = \frac{\max(\text{window}) + \min(\text{window})}{2}$
   - Mean + $k$ SD: $T(t) = \text{mean}(\text{window}) + k \cdot \text{std}(\text{window})$
4. **Candidate Peak Detection:** Identify local maxima where smoothed magnitude exceeds the dynamic threshold $T(t)$.
5. **Confirmation & Refractory Period:** Enforce minimum inter-step interval (e.g., 250–300 ms) and valley confirmation before accepting the step.
6. **Event Dispatch:** Emit a `+1` event immediately to update the live step counter.

## 9. Real-Time and Offline Evaluation

- **Live Detection:** Real-time stream processing with immediate on-screen counter updates.
- **Offline Replay:** After recording completes, both Algorithm A and Algorithm B run against the exact recorded sample series to guarantee a fair benchmark.
- Both modes use the exact same algorithm code and parameter sets.

## 10. Ground Truth & Error Metrics

Every trial is calibrated against a ground truth of **100 actual steps** ($N_{\text{true}} = 100$):

- **Ground-Truth Step Count ($N_{\text{true}}$):** Fixed at `100`.
- **Predicted Step Count ($N_{\text{predicted}}$):** Total steps registered by the algorithm.
- **Absolute Step Error:**
  $$\text{Absolute Error} = |N_{\text{predicted}} - N_{\text{true}}|$$
- **Percentage Margin of Error (out of 100):**
  $$\text{Margin of Error (\%)} = \left(\frac{|N_{\text{predicted}} - 100|}{100}\right) \times 100\% = |N_{\text{predicted}} - 100|\%$$
  *(Because the ground truth is exactly 100, an error of 3 steps directly corresponds to a 3% margin of error).*
- **Step Count Accuracy (%):**
  $$\text{Accuracy (\%)} = \max\left(0, 100\% - \text{Margin of Error (\%)}\right)$$

---

## 11. Simplified CSV Exports

The export data is streamlined into two targeted CSV files.

### 1. `sensor_data.csv` (High-Frequency Timeseries)

Contains the raw acceleration coordinates and resultant magnitude per sample to allow descriptive statistical verification (mean, min, max, standard deviation per axis) and signal inspection.

**Columns:**
1. `recording_id`: Unique identifier for the trial.
2. `sample_index`: Monotonically increasing sample index ($0, 1, 2, \dots$).
3. `timestamp_ns`: Sensor timestamp in nanoseconds.
4. `activity`: Type of movement (`walking` or `jogging`).
5. `phone_placement`: Phone position (`hand` or `pocket`).
6. `ax_mps2`: Raw X-axis acceleration ($m/s^2$).
7. `ay_mps2`: Raw Y-axis acceleration ($m/s^2$).
8. `az_mps2`: Raw Z-axis acceleration ($m/s^2$).
9. `magnitude_mps2`: Calculated acceleration magnitude appearing alongside X, Y, Z.

**Sample Output:**
```csv
recording_id,sample_index,timestamp_ns,activity,phone_placement,ax_mps2,ay_mps2,az_mps2,magnitude_mps2
REC_20261027_001,0,1729987200000000000,walking,hand,0.12,9.81,1.45,9.917
REC_20261027_001,1,1729987200010000000,walking,hand,0.15,9.85,1.50,9.964
REC_20261027_001,2,1729987200020000000,walking,hand,0.18,9.80,1.48,9.913
```

---

### 2. `evaluation_summary.csv` (Step & Error Summary)

Contains the trial-level performance results, showing step detections compared directly against the 100-step standard, the margin of error, activity, placement, and algorithm used.

**Columns:**
1. `recording_id`: Unique identifier matching `sensor_data.csv`.
2. `trial_number`: Trial iteration index (e.g., 1 to 5).
3. `activity`: Type of movement (`walking` or `jogging`).
4. `phone_placement`: Phone position (`hand` or `pocket`).
5. `algorithm`: Step detection algorithm (`adaptive_midpoint` or `mean_std`).
6. `ground_truth_steps`: Fixed baseline (`100`).
7. `predicted_steps`: Amount of steps detected by the algorithm compared to 100.
8. `absolute_error_steps`: Absolute difference $|N_{\text{predicted}} - 100|$.
9. `percentage_margin_of_error`: Margin of error out of 100 (percentage).

**Sample Output:**
```csv
recording_id,trial_number,activity,phone_placement,algorithm,ground_truth_steps,predicted_steps,absolute_error_steps,percentage_margin_of_error
REC_20261027_001,1,walking,hand,adaptive_midpoint,100,98,2,2.00
REC_20261027_001,1,walking,hand,mean_std,100,103,3,3.00
REC_20261027_002,1,walking,pocket,adaptive_midpoint,100,96,4,4.00
REC_20261027_002,1,walking,pocket,mean_std,100,99,1,1.00
```

---

## 12. UI Screens

1. **Dashboard:** Overview of trials conducted across E1–E8 and direct export options.
2. **Setup Screen:** Selection of activity (`walking`/`jogging`), placement (`hand`/`pocket`), trial number, target ground truth (default: 100), and live algorithm display.
3. **Live Recording Screen:**
   - Large prominent live counter displaying `+1` on each detection.
   - Progress gauge: `Detected: X / Target: 100`.
   - Visual pulse on step confirmation.
   - Live magnitude & threshold chart.
   - Elapsed timer and manual "Stop (100 Steps Completed)" button.
4. **Trial Results & Replay:** Side-by-side comparison of `adaptive_midpoint` vs `mean_std` against the 100-step baseline with margin of error.
5. **Export Screen:** One-tap export/sharing of `sensor_data.csv` and `evaluation_summary.csv`.

## 13. Experimental Integrity & Reproducibility

- Raw sensor readings remain immutable once saved.
- Both algorithms execute on the exact same sample sequence.
- Live detections must be verified against replay results on identical recorded files.
- The 100-step count is adhered to across all experimental conditions (E1 to E8).

## 14. Testing Requirements

- Unit tests for vector magnitude: $\sqrt{x^2 + y^2 + z^2}$.
- Unit tests for rolling window statistics (midpoint, mean, and standard deviation).
- Unit tests for peak detection state machine and refractory lockout.
- Unit tests validating margin of error calculations against $N_{\text{true}} = 100$.
- CSV serialization tests verifying the exact schemas of `sensor_data.csv` and `evaluation_summary.csv`.
- Synthetic 100-peak signal fixtures to ensure algorithm deterministic output.

## 15. Deliverables

1. Full Flutter project source code.
2. Architecture documentation detailing the live stream and offline replay pipelines.
3. The revised CSV schemas (`sensor_data.csv` and `evaluation_summary.csv`).
4. Step-by-step instructions for running the 8-condition pilot on physical Android hardware.