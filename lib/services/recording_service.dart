import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/experiment_models.dart';

/// Reads both Stream A (Raw Accelerometer with gravity) and Stream B
/// (User Accelerometer / Linear without gravity) in parallel and turns events
/// into synchronized [SensorSample]s.
class RecordingService {
  RecordingService({
    Stream<AccelerometerEvent> Function(Duration)? source,
    Stream<UserAccelerometerEvent> Function(Duration)? userSource,
  }) : _source =
           source ??
           ((interval) => accelerometerEventStream(samplingPeriod: interval)),
       _userSource =
           userSource ??
           ((interval) =>
               userAccelerometerEventStream(samplingPeriod: interval));

  final Stream<AccelerometerEvent> Function(Duration) _source;
  final Stream<UserAccelerometerEvent> Function(Duration) _userSource;

  StreamSubscription<AccelerometerEvent>? _subscription;
  StreamSubscription<UserAccelerometerEvent>? _userSubscription;
  final _samples = <SensorSample>[];
  int? _lastTimestampNs;

  // Latest linear acceleration from Stream B (userAccelerometerEventStream)
  double _latestUx = 0.0;
  double _latestUy = 0.0;
  double _latestUz = 0.0;
  bool _hasUserEvent = false;

  // Causal low-pass gravity estimate fallback if the device/mock does not emit UserAccelerometerEvents
  double _gx = 0.0;
  double _gy = 0.0;
  double _gz = 0.0;
  bool _gravityInitialized = false;

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

  /// Starts dual-stream recording and calls [onSample] for every new sample.
  void start(
    String recordingId, {
    required double samplingRateHz,
    required void Function(SensorSample sample) onSample,
    void Function(Object error)? onError,
  }) {
    if (isRecording) throw StateError('A recording is already active.');
    _samples.clear();
    _lastTimestampNs = null;
    _latestUx = 0.0;
    _latestUy = 0.0;
    _latestUz = 0.0;
    _hasUserEvent = false;
    _gravityInitialized = false;

    final interval = Duration(microseconds: (1000000 / samplingRateHz).round());

    // Subscribe to Stream B (User Accelerometer without gravity) in parallel.
    try {
      _userSubscription = _userSource(interval).listen(
        (userEvent) {
          _latestUx = userEvent.x;
          _latestUy = userEvent.y;
          _latestUz = userEvent.z;
          _hasUserEvent = true;
        },
        onError: (_) {
          // If hardware lacks a virtual linear sensor, fallback filter handles it.
        },
      );
    } on Object {
      // Ignore if unavailable in test environment.
    }

    // Subscribe to Stream A (Raw Accelerometer with gravity) as the primary clock.
    _subscription = _source(interval).listen((event) {
      var timestampNs = event.timestamp.microsecondsSinceEpoch * 1000;
      final last = _lastTimestampNs;
      if (last != null && timestampNs <= last) timestampNs = last + 1;
      _lastTimestampNs = timestampNs;

      // Update causal low-pass gravity estimate (alpha = 0.8) for fallback
      if (!_gravityInitialized) {
        _gx = event.x;
        _gy = event.y;
        _gz = event.z;
        _gravityInitialized = true;
      } else {
        const alpha = 0.8;
        _gx = alpha * _gx + (1 - alpha) * event.x;
        _gy = alpha * _gy + (1 - alpha) * event.y;
        _gz = alpha * _gz + (1 - alpha) * event.z;
      }

      final ux = _hasUserEvent ? _latestUx : (event.x - _gx);
      final uy = _hasUserEvent ? _latestUy : (event.y - _gy);
      final uz = _hasUserEvent ? _latestUz : (event.z - _gz);

      final sample = SensorSample(
        recordingId: recordingId,
        sampleIndex: _samples.length,
        timestampNs: timestampNs,
        axMps2: event.x,
        ayMps2: event.y,
        azMps2: event.z,
        uxMps2: ux,
        uyMps2: uy,
        uzMps2: uz,
      );
      _samples.add(sample);
      onSample(sample);
    }, onError: (Object error) => onError?.call(error));
  }

  Future<List<SensorSample>> stop() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _subscription?.cancel();
    _subscription = null;
    return samples;
  }

  Future<void> dispose() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
