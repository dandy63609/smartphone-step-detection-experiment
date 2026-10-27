import 'dart:collection';
import 'dart:math' as math;

import '../models/experiment_models.dart';

/// Algorithm A: T = (max(window) + min(window)) / 2
double midpointThreshold(Iterable<double> window) {
  var min = double.infinity;
  var max = double.negativeInfinity;
  for (final v in window) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  return (max + min) / 2;
}

/// Algorithm B: T = mean(window) + k · sd(window)
///
/// Uses the population standard deviation (divide by n).
double meanStdThreshold(Iterable<double> window, double k) {
  var n = 0;
  var sum = 0.0;
  for (final v in window) {
    n++;
    sum += v;
  }
  final mean = sum / n;
  var squares = 0.0;
  for (final v in window) {
    squares += (v - mean) * (v - mean);
  }
  return mean + k * math.sqrt(squares / n);
}

/// What the detector produced for one input sample.
class DetectorOutput {
  const DetectorOutput({
    required this.sampleIndex,
    required this.timestampNs,
    required this.smoothedMps2,
    required this.thresholdMps2,
    this.step,
  });

  final int sampleIndex;
  final int timestampNs;
  final double smoothedMps2;
  final double thresholdMps2;

  /// Not null when this sample confirmed a step (the peak is one sample back).
  final DetectionEvent? step;
}

class _WindowEntry {
  const _WindowEntry(this.timestampNs, this.value);
  final int timestampNs;
  final double value;
}

/// Streaming adaptive-threshold step detector. The live screen and the
/// offline replay both use this class, so they share the same code.
///
/// For each new sample `i`:
/// 1. **Smoothing:** causal moving average of the last
///    `smoothingSamples` magnitudes (past and current only).
/// 2. **Peak candidate:** sample `i-1` is a local maximum when
///    `s[i-2] <= s[i-1] > s[i]`. Sample `i` is used only to confirm the
///    maximum; it is never part of the threshold window for `i-1`.
/// 3. **Threshold window:** `T[i-1]` is computed from smoothed values with
///    timestamps in `[t[i-1] - windowDurationMs, t[i-1]]`. The window
///    **includes the candidate sample** and no later samples, so no future
///    samples are used.
/// 4. **Acceptance:** the candidate becomes a step when
///    `s[i-1] > T[i-1]`, the detector is armed (valley confirmed), and at
///    least `minimumStepIntervalMs` has passed since the previous step.
/// 5. **Valley confirmation:** after a step is accepted the detector is
///    disarmed. It re-arms when a smoothed sample falls below its own
///    threshold, so two steps always have a valley between them. The
///    detector starts armed because there is no previous step.
class StepDetector {
  StepDetector({
    required this.algorithm,
    this.parameters = const AlgorithmParameters(),
  });

  final ThresholdAlgorithm algorithm;
  final AlgorithmParameters parameters;

  final _rawBuffer = ListQueue<double>();
  var _rawSum = 0.0;
  final _window = ListQueue<_WindowEntry>();

  double? _sPrev2;
  double? _sPrev1;
  double? _tPrev1;
  int? _tsPrev1;
  int? _indexPrev1;

  var _armed = true;
  int? _lastStepNs;
  var _stepCount = 0;

  int get stepCount => _stepCount;

  double threshold(Iterable<double> window) =>
      algorithm == ThresholdAlgorithm.adaptiveMidpoint
      ? midpointThreshold(window)
      : meanStdThreshold(window, parameters.k);

  DetectorOutput addSample(SensorSample sample) {
    // 1. Causal moving average.
    final magnitude = sample.magnitudeMps2;
    _rawBuffer.addLast(magnitude);
    _rawSum += magnitude;
    if (_rawBuffer.length > parameters.smoothingSamples) {
      _rawSum -= _rawBuffer.removeFirst();
    }
    final smoothed = _rawSum / _rawBuffer.length;

    // 2-4. Decide on the candidate at i-1 using T[i-1] (computed before s[i]
    // was in the window).
    DetectionEvent? step;
    final sPrev1 = _sPrev1;
    final sPrev2 = _sPrev2;
    final tPrev1 = _tPrev1;
    final tsPrev1 = _tsPrev1;
    if (sPrev1 != null && sPrev2 != null && tPrev1 != null && tsPrev1 != null) {
      final isPeak = sPrev1 >= sPrev2 && sPrev1 > smoothed && sPrev1 > tPrev1;
      final intervalOk =
          _lastStepNs == null ||
          tsPrev1 - _lastStepNs! >= parameters.minimumStepIntervalMs * 1000000;
      if (isPeak && _armed && intervalOk) {
        step = DetectionEvent(
          detectionId: _stepCount,
          sampleIndex: _indexPrev1!,
          peakTimestampNs: tsPrev1,
          outputTimestampNs: sample.timestampNs,
          thresholdMps2: tPrev1,
        );
        _stepCount++;
        _lastStepNs = tsPrev1;
        _armed = false;
      }
    }

    // 3. Add s[i] to the window, drop old values, and compute T[i].
    _window.addLast(_WindowEntry(sample.timestampNs, smoothed));
    final windowStart =
        sample.timestampNs - parameters.windowDurationMs * 1000000;
    while (_window.first.timestampNs < windowStart) {
      _window.removeFirst();
    }
    final currentThreshold = threshold(_window.map((e) => e.value));

    // 5. Valley confirmation: re-arm once the signal drops below threshold.
    if (smoothed < currentThreshold) _armed = true;

    _sPrev2 = _sPrev1;
    _sPrev1 = smoothed;
    _tPrev1 = currentThreshold;
    _tsPrev1 = sample.timestampNs;
    _indexPrev1 = sample.sampleIndex;

    return DetectorOutput(
      sampleIndex: sample.sampleIndex,
      timestampNs: sample.timestampNs,
      smoothedMps2: smoothed,
      thresholdMps2: currentThreshold,
      step: step,
    );
  }

  /// Offline replay: runs a fresh detector over [samples] in order.
  static List<DetectionEvent> replay(
    List<SensorSample> samples, {
    required ThresholdAlgorithm algorithm,
    AlgorithmParameters parameters = const AlgorithmParameters(),
  }) {
    final detector = StepDetector(algorithm: algorithm, parameters: parameters);
    return [
      for (final sample in samples)
        ?detector.addSample(sample).step,
    ];
  }

  /// Runs both algorithms on the same samples for the primary comparison.
  static Map<ThresholdAlgorithm, List<DetectionEvent>> replayBoth(
    List<SensorSample> samples,
    AlgorithmParameters parameters,
  ) => {
    for (final algorithm in ThresholdAlgorithm.values)
      algorithm: replay(samples, algorithm: algorithm, parameters: parameters),
  };
}
