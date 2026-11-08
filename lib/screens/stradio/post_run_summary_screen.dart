import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../evaluation/step_count_evaluation.dart';
import '../../models/experiment_models.dart';
import '../../services/posthog_service.dart';
import '../../services/recording_repository.dart';
import '../../theme/stradio_theme.dart';
import '../../widgets/stradio_logo_widget.dart';

/// Formats an integer with standard thousands separators (e.g. `1248` -> `1,248`).
String formatStepCount(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// Screen 3: STRADIO Post-Run Summary Screen (100% User-Focused).
///
/// Highlights real workout achievements, the Stradio Signature Rhythm Score
/// circular visualizer, a Cadence Consistency graph, and "Save & Finish Workout"
/// (which persists the immutable recording and sends telemetry to PostHog Cloud).
class PostRunSummaryScreen extends StatefulWidget {
  const PostRunSummaryScreen({
    super.key,
    required this.recording,
    required this.metrics,
    required this.sensorHealth,
    required this.store,
    required this.postHogService,
  });

  final SavedRecording recording;
  final RunSummaryMetrics metrics;
  final SensorHealthReport sensorHealth;
  final RecordingStore store;
  final PostHogTelemetryService postHogService;

  @override
  State<PostRunSummaryScreen> createState() => _PostRunSummaryScreenState();
}

class _PostRunSummaryScreenState extends State<PostRunSummaryScreen> {
  bool _saving = false;
  bool _saved = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  Future<void> _saveAndFinishWorkout() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    try {
      if (!_saved) {
        try {
          await widget.store.save(widget.recording);
        } on StateError {
          // Already saved with this immutable ID; continue to telemetry.
        }
        await widget.postHogService.captureWorkoutAndBenchmarks(
          recording: widget.recording,
          metrics: widget.metrics,
          health: widget.sensorHealth,
        );
        _saved = true;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _feedbackIsError = true;
        _feedbackMessage = 'Could not save workout: $error';
      });
    }
  }

  Future<void> _shareWorkout() async {
    final m = widget.metrics;
    final stepsFormatted = formatStepCount(m.totalSteps);
    final summaryText =
        'STRADIO Workout Complete\n'
        'Steps: $stepsFormatted STEPS\n'
        'Duration: ${m.formattedDuration}\n'
        'Avg Cadence: ${m.averageCadenceSpm.round()} SPM\n'
        'Distance: ${m.distanceKm.toStringAsFixed(2)} KM\n'
        'Rhythm Score: ${m.rhythmScorePercent.round()}% Match (${m.targetBpm} BPM)';

    setState(() {
      _feedbackIsError = false;
      _feedbackMessage = 'Workout summary prepared for sharing.';
    });

    try {
      await SharePlus.instance
          .share(
            ShareParams(
              text: summaryText,
              subject: 'STRADIO Workout Summary',
            ),
          )
          .timeout(const Duration(milliseconds: 50));
    } on Object {
      // Native share sheet is optional in desktop/widget test environments.
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;
    final formattedSteps = formatStepCount(m.totalSteps);
    final avgSpmText = '${m.averageCadenceSpm.round()} AVG SPM';
    final distanceText = '${m.distanceKm.toStringAsFixed(2)} KM DISTANCE';
    final rhythmPercent = m.rhythmScorePercent.round();
    final benchmarkResults = evaluateRecordingAllFour(widget.recording);
    final errorPercent = (m.totalSteps - widget.recording.config.targetSteps).toDouble();

    return Scaffold(
      backgroundColor: StradioColors.ivoryCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPad = isWide ? 40.0 : (isTablet ? 28.0 : 20.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    // Minimalist Top Header Bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        12,
                        horizontalPad,
                        8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Semantics(
                            button: true,
                            label: 'Return to Run',
                            child: IconButton(
                              key: const Key('summary_back_button'),
                              onPressed: () => Navigator.of(context).pop(false),
                              tooltip: 'Discard / Back to Run',
                              style: IconButton.styleFrom(
                                backgroundColor: StradioColors.whiteSurface,
                                elevation: 1,
                                shadowColor: Colors.black.withValues(alpha: 0.08),
                                shape: const CircleBorder(),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: StradioColors.midnight,
                                size: 20,
                              ),
                            ),
                          ),
                          Text(
                            'POST-RUN INSIGHTS',
                            style: StradioTypography.interLabel(
                              fontSize: 11,
                              color: StradioColors.secondaryNeutral,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Share Workout',
                            child: IconButton(
                              key: const Key('summary_top_share_button'),
                              onPressed: _shareWorkout,
                              tooltip: 'Share Workout',
                              style: IconButton.styleFrom(
                                backgroundColor: StradioColors.whiteSurface,
                                elevation: 1,
                                shadowColor: Colors.black.withValues(alpha: 0.08),
                                shape: const CircleBorder(),
                              ),
                              icon: const Icon(
                                Icons.share_outlined,
                                color: StradioColors.sonicCoral,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad,
                          12,
                          horizontalPad,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Area: Celebratory Header + Mini Ribbon Wave Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const StradioMiniWaveBadge(),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Run Complete! : You Found Your Rhythm',
                                        style: StradioTypography.soraHeading(
                                          fontSize: isTablet ? 22 : 19,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Session ${widget.recording.recordingId} (${widget.recording.config.activity.value.toUpperCase()} / ${widget.recording.config.phonePlacement.value.toUpperCase()})',
                                        style: StradioTypography.interLabel(
                                          fontSize: 12,
                                          color: StradioColors.mutedIvory,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 1. Main Stat Hero Card with 100-step benchmark error
                            _MainStatHeroCard(
                              stepsLabel: '$formattedSteps STEPS',
                              targetSteps: widget.recording.config.targetSteps,
                              errorPercent: errorPercent,
                              durationLabel: '${m.formattedDuration} DURATION',
                              spmLabel: avgSpmText,
                              distanceLabel: distanceText,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 16),

                            // 2 & 3. Signature Rhythm Card + Pace/Cadence Consistency Card
                            if (isTablet)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _StradioSignatureRhythmCard(
                                      rhythmPercent: rhythmPercent,
                                      targetBpm: m.targetBpm,
                                      actualSpm: m.averageCadenceSpm,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _CadenceConsistencyCard(
                                      bucketsSpm: m.cadenceBucketsSpm,
                                      targetBpm: m.targetBpm,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _StradioSignatureRhythmCard(
                                rhythmPercent: rhythmPercent,
                                targetBpm: m.targetBpm,
                                actualSpm: m.averageCadenceSpm,
                              ),
                              const SizedBox(height: 16),
                              _CadenceConsistencyCard(
                                bucketsSpm: m.cadenceBucketsSpm,
                                targetBpm: m.targetBpm,
                              ),
                            ],
                            const SizedBox(height: 16),

                            // 4. Research Benchmark: 4-Algorithm Replay Scoreboard
                            _AlgorithmBenchmarkScoreboardCard(
                              results: benchmarkResults,
                              targetSteps: widget.recording.config.targetSteps,
                            ),

                            if (_feedbackMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _feedbackIsError
                                      ? StradioColors.statusError.withValues(
                                          alpha: 0.15,
                                        )
                                      : StradioColors.whiteSurface,
                                  borderRadius: BorderRadius.circular(
                                    StradioRadii.control,
                                  ),
                                  boxShadow: StradioColors.cardShadow,
                                ),
                                child: Text(
                                  _feedbackMessage!,
                                  style: StradioTypography.interBody(
                                    fontSize: 13,
                                    color: StradioColors.midnight,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Bar
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        12,
                        horizontalPad,
                        16,
                      ),
                      decoration: const BoxDecoration(
                        color: StradioColors.ivoryCanvas,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Primary glowing button "Save & Finish Workout" (Stadium Pill per Reference 1)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: StradioColors.heroGradient,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: StradioColors.sonicCoral.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FilledButton(
                              key: const Key('save_finish_workout_button'),
                              onPressed: _saving ? null : _saveAndFinishWorkout,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                _saving
                                    ? 'Saving Workout & Telemetry...'
                                    : 'Save & Finish Workout',
                                style: StradioTypography.soraHeading(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('share_workout_button'),
                            onPressed: _shareWorkout,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: StradioColors.whiteSurface,
                              shape: const StadiumBorder(),
                              side: BorderSide.none,
                              elevation: 1,
                              shadowColor: Colors.black.withValues(alpha: 0.06),
                              foregroundColor: StradioColors.midnight,
                            ),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: Text(
                              'Share Workout',
                              style: StradioTypography.interLabel(
                                fontSize: 14,
                                color: StradioColors.midnight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MainStatHeroCard extends StatelessWidget {
  const _MainStatHeroCard({
    required this.stepsLabel,
    required this.targetSteps,
    required this.errorPercent,
    required this.durationLabel,
    required this.spmLabel,
    required this.distanceLabel,
    required this.isTablet,
  });

  final String stepsLabel;
  final int targetSteps;
  final double errorPercent;
  final String durationLabel;
  final String spmLabel;
  final String distanceLabel;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final absError = errorPercent.abs();
    final signPrefix = errorPercent > 0 ? '+' : (errorPercent < 0 ? '-' : '');

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: StradioColors.whiteSurface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: StradioColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL WORKOUT ACHIEVEMENTS',
                style: StradioTypography.interLabel(
                  fontSize: 11,
                  color: StradioColors.secondaryNeutral,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StradioColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '100 Steps Benchmark',
                  style: StradioTypography.interLabel(
                    fontSize: 10,
                    color: StradioColors.rhythmViolet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                stepsLabel,
                key: const Key('summary_steps_headline'),
                style: StradioTypography.soraMetric(
                  fontSize: isTablet ? 42 : 34,
                  fontWeight: FontWeight.w800,
                  color: StradioColors.midnight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: absError <= 2.0
                      ? StradioColors.statusLive.withValues(alpha: 0.14)
                      : StradioColors.sonicCoral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Target: $targetSteps ($signPrefix${absError.toStringAsFixed(1)}% err)',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: absError <= 2.0
                        ? StradioColors.statusLive
                        : StradioColors.sonicCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: StradioColors.secondaryNeutral.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _AchievementTile(
                icon: Icons.timer_outlined,
                value: durationLabel,
                subtitle: 'Active Run Time',
              ),
              _AchievementTile(
                icon: Icons.speed_rounded,
                value: spmLabel,
                subtitle: 'Stride Cadence',
              ),
              _AchievementTile(
                icon: Icons.route_outlined,
                value: distanceLabel,
                subtitle: 'Estimated Distance',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlgorithmBenchmarkScoreboardCard extends StatelessWidget {
  const _AlgorithmBenchmarkScoreboardCard({
    required this.results,
    required this.targetSteps,
  });

  final List<StepCountResult> results;
  final int targetSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StradioColors.whiteSurface,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        boxShadow: StradioColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '4-ALGORITHM EVALUATION BENCHMARK',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: StradioColors.secondaryNeutral,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StradioColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Target: $targetSteps Steps',
                  style: StradioTypography.interLabel(
                    fontSize: 10,
                    color: StradioColors.rhythmViolet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Compares detected step counts against the physical 100-step ground truth across all 4 algorithmic pipelines.',
            style: StradioTypography.interBody(
              fontSize: 12,
              color: StradioColors.secondaryNeutral,
            ),
          ),
          const SizedBox(height: 14),
          ...results.map((r) => _AlgorithmResultRow(result: r)),
        ],
      ),
    );
  }
}

class _AlgorithmResultRow extends StatelessWidget {
  const _AlgorithmResultRow({required this.result});

  final StepCountResult result;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeTextColor) = switch (result.status) {
      DetectionStatus.accurate => (
        StradioColors.statusLive.withValues(alpha: 0.14),
        StradioColors.statusLive,
      ),
      DetectionStatus.overcounting => (
        StradioColors.sonicCoral.withValues(alpha: 0.14),
        StradioColors.sonicCoral,
      ),
      DetectionStatus.undercounting => (
        StradioColors.rhythmViolet.withValues(alpha: 0.14),
        StradioColors.rhythmViolet,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StradioColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(StradioRadii.control),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StradioColors.whiteSurface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: StradioColors.cardShadow,
            ),
            child: Text(
              result.variantCode,
              style: StradioTypography.soraHeading(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: StradioColors.midnight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.variantDisplayName,
                  style: StradioTypography.interBody(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StradioColors.midnight,
                  ),
                ),
                Text(
                  '${result.predictedSteps} steps (${result.marginOfErrorPercent.toStringAsFixed(1)}% error)',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: StradioColors.secondaryNeutral,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(StradioRadii.tag),
            ),
            child: Text(
              result.status.label,
              style: StradioTypography.interLabel(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: StradioColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(StradioRadii.control),
            ),
            child: Icon(icon, size: 18, color: StradioColors.sonicCoral),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: StradioTypography.soraHeading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StradioColors.midnight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: StradioTypography.interBody(
                  fontSize: 12,
                  color: StradioColors.secondaryNeutral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StradioSignatureRhythmCard extends StatelessWidget {
  const _StradioSignatureRhythmCard({
    required this.rhythmPercent,
    required this.targetBpm,
    required this.actualSpm,
  });

  final int rhythmPercent;
  final int targetBpm;
  final double actualSpm;

  @override
  Widget build(BuildContext context) {
    final hasSteps = actualSpm > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StradioColors.whiteSurface,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        boxShadow: StradioColors.cardShadow,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Rhythm Score circular match indicator $rhythmPercent percent',
            child: SizedBox(
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _RhythmRingPainter(
                  progress: (rhythmPercent / 100.0).clamp(0.0, 1.0),
                ),
                child: Center(
                  child: Text(
                    '$rhythmPercent%',
                    style: StradioTypography.soraMetric(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STRADIO SIGNATURE',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: StradioColors.rhythmViolet,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rhythm Score: $rhythmPercent% Match',
                  key: const Key('rhythm_score_headline'),
                  style: StradioTypography.soraHeading(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSteps
                      ? 'Your ${actualSpm.round()} SPM stride cadence synced against the $targetBpm BPM Neon Stride tempo.'
                      : 'No steps recorded in this session. Walk or jog during a run to measure your rhythm sync.',
                  style: StradioTypography.interBody(
                    fontSize: 13,
                    color: StradioColors.mutedIvory,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmRingPainter extends CustomPainter {
  const _RhythmRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 6;

    final trackPaint = Paint()
      ..color = StradioColors.secondaryNeutral.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          StradioColors.sonicCoral,
          StradioColors.rhythmViolet,
          StradioColors.sonicCoral,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RhythmRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CadenceConsistencyCard extends StatelessWidget {
  const _CadenceConsistencyCard({
    required this.bucketsSpm,
    required this.targetBpm,
  });

  final List<double> bucketsSpm;
  final int targetBpm;

  @override
  Widget build(BuildContext context) {
    final hasChartData = bucketsSpm.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StradioColors.whiteSurface,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        boxShadow: StradioColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cadence Consistency Across Run (SPM)',
                  style: StradioTypography.soraHeading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: StradioColors.midnight,
                  ),
                ),
              ),
              Text(
                'Target $targetBpm BPM',
                style: StradioTypography.interLabel(
                  fontSize: 12,
                  color: StradioColors.rhythmViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Measures how steady your stride cadence remained from start to finish.',
            style: StradioTypography.interBody(
              fontSize: 12,
              color: StradioColors.secondaryNeutral,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasChartData)
            Container(
              height: 110,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StradioColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(StradioRadii.control),
              ),
              child: Text(
                'Not enough stride intervals yet to plot cadence segments. Complete a run with active steps to view your consistency curve.',
                textAlign: TextAlign.center,
                style: StradioTypography.interBody(
                  fontSize: 12,
                  color: StradioColors.secondaryNeutral,
                ),
              ),
            )
          else
            Semantics(
              label: 'Cadence consistency line chart across workout segments',
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _CadenceConsistencyChartPainter(
                    bucketsSpm: bucketsSpm,
                    targetBpm: targetBpm,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CadenceConsistencyChartPainter extends CustomPainter {
  const _CadenceConsistencyChartPainter({
    required this.bucketsSpm,
    required this.targetBpm,
  });

  final List<double> bucketsSpm;
  final int targetBpm;

  @override
  void paint(Canvas canvas, Size size) {
    if (bucketsSpm.isEmpty) return;

    final maxVal = math.max(
      targetBpm * 1.25,
      bucketsSpm.reduce(math.max) * 1.1,
    );
    const minVal = 0.0;
    final range = math.max(1.0, maxVal - minVal);

    // Draw target BPM reference line
    final targetY =
        size.height - ((targetBpm - minVal) / range) * (size.height - 20) - 10;
    final guidePaint = Paint()
      ..color = StradioColors.secondaryNeutral.withValues(alpha: 0.20)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(0, targetY.clamp(8.0, size.height - 8.0)),
      Offset(size.width, targetY.clamp(8.0, size.height - 8.0)),
      guidePaint,
    );

    final points = <Offset>[];
    final count = bucketsSpm.length;
    for (var i = 0; i < count; i++) {
      final x = count == 1 ? size.width / 2 : (i / (count - 1)) * size.width;
      final normalized = ((bucketsSpm[i] - minVal) / range).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 24)) - 12;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final rect = Offset.zero & size;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          StradioColors.sonicCoral.withValues(alpha: 0.30),
          StradioColors.rhythmViolet.withValues(alpha: 0.04),
        ],
      ).createShader(rect);

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [StradioColors.sonicCoral, StradioColors.rhythmViolet],
      ).createShader(rect);

    canvas.drawPath(linePath, strokePaint);

    final dotPaint = Paint()..color = StradioColors.sonicCoral;
    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CadenceConsistencyChartPainter oldDelegate) =>
      oldDelegate.bucketsSpm != bucketsSpm ||
      oldDelegate.targetBpm != targetBpm;
}

