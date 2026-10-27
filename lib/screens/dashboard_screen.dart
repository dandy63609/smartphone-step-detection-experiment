import 'package:flutter/material.dart';

import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';
import '../services/recording_repository.dart';
import '../services/recording_service.dart';
import 'export_screen.dart';
import 'setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.store, this.recordingService});

  final RecordingStore? store;
  final RecordingService? recordingService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RecordingStore _store;
  late final RecordingService _recordingService;

  bool _loading = true;
  List<SavedRecording> _recordings = const [];

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _recordingService = widget.recordingService ?? RecordingService();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute evaluation results for all recordings
    final allResults = <StepCountResult>[
      for (final r in _recordings) ...evaluateRecording(r),
    ];
    final conditionSummaries = summarizeConditions(allResults);

    // Pilot target: 5 repetitions per condition (40 physical recordings)
    const targetRepsPerCondition = 5;
    final totalTrials = _recordings.length;
    const targetTotalRecordings = 40;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Detection Experiment'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExportScreen(store: _store),
                ),
              );
            },
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Export CSVs',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Research Pilot Progress Card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pilot Progress',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$totalTrials / $targetTotalRecordings Trials',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (totalTrials / targetTotalRecordings)
                                    .clamp(0.0, 1.0),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Fixed 100-step ground-truth comparison: Factorial design with 8 conditions (E1–E8), target 5 repetitions each.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Experimental Conditions (E1–E8)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap condition to test',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Grid / List of conditions E1-E8
                    for (final summary in conditionSummaries)
                      _buildConditionTile(
                        context,
                        summary: summary,
                        targetReps: targetRepsPerCondition,
                      ),

                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SetupScreen(
                store: _store,
                recordingService: _recordingService,
              ),
            ),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New 100-Step Trial'),
      ),
    );
  }

  Widget _buildConditionTile(
    BuildContext context, {
    required ConditionSummary summary,
    required int targetReps,
  }) {
    final theme = Theme.of(context);
    final count = summary.trials;
    final progress = (count / targetReps).clamp(0.0, 1.0);

    // Map condition ID to Activity, Placement, Algorithm
    final conditionDetails = _parseConditionId(summary.condition);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Pre-populate setup screen with this condition
          final config = ExperimentConfig(
            participantId: 'P01',
            activity: conditionDetails.$1,
            phonePlacement: conditionDetails.$2,
            placementDetail: conditionDetails.$2 == PhonePlacement.hand
                ? 'right hand'
                : 'front-right pocket',
            trialNumber: count + 1,
            primaryLiveAlgorithm: conditionDetails.$3,
          );
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SetupScreen(
                initialConfig: config,
                store: _store,
                recordingService: _recordingService,
              ),
            ),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: count >= targetReps
                      ? Colors.green.shade100
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.condition,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: count >= targetReps
                        ? Colors.green.shade900
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conditionDetails.$1.value.toUpperCase()} • ${conditionDetails.$2.value.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      conditionDetails.$3.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        color: count >= targetReps ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count / $targetReps',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (summary.meanMarginOfErrorPercent != null)
                    Text(
                      'Mean MoE: ${summary.meanMarginOfErrorPercent!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    )
                  else
                    const Text(
                      'Pending',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Activity, PhonePlacement, ThresholdAlgorithm) _parseConditionId(String id) {
    return switch (id) {
      'E1' => (Activity.walking, PhonePlacement.hand, ThresholdAlgorithm.adaptiveMidpoint),
      'E2' => (Activity.walking, PhonePlacement.hand, ThresholdAlgorithm.meanStd),
      'E3' => (Activity.jogging, PhonePlacement.hand, ThresholdAlgorithm.adaptiveMidpoint),
      'E4' => (Activity.jogging, PhonePlacement.hand, ThresholdAlgorithm.meanStd),
      'E5' => (Activity.walking, PhonePlacement.pocket, ThresholdAlgorithm.adaptiveMidpoint),
      'E6' => (Activity.walking, PhonePlacement.pocket, ThresholdAlgorithm.meanStd),
      'E7' => (Activity.jogging, PhonePlacement.pocket, ThresholdAlgorithm.adaptiveMidpoint),
      'E8' || _ => (Activity.jogging, PhonePlacement.pocket, ThresholdAlgorithm.meanStd),
    };
  }
}
