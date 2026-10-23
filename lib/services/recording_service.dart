import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/experiment_models.dart';
import 'csv_export.dart';

class RecordingService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _stopwatch = Stopwatch();
  final _samples = <SensorSample>[];
  String? _recordingId;

  bool get isRecording => _subscription != null;
  List<SensorSample> get samples => List.unmodifiable(_samples);

  Future<void> start(
    String recordingId, {
    Duration interval = SensorInterval.normalInterval,
  }) async {
    if (isRecording) throw StateError('A recording is already active.');
    _recordingId = recordingId;
    _samples.clear();
    _stopwatch
      ..reset()
      ..start();
    _subscription = accelerometerEventStream(samplingPeriod: interval)
        .listen((event) {
          final id = _recordingId;
          if (id == null) return;
          _samples.add(
            SensorSample(
              recordingId: id,
              sampleIndex: _samples.length,
              timestampNs: _stopwatch.elapsedMicroseconds * 1000,
              axMps2: event.x,
              ayMps2: event.y,
              azMps2: event.z,
            ),
          );
        });
  }

  Future<List<SensorSample>> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _stopwatch.stop();
    return samples;
  }

  Future<File> saveJson(
    ExperimentConfig config,
    List<SensorSample> samples,
    Map<String, List<DetectionEvent>> detections,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingId = samples.isEmpty ? 'empty' : samples.first.recordingId;
    final file = File('${directory.path}/step_recordings/$recordingId.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'recording_id': recordingId,
        'participant_id': config.participantId,
        'activity': config.activity.value,
        'phone_placement': config.phonePlacement.value,
        'placement_detail': config.placementDetail,
        'trial_number': config.trialNumber,
        'duration_seconds': config.durationSeconds,
        'notes': config.notes,
        'requested_sampling_rate_hz': config.requestedSamplingRateHz,
        'algorithm_parameters': config.parameters.toMap(),
        'algorithm_results': {
          for (final entry in detections.entries)
            entry.key: [
              for (final event in entry.value)
                {
                  'detection_id': event.detectionId,
                  'peak_timestamp_ns': event.peakTimestampNs,
                  'output_timestamp_ns': event.outputTimestampNs,
                  'threshold_mps2': event.thresholdMps2,
                  'sample_index': event.sampleIndex,
                  'processing_duration_micros': event.processingDurationMicros,
                },
            ],
        },
        'samples': [
          for (final sample in samples)
            {
              'sample_index': sample.sampleIndex,
              'timestamp_ns': sample.timestampNs,
              'ax_mps2': sample.axMps2,
              'ay_mps2': sample.ayMps2,
              'az_mps2': sample.azMps2,
              'magnitude_mps2': sample.magnitudeMps2,
            },
        ],
      }),
    );
    return file;
  }

  Future<Directory> exportCsvPackage({
    required List<SensorSample> samples,
    required Map<String, List<DetectionEvent>> detections,
    required AlgorithmParameters parameters,
    List<EvaluationResult> evaluations = const [],
  }) async {
    final base = await getApplicationDocumentsDirectory();
    final id = samples.isEmpty ? 'empty' : samples.first.recordingId;
    final folder = Directory('${base.path}/step_exports/$id');
    await folder.create(recursive: true);
    await File('${folder.path}/sensor_data.csv')
        .writeAsString(sensorCsv(samples));
    final allEvents = <String>[];
    for (final entry in detections.entries) {
      allEvents.add(
        detectedStepsCsv(
          recordingId: id,
          algorithm: entry.key,
          detections: entry.value,
          parameters: parameters,
        ),
      );
    }
    final detectionLines = allEvents.isEmpty
        ? 'recording_id,algorithm,detection_id,peak_timestamp_ns,output_timestamp_ns,threshold_at_detection_mps2,processing_duration_ms,sample_index,algorithm_parameters\n'
        : '${allEvents.first.split('\n').first}\n${allEvents.map((csv) => csv.split('\n').skip(1).where((line) => line.isNotEmpty).join('\n')).where((part) => part.isNotEmpty).join('\n')}\n';
    await File('${folder.path}/detected_steps.csv')
        .writeAsString(detectionLines);
    await File('${folder.path}/evaluation_results.csv')
        .writeAsString(evaluationCsv(evaluations));
    return folder;
  }

  Future<void> dispose() async => _subscription?.cancel();
}
