# Smartphone Step Detection Experiment

A Flutter/Dart Android application for collecting smartphone accelerometer data
and comparing two adaptive-threshold step-detection algorithms.

## Research objective

The experiment compares:

1. **Adaptive midpoint:** `(rolling maximum + rolling minimum) / 2`
2. **Mean plus standard deviation:** `rolling mean + k × rolling standard deviation`

Both algorithms must process the same raw recordings, smoothing pipeline, peak
rules, adaptive-window duration, and minimum step interval.

The initial pilot covers two activities (walking and jogging) and two phone
placements (hand-held and pocket), with five configurable repetitions per
condition. The pilot is exploratory and does not establish statistical
significance.

## Planned capabilities

- Record raw accelerometer X/Y/Z values with monotonic timestamps.
- Preserve raw magnitude data and measure actual sampling intervals.
- Replay each recording through both algorithms offline.
- Import manually annotated ground-truth step timestamps.
- Calculate event, count, latency, and processing metrics.
- Export sensor data, detections, ground truth, and evaluation results as CSV.
- Keep raw recordings immutable and record the exact parameters used.

## Scope rules

This project is local-first. It does not require accounts, backend services,
cloud uploads, payments, GPS, or analytics. Gravity remains included in the
initial raw-magnitude experiment. Audio playback, cadence prediction,
Kotlin/native implementations, and complex ML are deferred until the sensor
and detection pipeline are validated on a physical Android phone.

## Current status

The repository contains the Flutter application scaffold. The next milestone
is a minimal end-to-end pipeline:

1. Configure a recording.
2. Capture and save accelerometer samples.
3. Replay both algorithms over identical samples.
4. Save results and export the required CSV files.

Do not treat placeholder UI values or synthetic signals as experimental
results.

## Development

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Use a physical Android phone for sensor validation. Emulator tests and
synthetic signal tests are useful for software logic but cannot replace real
walking and jogging recordings.

See `AGENTS.en.md` for the English engineering and experiment-integrity rules.
