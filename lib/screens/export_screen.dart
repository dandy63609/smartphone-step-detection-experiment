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
      _statusMessage =
          'Generating sensor_data.csv, sensor_linear_data.csv, and evaluation_summary.csv...';
    });

    try {
      final files = await _exportService.writeCsvFiles(_recordings);
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Export ready: ${files.map((f) => f.path.split(RegExp(r'[/\\]')).last).join(', ')}';
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dataset Overview Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE1E6EF)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.folder_zip_outlined,
                                size: 20,
                                color: Color(0xFF1A73E8),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Experiment Dataset Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _statTile(
                                  'Total Trials',
                                  '${_recordings.length}',
                                  Icons.assignment_turned_in_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statTile(
                                  'Raw Samples',
                                  '$totalSamples',
                                  Icons.timeline_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statTile(
                                  'CSV Schemas',
                                  '3 files',
                                  Icons.table_view_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• sensor_data.csv — Standard 9-column raw accelerometer timeseries',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• sensor_linear_data.csv — Dual-stream (Raw +G & Linear -G)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• evaluation_summary.csv — 4-way benchmark (A1, A2, B1, B2)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Export Button
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _recordings.isEmpty || _exporting
                            ? null
                            : _exportAndShare,
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 20),
                        label: Text(
                          _exporting
                              ? 'Generating CSV Package...'
                              : 'Export & Share CSV Package',
                        ),
                      ),
                    ),

                    if (_statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A73E8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Recorded Trials (${_recordings.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List of recordings
                    Expanded(
                      child: _recordings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No trials recorded yet.\nStart a 100-step trial from the Dashboard.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5F6368),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recordings.length,
                              itemBuilder: (context, index) {
                                final r = _recordings[index];
                                final a1 = r.replayVariantCount(
                                  AlgorithmVariant.a1MidpointRaw,
                                );
                                final a2 = r.replayVariantCount(
                                  AlgorithmVariant.a2MidpointLinear,
                                );
                                final b1 = r.replayVariantCount(
                                  AlgorithmVariant.b1MeanSdRaw,
                                );
                                final b2 = r.replayVariantCount(
                                  AlgorithmVariant.b2MeanSdLinear,
                                );
                                final cond = conditionId(
                                  r.config.activity,
                                  r.config.phonePlacement,
                                  r.config.primaryLiveAlgorithm,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE1E6EF),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0FE),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          cond,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: Color(0xFF1A73E8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.recordingId,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Color(0xFF1F1F1F),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${r.config.participantId} • ${r.config.activity.value.toUpperCase()} • ${r.config.phonePlacement.value.toUpperCase()} (#${r.config.trialNumber})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF5F6368),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'A1:$a1 • A2:$a2 • B1:$b1 • B2:$b2  (Target: ${r.config.targetSteps})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A73E8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${r.samples.length}\nsmp',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF80868B),
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1F1F),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }
}
