import 'package:flutter/material.dart';

import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';
import 'setup_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.recording});

  final SavedRecording recording;

  @override
  Widget build(BuildContext context) {
    final results = evaluateRecording(recording);
    final midpointResult = results.firstWhere(
      (r) => r.algorithm == ThresholdAlgorithm.adaptiveMidpoint,
    );
    final meanStdResult = results.firstWhere(
      (r) => r.algorithm == ThresholdAlgorithm.meanStd,
    );
    final fourWayResults = evaluateRecordingAllFour(recording);
    final minAbsError = fourWayResults
        .map((r) => r.absoluteErrorSteps)
        .reduce((a, b) => a < b ? a : b);

    final liveMatched = recording.liveMatchesReplay;
    final liveAlgorithmName = recording.config.primaryLiveAlgorithm.displayName;
    final primaryReplayCount = recording.replayCount(
      recording.config.primaryLiveAlgorithm,
    );
    final condId = conditionId(
      recording.config.activity,
      recording.config.phonePlacement,
      recording.config.primaryLiveAlgorithm,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial Evaluation'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$condId • Trial #${recording.config.trialNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            // Live vs Replay Integrity Pill Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: liveMatched
                    ? const Color(0xFFE6F4EA)
                    : const Color(0xFFFEF7E0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: liveMatched
                      ? const Color(0xFFCEEAD6)
                      : const Color(0xFFFDE293),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      liveMatched
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      size: 20,
                      color: liveMatched
                          ? const Color(0xFF137333)
                          : const Color(0xFFB06000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveMatched
                              ? 'Experimental Integrity Verified'
                              : 'Replay Mismatch Detected',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: liveMatched
                                ? const Color(0xFF137333)
                                : const Color(0xFFB06000),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          liveMatched
                              ? 'Live count ($liveAlgorithmName: ${recording.liveStepCount}) matches offline replay ($primaryReplayCount).'
                              : 'Live count (${recording.liveStepCount}) differs from offline replay ($primaryReplayCount).',
                          style: TextStyle(
                            fontSize: 12,
                            color: liveMatched
                                ? const Color(0xFF0D652D)
                                : const Color(0xFF8F4E00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4-Algorithm Scoreboard Section (PLANNING.md §2 & §3 Fase 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '4-Algorithm Scoreboard (A1–B2)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  Text(
                    'Target: ${recording.config.targetSteps} Steps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E6EF)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Column(
                children: [
                  // Header row
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Kombinasi Algoritma',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Langkah',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'MoE %',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Status',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EEF7)),
                  for (var i = 0; i < fourWayResults.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0xFFF1F3F4)),
                    _buildScoreboardRow(
                      fourWayResults[i],
                      isWinner:
                          fourWayResults[i].absoluteErrorSteps == minAbsError,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary Comparison Cards (A1 vs B1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Primary Stream Comparison (Raw +Gravity)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _algorithmCard(
                    context,
                    title: 'Adaptive Midpoint',
                    subtitle: 'A1 • T = (max + min) / 2',
                    result: midpointResult,
                    isPrimary: recording.config.primaryLiveAlgorithm ==
                        ThresholdAlgorithm.adaptiveMidpoint,
                    isBetter: midpointResult.absoluteErrorSteps <=
                        meanStdResult.absoluteErrorSteps,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _algorithmCard(
                    context,
                    title: 'Mean + k·SD',
                    subtitle: 'B1 • T = μ + ${recording.config.parameters.k}·σ',
                    result: meanStdResult,
                    isPrimary: recording.config.primaryLiveAlgorithm ==
                        ThresholdAlgorithm.meanStd,
                    isBetter: meanStdResult.absoluteErrorSteps <=
                        midpointResult.absoluteErrorSteps,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recording Metadata Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E6EF)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recording.recordingId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _infoItem('Participant', recording.config.participantId),
                      _infoItem(
                        'Activity',
                        recording.config.activity.value.toUpperCase(),
                      ),
                      _infoItem(
                        'Placement',
                        '${recording.config.phonePlacement.value.toUpperCase()} (${recording.config.placementDetail})',
                      ),
                      _infoItem(
                        'Duration',
                        '${recording.durationSeconds.toStringAsFixed(1)} s',
                      ),
                      _infoItem('Samples', '${recording.samples.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  final nextConfig = ExperimentConfig(
                    participantId: recording.config.participantId,
                    activity: recording.config.activity,
                    phonePlacement: recording.config.phonePlacement,
                    placementDetail: recording.config.placementDetail,
                    trialNumber: recording.config.trialNumber + 1,
                    primaryLiveAlgorithm: recording.config.primaryLiveAlgorithm,
                    targetSteps: recording.config.targetSteps,
                    fallbackTimeoutSeconds:
                        recording.config.fallbackTimeoutSeconds,
                    notes: recording.config.notes,
                    requestedSamplingRateHz:
                        recording.config.requestedSamplingRateHz,
                    parameters: recording.config.parameters,
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SetupScreen(initialConfig: nextConfig),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Next Trial (#${recording.config.trialNumber + 1})',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Return to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboardRow(StepCountResult r, {required bool isWinner}) {
    final signed = r.signedErrorSteps;
    final diffStr = signed == 0
        ? '0'
        : signed > 0
        ? '+$signed'
        : '$signed';

    final (statusBg, statusFg) = switch (r.status) {
      DetectionStatus.accurate => (
        const Color(0xFFE6F4EA),
        const Color(0xFF137333),
      ),
      DetectionStatus.overcounting => (
        const Color(0xFFFEF7E0),
        const Color(0xFFB06000),
      ),
      DetectionStatus.undercounting => (
        const Color(0xFFFCE8E6),
        const Color(0xFFC5221F),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Variant Badge & Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isWinner
                        ? const Color(0xFFE6F4EA)
                        : const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.variantCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isWinner
                          ? const Color(0xFF137333)
                          : const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.variant?.thresholdAlgorithm.displayName ??
                            r.algorithm.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      Text(
                        r.variant?.sensorLabel ?? 'Raw Accel (+Gravity)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Predicted Steps & Signed Diff
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${r.predictedSteps}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '($diffStr)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6368),
                  ),
                ),
              ],
            ),
          ),

          // Margin of Error %
          Expanded(
            flex: 2,
            child: Text(
              '${r.marginOfErrorPercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          // Status Pill
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5F6368),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }

  Widget _algorithmCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required StepCountResult result,
    required bool isPrimary,
    required bool isBetter,
  }) {
    final signed = result.signedErrorSteps;
    final signedStr = signed > 0 ? '+$signed' : '$signed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBetter ? const Color(0xFF1A73E8) : const Color(0xFFE1E6EF),
          width: isBetter ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF80868B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${result.predictedSteps}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${result.groundTruthSteps}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF80868B),
                ),
              ),
            ],
          ),
          const Text(
            'Detected Steps',
            style: TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.accuracyPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE8F0FE),
              color: result.accuracyPercent >= 95
                  ? const Color(0xFF1E8E3E)
                  : const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          _metricRow(
            'Abs Error',
            '${result.absoluteErrorSteps} ($signedStr)',
          ),
          const SizedBox(height: 6),
          _metricRow(
            'Margin of Error',
            '${result.marginOfErrorPercent.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 6),
          _metricRow(
            'Accuracy',
            '${result.accuracyPercent.toStringAsFixed(1)}%',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight
                ? const Color(0xFF137333)
                : const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}
