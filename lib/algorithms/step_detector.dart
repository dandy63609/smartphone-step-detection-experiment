import '../models/experiment_models.dart';

enum ThresholdAlgorithm { adaptiveMidpoint, meanPlusStandardDeviation }

class StepDetector {
  StepDetector({
    required this.algorithm,
    this.parameters = const AlgorithmParameters(),
  });

  final ThresholdAlgorithm algorithm;
  final AlgorithmParameters parameters;

  List<DetectionEvent> process(List<SensorSample> samples) {
    if (samples.isEmpty) return const [];
    final smooth = <double>[];
    final detections = <DetectionEvent>[];
    var lastAcceptedNs = -1 << 60;
    for (var i = 0; i < samples.length; i++) {
      final started = DateTime.now().microsecondsSinceEpoch;
      final start = (i - parameters.smoothingSamples + 1).clamp(0, i);
      final values = [
        for (var j = start; j <= i; j++) samples[j].magnitudeMps2,
      ];
      smooth.add(values.reduce((a, b) => a + b) / values.length);
      final windowStart =
          samples[i].timestampNs - parameters.windowDurationMs * 1000000;
      final window = [
        for (var j = 0; j <= i; j++)
          if (samples[j].timestampNs >= windowStart) smooth[j],
      ];
      if (window.length < 2 || i < 2 || i == samples.length - 1) continue;
      final threshold = _threshold(window);
      final isPeak =
          smooth[i - 1] > threshold &&
          smooth[i - 1] >= smooth[i - 2] &&
          smooth[i - 1] > smooth[i];
      final peakTimestamp = samples[i - 1].timestampNs;
      if (isPeak &&
          peakTimestamp - lastAcceptedNs >=
              parameters.minimumStepIntervalMs * 1000000) {
        lastAcceptedNs = peakTimestamp;
        detections.add(
          DetectionEvent(
            detectionId: detections.length,
            peakTimestampNs: peakTimestamp,
            outputTimestampNs: samples[i].timestampNs,
            thresholdMps2: threshold,
            sampleIndex: i - 1,
            processingDurationMicros:
                DateTime.now().microsecondsSinceEpoch - started,
          ),
        );
      }
    }
    return detections;
  }

  double _threshold(List<double> window) {
    if (algorithm == ThresholdAlgorithm.adaptiveMidpoint) {
      final min = window.reduce((a, b) => a < b ? a : b);
      final max = window.reduce((a, b) => a > b ? a : b);
      return (min + max) / 2;
    }
    final mean = window.reduce((a, b) => a + b) / window.length;
    final variance =
        window.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        window.length;
    return mean + parameters.k * _sqrt(variance);
  }

  double _sqrt(double value) {
    if (value == 0) return 0;
    var x = value;
    for (var i = 0; i < 12; i++) {
      x = (x + value / x) / 2;
    }
    return x;
  }
}
