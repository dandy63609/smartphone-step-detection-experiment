import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'algorithms/step_detector.dart';
import 'evaluation/event_matcher.dart';
import 'models/experiment_models.dart';
import 'services/ground_truth_csv.dart';
import 'services/recording_repository.dart';
import 'services/recording_service.dart';

void main() {
  runApp(const StepDetectionApp());
}

class StepDetectionApp extends StatelessWidget {
  const StepDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Detection Experiment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ExperimentHomePage(),
    );
  }
}

class ExperimentHomePage extends StatefulWidget {
  const ExperimentHomePage({super.key});

  @override
  State<ExperimentHomePage> createState() => _ExperimentHomePageState();
}

class _ExperimentHomePageState extends State<ExperimentHomePage> {
  final _recordingService = RecordingService();
  final _participantController = TextEditingController(text: 'P01');
  final _placementController = TextEditingController(
    text: 'front-right pocket',
  );
  final _trialController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '60');
  final _notesController = TextEditingController();
  final _samplingRateController = TextEditingController(text: '100');
  final _smoothingController = TextEditingController(text: '3');
  final _windowController = TextEditingController(text: '1000');
  final _minimumIntervalController = TextEditingController(text: '250');
  final _kController = TextEditingController(text: '1.5');
  Activity _activity = Activity.walking;
  PhonePlacement _phonePlacement = PhonePlacement.pocket;
  Timer? _refreshTimer;
  Timer? _stopTimer;
  bool _recording = false;
  String _status = 'Ready for a physical-device recording.';
  int _sampleCount = 0;
  String? _lastRecordingId;
  Map<String, List<DetectionEvent>> _lastDetections = const {};
  List<SensorSample> _selectedSamples = const [];

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _stopTimer?.cancel();
    _recordingService.dispose();
    _participantController.dispose();
    _placementController.dispose();
    _trialController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _samplingRateController.dispose();
    _smoothingController.dispose();
    _windowController.dispose();
    _minimumIntervalController.dispose();
    _kController.dispose();
    super.dispose();
  }

  ExperimentConfig _config() => ExperimentConfig(
    participantId: _participantController.text.trim(),
    activity: _activity,
    phonePlacement: _phonePlacement,
    placementDetail: _placementController.text.trim(),
    trialNumber: int.tryParse(_trialController.text) ?? 0,
    durationSeconds: int.tryParse(_durationController.text) ?? 0,
    notes: _notesController.text.trim(),
    requestedSamplingRateHz: double.tryParse(_samplingRateController.text) ?? 0,
    parameters: AlgorithmParameters(
      smoothingSamples: int.tryParse(_smoothingController.text) ?? 0,
      windowDurationMs: int.tryParse(_windowController.text) ?? 0,
      minimumStepIntervalMs: int.tryParse(_minimumIntervalController.text) ?? 0,
      k: double.tryParse(_kController.text) ?? -1,
    ),
  );

  Future<void> _finishRecording() async {
    if (!_recording) return;
    _refreshTimer?.cancel();
    _stopTimer?.cancel();
    final config = _config();
    final samples = await _recordingService.stop();
    final parameters = config.parameters;
    final detections = <String, List<DetectionEvent>>{
      'adaptive_midpoint': StepDetector(
        algorithm: ThresholdAlgorithm.adaptiveMidpoint,
        parameters: parameters,
      ).process(samples),
      'mean_plus_standard_deviation': StepDetector(
        algorithm: ThresholdAlgorithm.meanPlusStandardDeviation,
        parameters: parameters,
      ).process(samples),
    };
    await _recordingService.saveJson(config, samples, detections);
    final exportDirectory = await _recordingService.exportCsvPackage(
      samples: samples,
      detections: detections,
      parameters: parameters,
    );
    if (!mounted) return;
    setState(() {
      _recording = false;
      _sampleCount = samples.length;
      _lastRecordingId = samples.isEmpty ? null : samples.first.recordingId;
      _lastDetections = detections;
      _selectedSamples = samples;
      _status =
          'Saved ${samples.length} samples and both result sets. CSV package: ${exportDirectory.path}';
    });
  }

  Future<void> _importGroundTruth() async {
    final recordingId = _lastRecordingId;
    if (recordingId == null || _lastDetections.isEmpty) {
      setState(
        () => _status =
            'Record and process a session before importing its ground truth.',
      );
      return;
    }
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (selected == null) return;
    final content = utf8.decode(await selected.readAsBytes());
    final imported = parseGroundTruthCsv(content);
    final errors = [...imported.errors];
    final events = imported.events[recordingId];
    if (events == null) {
      errors.add('No ground-truth rows match recording ID $recordingId.');
    }
    if (errors.isNotEmpty) {
      if (!mounted) return;
      setState(() => _status = 'Import rejected: ${errors.join(' ')}');
      return;
    }
    final groundTruthEvents = events!;
    const toleranceMs = 150;
    final results = [
      for (final entry in _lastDetections.entries)
        evaluateDetections(
          recordingId: recordingId,
          algorithm: entry.key,
          detections: entry.value,
          groundTruth: groundTruthEvents,
          matchingToleranceMs: toleranceMs,
        ),
    ];
    final exportDirectory = await _recordingService.exportCsvPackage(
      samples: _selectedSamples,
      detections: _lastDetections,
      parameters: _config().parameters,
      evaluations: results,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EvaluationResultsPage(results: results),
      ),
    );
    if (!mounted) return;
    setState(
      () => _status =
          'Imported ${groundTruthEvents.length} ground-truth steps. Updated: ${exportDirectory.path}',
    );
  }

  Future<void> _openRecordings() async {
    final selected = await Navigator.of(context).push<SavedRecording>(
      MaterialPageRoute<SavedRecording>(
        builder: (_) => const RecordingListPage(),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _lastRecordingId = selected.recordingId;
      _lastDetections = selected.detections;
      _selectedSamples = selected.samples;
      _sampleCount = selected.samples.length;
      _status =
          'Loaded ${selected.recordingId}: ${selected.samples.length} samples.';
    });
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _finishRecording();
      return;
    }
    final config = _config();
    final errors = config.validate();
    if (errors.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _status = errors.join(' ');
      });
      return;
    }
    final recordingId =
        '${_participantController.text.trim()}_${DateTime.now().microsecondsSinceEpoch}';
    await _recordingService.start(
      recordingId,
      interval: Duration(
        microseconds: (1000000 / config.requestedSamplingRateHz).round(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _recording = true;
      _sampleCount = 0;
      _status = 'Recording raw accelerometer samples...';
    });
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted || !_recording) {
        timer.cancel();
        return;
      }
      setState(() => _sampleCount = _recordingService.samples.length);
    });
    _stopTimer = Timer(
      Duration(seconds: config.durationSeconds),
      _finishRecording,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Detection Experiment'),
        actions: [
          IconButton(
            tooltip: 'Saved recordings',
            onPressed: _recording ? null : _openRecordings,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text('Recording baseline', style: TextStyle(fontSize: 24)),
            SizedBox(height: 12),
            Text(
              'Raw accelerometer data is retained and replayed through both algorithms.',
            ),
            SizedBox(height: 24),
            TextField(
              controller: _participantController,
              decoration: InputDecoration(labelText: 'Participant ID'),
            ),
            DropdownButtonFormField<Activity>(
              initialValue: _activity,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: Activity.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _activity = value!),
            ),
            DropdownButtonFormField<PhonePlacement>(
              initialValue: _phonePlacement,
              decoration: const InputDecoration(labelText: 'Phone placement'),
              items: PhonePlacement.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _phonePlacement = value!),
            ),
            TextField(
              controller: _placementController,
              decoration: InputDecoration(labelText: 'Placement detail'),
            ),
            TextField(
              controller: _trialController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Trial number'),
            ),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Recording duration (seconds)',
              ),
            ),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Protocol notes (optional)',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recording and detector parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              controller: _samplingRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Requested sampling rate (Hz)',
              ),
            ),
            TextField(
              controller: _smoothingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Smoothing window (samples)',
              ),
            ),
            TextField(
              controller: _windowController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Adaptive window (ms)',
              ),
            ),
            TextField(
              controller: _minimumIntervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum step interval (ms)',
              ),
            ),
            TextField(
              controller: _kController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Mean + k × standard deviation: k',
              ),
            ),
            SizedBox(height: 24),
            Text(_status),
            Text('Samples: $_sampleCount'),
            SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(_recording ? 'Stop and process' : 'Start recording'),
            ),
            TextButton.icon(
              onPressed: _recording ? null : _importGroundTruth,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import ground-truth CSV'),
            ),
            SizedBox(height: 16),
            Text(
              'Algorithms: adaptive midpoint; mean + 1.5 standard deviations.',
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingListPage extends StatelessWidget {
  const RecordingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved recordings')),
      body: FutureBuilder<List<SavedRecording>>(
        future: RecordingRepository().list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not read recordings: ${snapshot.error}'),
            );
          }
          final recordings = snapshot.data ?? const [];
          if (recordings.isEmpty) {
            return const Center(child: Text('No saved recordings found.'));
          }
          return ListView.separated(
            itemCount: recordings.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final recording = recordings[index];
              return ListTile(
                title: Text(recording.recordingId),
                subtitle: Text(
                  '${recording.participantId} · ${recording.activity} · ${recording.phonePlacement} · trial ${recording.trialNumber}\n${recording.samples.length} samples',
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).pop(recording),
              );
            },
          );
        },
      ),
    );
  }
}

class EvaluationResultsPage extends StatelessWidget {
  const EvaluationResultsPage({super.key, required this.results});

  final List<EvaluationResult> results;

  String _format(double? value) =>
      value == null ? '—' : value.toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Algorithm comparison')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Metrics use imported annotations only.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          for (final result in results)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.algorithm,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Predicted: ${result.predictedCount}; ground truth: ${result.groundTruthCount}',
                    ),
                    Text(
                      'TP ${result.truePositives}; FP ${result.falsePositives}; FN ${result.falseNegatives}',
                    ),
                    Text(
                      'Precision ${_format(result.precision)} · Recall ${_format(result.recall)} · F1 ${_format(result.f1)}',
                    ),
                    Text(
                      'Median detection latency: ${_format(result.medianLatencyMs)} ms',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
