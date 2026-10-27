import 'package:flutter/material.dart';

import '../models/experiment_models.dart';
import '../services/export_service.dart';
import '../services/recording_repository.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.store, this.exportService});

  final RecordingStore? store;
  final ExportService? exportService;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late final RecordingStore _store;
  late final ExportService _exportService;

  bool _loading = true;
  bool _exporting = false;
  List<SavedRecording> _recordings = const [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _exportService = widget.exportService ?? ExportService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _store.list();
    if (!mounted) return;
    setState(() {
      _recordings = list;
      _loading = false;
    });
  }

  Future<void> _exportAndShare() async {
    if (_recordings.isEmpty) return;
    setState(() {
      _exporting = true;
      _statusMessage = 'Generating sensor_data.csv and evaluation_summary.csv...';
    });

    try {
      final files = await _exportService.writeCsvFiles(_recordings);
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Generated ${files.length} CSV files: ${files.map((f) => f.path.split(RegExp(r'[/\\]')).last).join(', ')}';
      });
      await _exportService.share(files);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Export failed: $e';
      });
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSamples = _recordings.fold<int>(
      0,
      (sum, r) => sum + r.samples.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Datasets'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Experiment Dataset Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statColumn('Total Trials', '${_recordings.length}'),
                                _statColumn('Sensor Samples', '$totalSamples'),
                                _statColumn(
                                  'Output CSVs',
                                  '2 files',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Target Files:\n'
                              '1. sensor_data.csv (High-Frequency Timeseries)\n'
                              '2. evaluation_summary.csv (100-Step Margin of Error)',
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Export button
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _recordings.isEmpty || _exporting
                            ? null
                            : _exportAndShare,
                        icon: _exporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share),
                        label: Text(
                          _exporting
                              ? 'Exporting...'
                              : 'Export & Share CSV Package',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 20),
                    Text(
                      'Recorded Trials (${_recordings.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List of recordings
                    Expanded(
                      child: _recordings.isEmpty
                          ? const Center(
                              child: Text(
                                'No trials recorded yet.\nConduct trials from the Dashboard.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _recordings.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final r = _recordings[index];
                                final mid = r.replayCount(
                                  ThresholdAlgorithm.adaptiveMidpoint,
                                );
                                final msd = r.replayCount(
                                  ThresholdAlgorithm.meanStd,
                                );
                                return ListTile(
                                  title: Text(
                                    r.recordingId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${r.config.participantId} • ${r.config.activity.value} • ${r.config.phonePlacement.value} (#${r.config.trialNumber})\n'
                                    'Detections: Midpoint=$mid | Mean+SD=$msd (out of ${r.config.targetSteps})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '${r.samples.length} smp',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
