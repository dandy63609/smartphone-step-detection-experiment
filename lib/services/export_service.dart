import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';
import 'csv_export.dart';

/// Writes and shares `sensor_data.csv`, `sensor_linear_data.csv`, and
/// `evaluation_summary.csv` (covering all 4 algorithm combinations A1, A2, B1, B2).
class ExportService {
  Future<List<File>> writeCsvFiles(List<SavedRecording> recordings) async {
    final base = await getApplicationDocumentsDirectory();
    final folder = Directory('${base.path}/step_exports');
    await folder.create(recursive: true);
    final ordered = [...recordings]
      ..sort((a, b) => a.recordingId.compareTo(b.recordingId));

    final sensorFile = File('${folder.path}/sensor_data.csv');
    await sensorFile.writeAsString(sensorDataCsv(ordered), flush: true);

    final linearFile = File('${folder.path}/sensor_linear_data.csv');
    await linearFile.writeAsString(sensorDualStreamCsv(ordered), flush: true);

    final summaryFile = File('${folder.path}/evaluation_summary.csv');
    await summaryFile.writeAsString(
      evaluationSummaryCsv([
        for (final r in ordered) ...evaluateRecordingAllFour(r),
      ]),
      flush: true,
    );
    return [sensorFile, linearFile, summaryFile];
  }

  Future<void> share(List<File> files) => SharePlus.instance.share(
    ShareParams(
      files: [for (final f in files) XFile(f.path, mimeType: 'text/csv')],
      subject: 'Step detection experiment export',
    ),
  );
}
