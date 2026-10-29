# System Architecture: Step Detection Experiment

This document details the real-time sensor processing, live telemetry, and offline replay pipeline implemented in the Flutter application.

---

## 1. High-Level Architecture Overview

The application is structured into five cohesive modules following clean architecture principles:

```
lib/
├── models/       # Domain entities, experiment configuration, and data classes
├── algorithms/   # Streaming signal processing and adaptive threshold algorithms
├── evaluation/   # 100-step ground-truth evaluation, accuracy, and condition metrics
├── services/     # Sensor streams, local JSON repository, and CSV export/sharing
└── screens/      # Material 3 UI: Dashboard (E1–E8), Setup, Live Recording, Results, Export
```

---

## 2. Signal Processing Pipeline

The signal processing pipeline executes identically during **Live Streaming** and **Offline Replay**:

```
[Raw Tri-Axial Accelerometer (ax, ay, az)]
                   │
                   ▼
     1. Euclidean Vector Norm (m(t))
        m(t) = sqrt(ax^2 + ay^2 + az^2)   (Gravity retained)
                   │
                   ▼
     2. Causal Moving-Average Filter
        s(t) = (1/N) * sum_{j=0}^{N-1} m(t - j)  (Past & current samples only)
                   │
                   ▼
     3. Adaptive Threshold Computation & Stationary Gate (T(t))
        • Algorithm A (Midpoint): T(t) = [max(window) + min(window)] / 2
        • Algorithm B (Mean + k·SD): T(t) = mean(window) + k * std(window)
        • Stationary Noise Gate: Requires window spread (max - min) >= minWindowSpreadMps2 (1.2 m/s²)
        Window spans [t - windowDurationMs, t] (includes current candidate sample, no future samples)
                   │
                   ▼
     4. Candidate Peak Detection & Valley Confirmation
        • Local Maximum: s[i-1] >= s[i-2] && s[i-1] > s[i] && s[i-1] > T[i-1]
        • Valley Re-arming: Detector requires signal to drop below T(t) before re-arming
        • Refractory Lockout: Requires peak_timestamp - last_step >= minimumStepIntervalMs (250 ms)
                   │
                   ▼
     5. Dispatch Confirmed Step Event (+1)
```

---

## 3. Real-Time vs. Offline Replay Equivalence

A core requirement of the experimental design (AGENTS.md §9 & §13) is guaranteeing that live detections and offline benchmark replay yield identical, reproducible results:

1. **Deterministic State Machine:** `StepDetector` operates sample-by-sample without wall-clock time dependency. Hardware sensor timestamps (`timestamp_ns`) drive the rolling window boundaries.
2. **Replay Validation:** Upon completing a trial, the raw sensor timeseries is replayed through both algorithms using `StepDetector.replayBoth()`.
3. **Integrity Check:** The Results screen automatically verifies that the live step count matches the replay step count for the active algorithm (`liveStepCount == replayCount`), visually confirming experimental validity.

---

## 4. Data Persistence & CSV Exports

All raw readings and metadata are stored immutably in local app storage:

- **Local Storage (`FileRecordingStore`):** Saves each trial as an immutable JSON file (`REC_YYYYMMDD_NNN.json`). Overwriting existing files is forbidden by design.
- **`sensor_data.csv` (High-Frequency Timeseries):**
  `recording_id,sample_index,timestamp_ns,activity,phone_placement,ax_mps2,ay_mps2,az_mps2,magnitude_mps2`
- **`evaluation_summary.csv` (100-Step Trial Summaries):**
  `recording_id,trial_number,activity,phone_placement,algorithm,ground_truth_steps,predicted_steps,absolute_error_steps,percentage_margin_of_error`
