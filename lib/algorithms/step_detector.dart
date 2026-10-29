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

/// Computes `max(window) - min(window)` to detect stationary sensor noise.
double windowSpread(Iterable<double> window) {
  var min = double.infinity;
  var max = double.negativeInfinity;
  for (final v in window) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  if (min == double.infinity || max == double.negativeInfinity) return 0.0;
  return max - min;
}

/// What the detector produced for one input sample.
class DetectorOutput {
  const DetectorOutput({
    required this.sampleIndex,
    required this.timestampNs,
    required this.smoothedMps2,
    required this.thresholdMps2,
    this.isStationary = false,
    this.step,
  });

  final int sampleIndex;
  final int timestampNs;
  final double smoothedMps2;
  final double thresholdMps2;

  /// True when the rolling window's dynamic spread (`max - min`) is below the
  /// stationary noise floor (`minWindowSpreadMps2`), e.g. phone resting on a table.
  final bool isStationary;

  /// Not null when this sample confirmed a step (the peak is one sample back).
  final DetectionEvent? step;
}

class _WindowEntry {
  const _WindowEntry(this.timestampNs, this.value);
  final int timestampNs;
  final double value;
}

/// Streaming adaptive-threshold step detector supporting both Raw Accelerometer
/// (Stream A, with gravity) and User/Linear Accelerometer (Stream B, without gravity).
class StepDetector {
  StepDetector({
    required this.algorithm,
    this.parameters = const AlgorithmParameters(),
    this.useLinearAcceleration = false,
  });

  final ThresholdAlgorithm algorithm;
  final AlgorithmParameters parameters;

  /// When false (A1, B1), uses `sample.magnitudeMps2` (Raw with gravity).
  /// When true (A2, B2), uses `sample.userMagnitudeMps2` (Linear without gravity,
  /// with causal high-pass gravity removal fallback if `ux,uy,uz` were not populated).
  final bool useLinearAcceleration;

  final _rawBuffer = ListQueue<double>();
  var _rawSum = 0.0;
  final _window = ListQueue<_WindowEntry>();

  // Causal low-pass gravity estimate used only when useLinearAcceleration is
  // true and the sample does not carry explicit userAccelerometer coordinates.
  double? _gravityEstimateMps2;

  double? _sPrev2;
  double? _sPrev1;
  double? _tPrev1;
  int? _tsPrev1;
  int? _indexPrev1;
  bool _stationaryPrev1 = true;

  var _armed = true;
  int? _lastStepNs;
  var _stepCount = 0;

  int get stepCount => _stepCount;

  double threshold(Iterable<double> window) =>
      algorithm == ThresholdAlgorithm.adaptiveMidpoint
      ? midpointThreshold(window)
      : meanStdThreshold(window, parameters.k);

  double _extractMagnitude(SensorSample sample) {
    if (!useLinearAcceleration) {
      return sample.magnitudeMps2;
    }
    if (sample.hasLinearReading) {
      return sample.userMagnitudeMps2;
    }
    // Causal gravity-removal fallback when only raw (ax, ay, az) is provided:
    // Estimate baseline gravity via causal IIR filter and isolate dynamic swing.
    final rawMag = sample.magnitudeMps2;
    final prevG = _gravityEstimateMps2;
    final g = prevG == null ? rawMag : (0.98 * prevG + 0.02 * rawMag);
    _gravityEstimateMps2 = g;
    return math.max(0.0, rawMag - g);
  }

  DetectorOutput addSample(SensorSample sample) {
    // 1. Causal moving average.
    final magnitude = _extractMagnitude(sample);
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
      if (isPeak && !_stationaryPrev1 && _armed && intervalOk) {
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
    final values = _window.map((e) => e.value);
    final rawThreshold = threshold(values);
    final spread = windowSpread(values);
    final isStationary = spread < parameters.minWindowSpreadMps2;
    final currentThreshold = isStationary
        ? rawThreshold + (parameters.minWindowSpreadMps2 - spread) * 0.5
        : rawThreshold;

    // 5. Valley confirmation: re-arm once the signal drops below threshold.
    if (smoothed < currentThreshold) _armed = true;

    _sPrev2 = _sPrev1;
    _sPrev1 = smoothed;
    _tPrev1 = currentThreshold;
    _tsPrev1 = sample.timestampNs;
    _indexPrev1 = sample.sampleIndex;
    _stationaryPrev1 = isStationary;

    return DetectorOutput(
      sampleIndex: sample.sampleIndex,
      timestampNs: sample.timestampNs,
      smoothedMps2: smoothed,
      thresholdMps2: currentThreshold,
      isStationary: isStationary,
      step: step,
    );
  }

  /// Offline replay: runs a fresh detector over [samples] in order.
  static List<DetectionEvent> replay(
    List<SensorSample> samples, {
    required ThresholdAlgorithm algorithm,
    AlgorithmParameters parameters = const AlgorithmParameters(),
    bool useLinearAcceleration = false,
  }) {
    final detector = StepDetector(
      algorithm: algorithm,
      parameters: parameters,
      useLinearAcceleration: useLinearAcceleration,
    );
    return [
      for (final sample in samples)
        ?detector.addSample(sample).step,
    ];
  }

  /// Runs both primary algorithms on the raw stream (A1 & B1).
  static Map<ThresholdAlgorithm, List<DetectionEvent>> replayBoth(
    List<SensorSample> samples,
    AlgorithmParameters parameters,
  ) => {
    for (final algorithm in ThresholdAlgorithm.values)
      algorithm: replay(samples, algorithm: algorithm, parameters: parameters),
  };

  /// Runs all 4 algorithm combinations simultaneously (A1, A2, B1, B2) on the
  /// exact same sample sequence (PLANNING.md §2 & §3 Fase 2).
  static Map<AlgorithmVariant, List<DetectionEvent>> replayAllFour(
    List<SensorSample> samples,
    AlgorithmParameters parameters,
  ) => {
    for (final variant in AlgorithmVariant.values)
      variant: replay(
        samples,
        algorithm: variant.thresholdAlgorithm,
        parameters: parameters,
        useLinearAcceleration: variant.usesLinearAcceleration,
      ),
  };
}
