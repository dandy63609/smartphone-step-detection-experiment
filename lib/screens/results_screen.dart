import 'package:flutter/material.dart';

import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';
import 'setup_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.recording});

  final SavedRecording recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = evaluateRecording(recording);
    final midpointResult = results.firstWhere(
      (r) => r.algorithm == ThresholdAlgorithm.adaptiveMidpoint,
    );
    final meanStdResult = results.firstWhere(
      (r) => r.algorithm == ThresholdAlgorithm.meanStd,
    );

    final liveMatched = recording.liveMatchesReplay;
    final liveAlgorithmName = recording.config.primaryLiveAlgorithm.displayName;
    final primaryReplayCount = recording.replayCount(
      recording.config.primaryLiveAlgorithm,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial Evaluation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Recording Info Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recording.recordingId,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Trial #${recording.config.trialNumber}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _infoItem(
                          'Participant',
                          recording.config.participantId,
                        ),
                        _infoItem(
                          'Activity',
                          recording.config.activity.value.toUpperCase(),
                        ),
                        _infoItem(
                          'Placement',
                          '${recording.config.phonePlacement.value.toUpperCase()} (${recording.config.placementDetail})',
                        ),
                        _infoItem(
                          'Ground Truth',
                          '${recording.config.targetSteps} steps',
                        ),
                        _infoItem(
                          'Duration',
                          '${recording.durationSeconds.toStringAsFixed(1)} s',
                        ),
                        _infoItem(
                          'Samples',
                          '${recording.samples.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live vs Replay Integrity Check
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: liveMatched
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: liveMatched
                      ? Colors.green.shade400
                      : Colors.amber.shade400,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    liveMatched ? Icons.verified : Icons.warning_amber,
                    color: liveMatched
                        ? Colors.green.shade800
                        : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      liveMatched
                          ? 'Experimental Integrity Verified: Live count ($liveAlgorithmName: ${recording.liveStepCount}) exactly matches offline replay ($primaryReplayCount).'
                          : 'Notice: Live count (${recording.liveStepCount}) differs from replay ($primaryReplayCount).',
                      style: TextStyle(
                        fontSize: 13,
                        color: liveMatched
                            ? Colors.green.shade900
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Algorithm Benchmark (Target: 100 Steps)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Comparison Cards
            Row(
              children: [
                Expanded(
                  child: _algorithmCard(
                    context,
                    title: 'Adaptive Midpoint',
                    result: midpointResult,
                    isPrimary: recording.config.primaryLiveAlgorithm ==
                        ThresholdAlgorithm.adaptiveMidpoint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _algorithmCard(
                    context,
                    title: 'Mean + k·SD',
                    result: meanStdResult,
                    isPrimary: recording.config.primaryLiveAlgorithm ==
                        ThresholdAlgorithm.meanStd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            FilledButton.icon(
              onPressed: () {
                // Navigate to next trial with incremented trial number
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
              icon: const Icon(Icons.play_arrow),
              label: Text('Next Trial (#${recording.config.trialNumber + 1})'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _algorithmCard(
    BuildContext context, {
    required String title,
    required StepCountResult result,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE', style: TextStyle(fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${result.predictedSteps}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const Text('Detected Steps', style: TextStyle(fontSize: 12)),
            const Divider(height: 16),
            _metricRow(
              'Absolute Error',
              '${result.absoluteErrorSteps} steps',
            ),
            const SizedBox(height: 6),
            _metricRow(
              'Margin of Error',
              '${result.marginOfErrorPercent.toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 6),
            _metricRow(
              'Accuracy',
              '${result.accuracyPercent.toStringAsFixed(2)}%',
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? Colors.green.shade800 : null,
          ),
        ),
      ],
    );
  }
}
