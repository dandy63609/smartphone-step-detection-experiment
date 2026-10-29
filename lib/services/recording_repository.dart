import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/experiment_models.dart';

/// Builds the next `REC_YYYYMMDD_NNN` ID for [date], continuing from the
/// IDs already used that day.
String nextRecordingId(Iterable<String> existingIds, DateTime date) {
  final day =
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
  final pattern = RegExp('^REC_${day}_(\\d{3,})\$');
  var highest = 0;
  for (final id in existingIds) {
    final match = pattern.firstMatch(id);
    if (match != null) {
      final n = int.parse(match.group(1)!);
      if (n > highest) highest = n;
    }
  }
  return 'REC_${day}_${(highest + 1).toString().padLeft(3, '0')}';
}

String recordingToJson(SavedRecording recording) => jsonEncode({
  'recording_id': recording.recordingId,
  'created_at': recording.createdAt.toIso8601String(),
  'config': recording.config.toMap(),
  'live_step_count': recording.liveStepCount,
  'replay_detections': {
    for (final entry in recording.replayDetections.entries)
      entry.key.value: [for (final e in entry.value) e.toMap()],
  },
  'replay_variant_detections': {
    for (final entry in recording.replayVariantDetections.entries)
      entry.key.value: [for (final e in entry.value) e.toMap()],
  },
  'samples': [for (final s in recording.samples) s.toMap()],
});

SavedRecording recordingFromJson(String source) {
  final root = jsonDecode(source);
  if (root is! Map<String, dynamic>) {
    throw const FormatException('Recording JSON must be an object.');
  }
  final id = root['recording_id']?.toString() ?? '';
  if (id.isEmpty) throw const FormatException('Recording ID is missing.');
  final config = root['config'];
  if (config is! Map<String, dynamic>) {
    throw const FormatException('Recording config is missing.');
  }
  final replay = <ThresholdAlgorithm, List<DetectionEvent>>{};
  final rawReplay = root['replay_detections'];
  if (rawReplay is Map<String, dynamic>) {
    for (final entry in rawReplay.entries) {
      replay[ThresholdAlgorithmLabel.parse(entry.key)] = [
        for (final row in entry.value as List)
          DetectionEvent.fromMap(row as Map<String, dynamic>),
      ];
    }
  }
  final variantReplay = <AlgorithmVariant, List<DetectionEvent>>{};
  final rawVariantReplay = root['replay_variant_detections'];
  if (rawVariantReplay is Map<String, dynamic>) {
    for (final entry in rawVariantReplay.entries) {
      variantReplay[AlgorithmVariantLabel.parse(entry.key)] = [
        for (final row in entry.value as List)
          DetectionEvent.fromMap(row as Map<String, dynamic>),
      ];
    }
  }
  return SavedRecording(
    recordingId: id,
    createdAt:
        DateTime.tryParse(root['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    config: ExperimentConfig.fromMap(config),
    liveStepCount: (root['live_step_count'] as num?)?.toInt() ?? 0,
    replayDetections: replay,
    replayVariantDetections: variantReplay,
    samples: [
      for (final row in (root['samples'] as List? ?? const []))
        SensorSample.fromMap(id, row as Map<String, dynamic>),
    ],
  );
}

/// Local persistence for recordings.
abstract class RecordingStore {
  Future<List<SavedRecording>> list();

  /// Saves a new recording. Fails if the ID already exists, so raw data is
  /// never overwritten.
  Future<void> save(SavedRecording recording);

  Future<String> nextId(DateTime date);
}

/// Stores each recording as a JSON file in the app documents folder.
class FileRecordingStore implements RecordingStore {
  FileRecordingStore({Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/step_recordings');
  }

  @override
  Future<List<SavedRecording>> list() async {
    final directory = await _directory();
    if (!await directory.exists()) return const [];
    final recordings = <SavedRecording>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        recordings.add(recordingFromJson(await entity.readAsString()));
      } on Object {
        // Skip unreadable files; they are left untouched on disk.
      }
    }
    recordings.sort((a, b) => b.recordingId.compareTo(a.recordingId));
    return recordings;
  }

  @override
  Future<void> save(SavedRecording recording) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/${recording.recordingId}.json');
    if (await file.exists()) {
      throw StateError(
        'Recording ${recording.recordingId} already exists; '
        'raw recordings are immutable.',
      );
    }
    await file.writeAsString(recordingToJson(recording), flush: true);
  }

  @override
  Future<String> nextId(DateTime date) async {
    final directory = await _directory();
    if (!await directory.exists()) return nextRecordingId(const [], date);
    final ids = <String>[
      await for (final entity in directory.list())
        if (entity is File && entity.path.endsWith('.json'))
          entity.uri.pathSegments.last.replaceAll('.json', ''),
    ];
    return nextRecordingId(ids, date);
  }
}
