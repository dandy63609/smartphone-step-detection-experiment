import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../theme/stradio_theme.dart';

/// Daily bucket for the 7-Day Step Trend Bar Chart in [ActivityScreen].
class DailyStepBucket {
  const DailyStepBucket({
    required this.date,
    required this.shortLabel,
    required this.steps,
    required this.distanceKm,
    required this.sessionCount,
    required this.isToday,
  });

  final DateTime date;
  final String shortLabel;
  final int steps;
  final double distanceKm;
  final int sessionCount;
  final bool isToday;
}

/// Consumer Workout Journal & Weekly Step Trend screen (`v0.2.0` Milestone 6A).
///
/// Follows `assets/images/stradio-reference-1.png`, `docs/DESIGN.md`, and
/// `docs/EXPERIENCE.md`:
/// - **7-Day Step Trend & Weekly Summary Card (`28px` Pebble):** Displays real
///   accumulated steps, distance (`km`), and workout count over the last 7
///   calendar days alongside a 7-bar daily chart (`Mon`..`Sun` / `Sen`..`Min`).
///   Zero fake or pre-populated numbers.
/// - **Activity Filter Chips (`999px` Pill):** `All` / `Semua`, `Walking` /
///   `Jalan`, and `Jogging` / `Lari` with `48x48 dp` minimum touch targets.
/// - **Enriched Session History Cards (`16px` Card):** Date/time stamp,
///   activity badge (`WALK` / `JOG`), steps, calibrated distance (`km`),
///   duration, target BPM, and an optional `RAW 100Hz` badge when Developer
///   Mode is enabled and raw samples are present.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.profile,
    required this.recordings,
    required this.isLoading,
    required this.onOpenRecording,
    required this.onStartRunTap,
    this.referenceDate,
  });

  final StradioUserProfile profile;
  final List<SavedRecording> recordings;
  final bool isLoading;
  final ValueChanged<SavedRecording> onOpenRecording;
  final VoidCallback onStartRunTap;
  final DateTime? referenceDate;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'all'; // 'all' | 'walking' | 'jogging'

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  String _formatDuration(double totalSeconds) {
    final sec = totalSeconds.round().clamp(0, 86400 * 7);
    final mins = sec ~/ 60;
    final remSec = sec % 60;
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '${hrs}h ${remMins}m';
    }
    return '${mins}m ${remSec.toString().padLeft(2, '0')}s';
  }

  String _formatDateLabel(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $hh:$mm';
  }

  String _weekdayShortLabel(int weekday, AppLanguage language) {
    if (language == AppLanguage.id) {
      return switch (weekday) {
        DateTime.monday => 'Sen',
        DateTime.tuesday => 'Sel',
        DateTime.wednesday => 'Rab',
        DateTime.thursday => 'Kam',
        DateTime.friday => 'Jum',
        DateTime.saturday => 'Sab',
        _ => 'Min',
      };
    }
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      _ => 'Sun',
    };
  }

  List<DailyStepBucket> _computeWeeklyBuckets(
    List<SavedRecording> sourceRecordings,
  ) {
    final now = (widget.referenceDate ?? DateTime.now()).toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final buckets = <DailyStepBucket>[];

    for (var offset = 6; offset >= 0; offset--) {
      final dayDate = todayStart.subtract(Duration(days: offset));
      var daySteps = 0;
      var dayDistKm = 0.0;
      var daySessions = 0;

      for (final rec in sourceRecordings) {
        final localRec = rec.createdAt.toLocal();
        if (localRec.year == dayDate.year &&
            localRec.month == dayDate.month &&
            localRec.day == dayDate.day) {
          final steps = rec.effectiveStepCount;
          daySteps += steps;
          dayDistKm += RunMetricsCalculator.estimateDistanceKm(
            steps: steps,
            activity: rec.config.activity,
            heightCm: widget.profile.validHeightCm,
          );
          daySessions++;
        }
      }

      buckets.add(
        DailyStepBucket(
          date: dayDate,
          shortLabel: _weekdayShortLabel(
            dayDate.weekday,
            widget.profile.language,
          ),
          steps: daySteps,
          distanceKm: dayDistKm,
          sessionCount: daySessions,
          isToday: offset == 0,
        ),
      );
    }

    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;

    final filteredRecordings =
        widget.recordings.where((rec) {
          if (_selectedFilter == 'walking') {
            return rec.config.activity == Activity.walking;
          }
          if (_selectedFilter == 'jogging') {
            return rec.config.activity == Activity.jogging;
          }
          return true;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final weeklyBuckets = _computeWeeklyBuckets(filteredRecordings);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 20.0;

        return SingleChildScrollView(
          key: const Key('shell_activity_scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            16,
            horizontalPad,
            bottomClearance,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.navActivity,
                    style: StradioTypography.soraHeading(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. 7-Day Step Trend & Weekly Summary Card (28px Pebble)
                  _buildWeeklySummaryCard(
                    palette: palette,
                    strings: strings,
                    buckets: weeklyBuckets,
                  ),
                  const SizedBox(height: 18),

                  // 2. Activity Filter Chips Row (999px Pill, 48x48 dp touch targets)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          key: const Key('activity_filter_all'),
                          palette: palette,
                          filter: 'all',
                          label: strings.activityFilterAll,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('activity_filter_walking'),
                          palette: palette,
                          filter: 'walking',
                          label: strings.activityFilterWalking,
                          icon: Icons.directions_walk_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('activity_filter_jogging'),
                          palette: palette,
                          filter: 'jogging',
                          label: strings.activityFilterJogging,
                          icon: Icons.directions_run_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Session History List or Empty State
                  if (widget.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (widget.recordings.isEmpty)
                    _buildEmptyHistoryCard(palette, strings)
                  else if (filteredRecordings.isEmpty)
                    _buildEmptyFilterCard(palette, strings)
                  else
                    ...filteredRecordings.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSessionCard(
                          palette: palette,
                          strings: strings,
                          rec: rec,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySummaryCard({
    required StradioPalette palette,
    required StradioStrings strings,
    required List<DailyStepBucket> buckets,
  }) {
    final totalWeekSteps = buckets.fold<int>(0, (s, b) => s + b.steps);
    final totalWeekDistKm = buckets.fold<double>(
      0.0,
      (s, b) => s + b.distanceKm,
    );
    final totalWeekSessions = buckets.fold<int>(
      0,
      (s, b) => s + b.sessionCount,
    );

    final dailyGoal = widget.profile.dailyStepGoal > 0
        ? widget.profile.dailyStepGoal
        : StradioUserProfile.defaultDailyStepGoal;
    final maxBucketSteps = buckets.fold<int>(
      dailyGoal,
      (m, b) => math.max(m, b.steps),
    );

    return Container(
      key: const Key('activity_weekly_summary_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: palette.accentCoral,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.activityWeeklyTitle,
                    style: StradioTypography.soraHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceSubtle,
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                ),
                child: Text(
                  strings.activitySessionsCount(totalWeekSessions),
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.accentViolet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekly Totals Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNumber(totalWeekSteps),
                      key: const Key('activity_weekly_total_steps'),
                      style: StradioTypography.soraHeading(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.metricSteps,
                      style: StradioTypography.interLabel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${totalWeekDistKm.toStringAsFixed(2)} km',
                      key: const Key('activity_weekly_total_distance'),
                      style: StradioTypography.soraHeading(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.metricDistance,
                      style: StradioTypography.interLabel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-Day Step Trend Bar Chart
          SizedBox(
            key: const Key('activity_weekly_bar_chart'),
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildDayTrendBar(
                      palette: palette,
                      bucket: buckets[i],
                      maxSteps: maxBucketSteps,
                      dailyGoal: dailyGoal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTrendBar({
    required StradioPalette palette,
    required DailyStepBucket bucket,
    required int maxSteps,
    required int dailyGoal,
  }) {
    final ratio = maxSteps > 0
        ? (bucket.steps / maxSteps).clamp(0.0, 1.0)
        : 0.0;
    final barHeight = bucket.steps == 0 ? 6.0 : (12.0 + ratio * 52.0);
    final reachedGoal =
        !widget.profile.isOpenGoal &&
        bucket.steps >= dailyGoal &&
        bucket.steps > 0;

    final Color barColor;
    if (bucket.steps == 0) {
      barColor = palette.surfaceSubtle;
    } else if (reachedGoal) {
      barColor = StradioColors.statusLive;
    } else if (bucket.isToday) {
      barColor = palette.accentCoral;
    } else {
      barColor = palette.accentViolet.withValues(alpha: 0.72);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(StradioRadii.pill),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          bucket.shortLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StradioTypography.interLabel(
            fontSize: 10,
            fontWeight: bucket.isToday ? FontWeight.w800 : FontWeight.w600,
            color: bucket.isToday ? palette.accentCoral : palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required StradioPalette palette,
    required String filter,
    required String label,
    IconData? icon,
  }) {
    final isSelected = _selectedFilter == filter;
    final fgColor = isSelected ? Colors.white : palette.textPrimary;

    return Material(
      color: isSelected ? palette.accentCoral : palette.surface,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fgColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: StradioTypography.interLabel(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required StradioPalette palette,
    required StradioStrings strings,
    required SavedRecording rec,
  }) {
    final steps = rec.effectiveStepCount;
    final distKm = RunMetricsCalculator.estimateDistanceKm(
      steps: steps,
      activity: rec.config.activity,
      heightCm: widget.profile.validHeightCm,
    );
    final isJogging = rec.config.activity == Activity.jogging;
    final activityTag = isJogging ? 'JOG' : 'WALK';
    final hasRawSamples =
        widget.profile.developerModeEnabled && rec.samples.isNotEmpty;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(StradioRadii.card),
      child: InkWell(
        key: Key('activity_item_${rec.recordingId}'),
        borderRadius: BorderRadius.circular(StradioRadii.card),
        onTap: () => widget.onOpenRecording(rec),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StradioRadii.card),
            boxShadow: palette.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.accentCoral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(StradioRadii.control),
                ),
                child: Icon(
                  isJogging
                      ? Icons.directions_run_rounded
                      : Icons.directions_walk_rounded,
                  color: palette.accentCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${_formatNumber(steps)} ${strings.metricSteps.toLowerCase()}',
                          style: StradioTypography.soraHeading(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceSubtle,
                            borderRadius: BorderRadius.circular(
                              StradioRadii.tag,
                            ),
                          ),
                          child: Text(
                            '$activityTag · ${rec.targetBpm} BPM',
                            style: StradioTypography.interLabel(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: palette.accentViolet,
                            ),
                          ),
                        ),
                        if (hasRawSamples)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: StradioColors.statusLive.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(
                                StradioRadii.tag,
                              ),
                            ),
                            child: Text(
                              'RAW 100Hz',
                              style: StradioTypography.interLabel(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: StradioColors.statusLive,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distKm.toStringAsFixed(2)} km · ${_formatDuration(rec.durationSeconds)} · ${_formatDateLabel(rec.createdAt)}',
                      style: StradioTypography.interBody(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryCard(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Container(
      key: const Key('activity_empty_state_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.accentCoral.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_run_rounded,
              size: 26,
              color: palette.accentCoral,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.emptyActivityBody,
            textAlign: TextAlign.center,
            style: StradioTypography.interBody(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const Key('activity_empty_start_run_button'),
              onPressed: widget.onStartRunTap,
              icon: const Icon(Icons.directions_run_rounded, size: 18),
              label: Text(strings.activityStartFirstRunAction),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accentCoral,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterCard(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Container(
      key: const Key('activity_empty_filter_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            strings.activityEmptyFilterBody,
            textAlign: TextAlign.center,
            style: StradioTypography.interBody(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              key: const Key('activity_empty_filter_reset_button'),
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              child: Text(strings.activityFilterAll),
            ),
          ),
        ],
      ),
    );
  }
}

