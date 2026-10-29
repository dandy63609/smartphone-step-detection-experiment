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
    final completedConditions = conditionSummaries
        .where((c) => c.trials >= targetRepsPerCondition)
        .length;

    final overallMeanAccuracy = allResults.isEmpty
        ? null
        : allResults.map((r) => r.accuracyPercent).reduce((a, b) => a + b) /
              allResults.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: Color(0xFF1A73E8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Step Detection Experiment',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExportScreen(store: _store),
                ),
              );
            },
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export CSVs',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    // Google Fit-style Hero Pilot Progress Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE1E6EF)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Circular Ring Indicator
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: CircularProgressIndicator(
                                        value: (totalTrials /
                                                targetTotalRecordings)
                                            .clamp(0.0, 1.0),
                                        strokeWidth: 7,
                                        strokeCap: StrokeCap.round,
                                        backgroundColor:
                                            const Color(0xFFE8F0FE),
                                        color: const Color(0xFF1A73E8),
                                      ),
                                    ),
                                    Text(
                                      '${((totalTrials / targetTotalRecordings) * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A73E8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pilot Progress',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalTrials / $targetTotalRecordings Trials recorded',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF444746),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _metricPill(
                                          icon: Icons.check_circle_outline,
                                          label: '$completedConditions/8 Done',
                                          bgColor: const Color(0xFFE6F4EA),
                                          fgColor: const Color(0xFF137333),
                                        ),
                                        _metricPill(
                                          icon: Icons.analytics_outlined,
                                          label: overallMeanAccuracy != null
                                              ? '${overallMeanAccuracy.toStringAsFixed(1)}% Acc'
                                              : '100-Step Ground Truth',
                                          bgColor: const Color(0xFFE8F0FE),
                                          fgColor: const Color(0xFF1967D2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.science_outlined,
                                  size: 18,
                                  color: Color(0xFF1A73E8),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Factorial benchmark (E1–E8): Adaptive Midpoint vs Mean + k·SD calibrated to 100 physical steps.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF444746),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Experimental Conditions (E1–E8)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'Tap to launch trial',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // List of conditions E1-E8
                    for (final summary in conditionSummaries)
                      _buildConditionTile(
                        context,
                        summary: summary,
                        targetReps: targetRepsPerCondition,
                      ),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New 100-Step Trial',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTile(
    BuildContext context, {
    required ConditionSummary summary,
    required int targetReps,
  }) {
    final count = summary.trials;
    final isComplete = count >= targetReps;
    final conditionDetails = _parseConditionId(summary.condition);
    final isWalking = conditionDetails.$1 == Activity.walking;
    final isHand = conditionDetails.$2 == PhonePlacement.hand;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isComplete
                ? const Color(0xFFCEEAD6)
                : const Color(0xFFE1E6EF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final config = ExperimentConfig(
              participantId: 'P01',
              activity: conditionDetails.$1,
              phonePlacement: conditionDetails.$2,
              placementDetail: isHand ? 'right hand' : 'front-right pocket',
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Condition Badge E1..E8
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFFE6F4EA)
                        : const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    summary.condition,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isComplete
                          ? const Color(0xFF137333)
                          : const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Activity, Placement, and Algorithm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isWalking
                                ? Icons.directions_walk_rounded
                                : Icons.directions_run_rounded,
                            size: 15,
                            color: const Color(0xFF1A73E8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conditionDetails.$1.value.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: Color(0xFF9AA0A6)),
                            ),
                          ),
                          Icon(
                            isHand
                                ? Icons.back_hand_outlined
                                : Icons.checkroom_rounded,
                            size: 14,
                            color: const Color(0xFF5F6368),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conditionDetails.$2.value.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conditionDetails.$3.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 5-segment progress bar
                      Row(
                        children: List.generate(targetReps, (i) {
                          final filled = i < count;
                          return Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsets.only(
                                right: i == targetReps - 1 ? 0 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: filled
                                    ? (isComplete
                                          ? const Color(0xFF1E8E3E)
                                          : const Color(0xFF1A73E8))
                                    : const Color(0xFFE8EAED),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Right metrics column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFFE6F4EA)
                            : const Color(0xFFF3F6FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count / $targetReps',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isComplete
                              ? const Color(0xFF137333)
                              : const Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (summary.meanMarginOfErrorPercent != null)
                      Text(
                        '±${summary.meanMarginOfErrorPercent!.toStringAsFixed(1)}% MoE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A73E8),
                        ),
                      )
                    else
                      const Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9AA0A6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA0A6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Activity, PhonePlacement, ThresholdAlgorithm) _parseConditionId(String id) {
    return switch (id) {
      'E1' => (
        Activity.walking,
        PhonePlacement.hand,
        ThresholdAlgorithm.adaptiveMidpoint,
      ),
      'E2' => (
        Activity.walking,
        PhonePlacement.hand,
        ThresholdAlgorithm.meanStd,
      ),
      'E3' => (
        Activity.jogging,
        PhonePlacement.hand,
        ThresholdAlgorithm.adaptiveMidpoint,
      ),
      'E4' => (
        Activity.jogging,
        PhonePlacement.hand,
        ThresholdAlgorithm.meanStd,
      ),
      'E5' => (
        Activity.walking,
        PhonePlacement.pocket,
        ThresholdAlgorithm.adaptiveMidpoint,
      ),
      'E6' => (
        Activity.walking,
        PhonePlacement.pocket,
        ThresholdAlgorithm.meanStd,
      ),
      'E7' => (
        Activity.jogging,
        PhonePlacement.pocket,
        ThresholdAlgorithm.adaptiveMidpoint,
      ),
      'E8' || _ => (
        Activity.jogging,
        PhonePlacement.pocket,
        ThresholdAlgorithm.meanStd,
      ),
    };
  }
}
