import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/experiment_models.dart';

/// Reads the raw accelerometer (gravity included) and turns events into
/// [SensorSample]s.
class RecordingService {
  RecordingService({Stream<AccelerometerEvent> Function(Duration)? source})
    : _source =
          source ??
          ((interval) => accelerometerEventStream(samplingPeriod: interval));

  final Stream<AccelerometerEvent> Function(Duration) _source;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _samples = <SensorSample>[];
  int? _lastTimestampNs;

  bool get isRecording => _subscription != null;
  List<SensorSample> get samples => List.unmodifiable(_samples);

  /// Returns true when an accelerometer event arrives within [timeout].
  Future<bool> isAccelerometerAvailable({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      await _source(SensorInterval.normalInterval).first.timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }

  /// Starts recording and calls [onSample] for every new sample.
  void start(
    String recordingId, {
    required double samplingRateHz,
    required void Function(SensorSample sample) onSample,
    void Function(Object error)? onError,
  }) {
    if (isRecording) throw StateError('A recording is already active.');
    _samples.clear();
    _lastTimestampNs = null;
    final interval = Duration(microseconds: (1000000 / samplingRateHz).round());
    _subscription = _source(interval).listen((event) {
      // Hardware sensor timestamp (Android: SensorEvent.timestamp plus a fixed
      // boot offset), stored in nanoseconds. It is forced to increase strictly
      // so the time window works correctly.
      var timestampNs = event.timestamp.microsecondsSinceEpoch * 1000;
      final last = _lastTimestampNs;
      if (last != null && timestampNs <= last) timestampNs = last + 1;
      _lastTimestampNs = timestampNs;
      final sample = SensorSample(
        recordingId: recordingId,
        sampleIndex: _samples.length,
        timestampNs: timestampNs,
        axMps2: event.x,
        ayMps2: event.y,
        azMps2: event.z,
      );
      _samples.add(sample);
      onSample(sample);
    }, onError: (Object error) => onError?.call(error));
  }

  Future<List<SensorSample>> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    return samples;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
