import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/experiment_models.dart';

class RecordingRepository {
  Future<List<SavedRecording>> list() async {
    final directory = await _directory();
    if (!await directory.exists()) {
      return const [];
    }
    final recordings = <SavedRecording>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      try {
        recordings.add(fromJson(await entity.readAsString()));
      } on FormatException {
        // Ignore malformed files; raw data is never overwritten.
      }
    }
    recordings.sort((a, b) => b.recordingId.compareTo(a.recordingId));
    return recordings;
  }

  Future<SavedRecording> load(String recordingId) async {
    final directory = await _directory();
    final file = File('${directory.path}/$recordingId.json');
    if (!await file.exists()) {
      throw StateError('Recording $recordingId was not found.');
    }
    return fromJson(await file.readAsString());
  }

  Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/step_recordings');
  }

  SavedRecording fromJson(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Recording JSON must be an object.');
    }
    String text(String key) => root[key]?.toString() ?? '';
    int number(String key) => (root[key] as num?)?.toInt() ?? 0;
    final id = text('recording_id');
    if (id.isEmpty) {
      throw const FormatException('Recording ID is missing.');
    }
    final samples = <SensorSample>[
      for (final row in (root['samples'] as List? ?? const []))
        if (row is Map<String, dynamic>)
          SensorSample(
            recordingId: id,
            sampleIndex: (row['sample_index'] as num?)?.toInt() ?? 0,
            timestampNs: (row['timestamp_ns'] as num?)?.toInt() ?? 0,
            axMps2: (row['ax_mps2'] as num?)?.toDouble() ?? 0,
            ayMps2: (row['ay_mps2'] as num?)?.toDouble() ?? 0,
            azMps2: (row['az_mps2'] as num?)?.toDouble() ?? 0,
          ),
    ];
    final detections = <String, List<DetectionEvent>>{};
    final results = root['algorithm_results'];
    if (results is Map<String, dynamic>) {
      for (final entry in results.entries) {
        final rows = entry.value as List? ?? const [];
        detections[entry.key] = [
          for (final row in rows)
            if (row is Map<String, dynamic>)
              DetectionEvent(
                detectionId: (row['detection_id'] as num?)?.toInt() ?? 0,
                peakTimestampNs:
                    (row['peak_timestamp_ns'] as num?)?.toInt() ?? 0,
                outputTimestampNs:
                    (row['output_timestamp_ns'] as num?)?.toInt() ?? 0,
                thresholdMps2: (row['threshold_mps2'] as num?)?.toDouble() ?? 0,
                sampleIndex: (row['sample_index'] as num?)?.toInt() ?? 0,
                processingDurationMicros:
                    (row['processing_duration_micros'] as num?)?.toInt() ?? 0,
              ),
        ];
      }
    }
    return SavedRecording(
      recordingId: id,
      participantId: text('participant_id'),
      activity: text('activity'),
      phonePlacement: text('phone_placement'),
      placementDetail: text('placement_detail'),
      trialNumber: number('trial_number'),
      durationSeconds: number('duration_seconds'),
      samples: samples,
      detections: detections,
    );
  }
}
