import '../models/experiment_models.dart';

class GroundTruthImport {
  const GroundTruthImport({required this.events, required this.errors});

  final Map<String, List<GroundTruthEvent>> events;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// Parses the documented CSV format without treating detector output as truth.
GroundTruthImport parseGroundTruthCsv(String content) {
  final lines = content
      .replaceFirst('\uFEFF', '')
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    return const GroundTruthImport(events: {}, errors: ['The CSV is empty.']);
  }
  final header = _parseCsvLine(lines.first);
  const required = {
    'recording_id',
    'ground_truth_step_id',
    'ground_truth_timestamp_ns',
  };
  final missing = required.where((name) => !header.contains(name)).toList();
  if (missing.isNotEmpty) {
    return GroundTruthImport(
      events: const {},
      errors: ['Missing required columns: ${missing.join(', ')}.'],
    );
  }
  final index = {for (var i = 0; i < header.length; i++) header[i]: i};
  final imported = <String, List<GroundTruthEvent>>{};
  final errors = <String>[];
  for (var row = 1; row < lines.length; row++) {
    final fields = _parseCsvLine(lines[row]);
    final id = _field(fields, index['recording_id']!);
    final stepId = int.tryParse(_field(fields, index['ground_truth_step_id']!));
    final timestamp = int.tryParse(
      _field(fields, index['ground_truth_timestamp_ns']!),
    );
    if (id.isEmpty || stepId == null || timestamp == null) {
      errors.add(
        'Row ${row + 1} has an invalid recording ID, step ID, or nanosecond timestamp.',
      );
      continue;
    }
    imported
        .putIfAbsent(id, () => [])
        .add(
          GroundTruthEvent(
            id: stepId,
            timestampNs: timestamp,
            notes: index.containsKey('annotation_notes')
                ? _field(fields, index['annotation_notes']!)
                : '',
          ),
        );
  }
  for (final entry in imported.entries) {
    final duplicateIds = <int>{};
    final seen = <int>{};
    for (final event in entry.value) {
      if (!seen.add(event.id)) duplicateIds.add(event.id);
    }
    if (duplicateIds.isNotEmpty) {
      errors.add('Recording ${entry.key} has duplicate ground-truth step IDs.');
    }
  }
  return GroundTruthImport(events: imported, errors: errors);
}

String _field(List<String> fields, int index) =>
    index < fields.length ? fields[index].trim() : '';

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"' && quoted && i + 1 < line.length && line[i + 1] == '"') {
      buffer.write('"');
      i++;
    } else if (char == '"') {
      quoted = !quoted;
    } else if (char == ',' && !quoted) {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString());
  return cells;
}
