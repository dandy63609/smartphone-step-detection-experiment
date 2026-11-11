import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../theme/stradio_theme.dart';

/// Timeframe options for the interactive analytics chart in [ActivityScreen].
enum ActivityTimeRange { week, month, quarter, all }

/// Visualization types supported by the analytics chart in [ActivityScreen].
enum ActivityChartType { bar, line, split }

/// Aggregated period bucket for the interactive chart in [ActivityScreen].
class ActivityChartBucket {
  const ActivityChartBucket({
    required this.startDate,
    required this.endDate,
    required this.shortLabel,
    required this.periodLabel,
    required this.walkingSteps,
    required this.joggingSteps,
    required this.distanceKm,
    required this.sessionCount,
    required this.daySpanCount,
    required this.isCurrentBucket,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String shortLabel;
  final String periodLabel;
  final int walkingSteps;
  final int joggingSteps;
  final double distanceKm;
  final int sessionCount;
  final int daySpanCount;
  final bool isCurrentBucket;

  int get totalSteps => walkingSteps + joggingSteps;
}

/// Consumer Workout Journal & Interactive Step Analytics screen (`v0.2.0` Stage 7B).
///
/// Features:
/// - **Interactive Multi-Range & Multi-Type Analytics Card (`28px` Pebble):**
///   Supports `1W`, `1M`, `3M`, and `All` timeframes across `Bar`, smooth
///   `Line/Area`, and stacked `Activity Split` (`Walking` vs `Jogging`) views.
/// - **Click-to-Inspect Frosted Popover:** Tapping any bar or line node shows
///   a frosted glass detail card with exact period dates, steps, distance,
///   sessions, and goal completion.
/// - **Symmetrical Activity Filter Chips (`999px` Pill):** Balanced `All`,
///   `Walking`, and `Jogging` chips with `48x48 dp` touch targets.
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
  ActivityTimeRange _selectedRange = ActivityTimeRange.week;
  ActivityChartType _selectedChartType = ActivityChartType.bar;
  int? _selectedBucketIndex;

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

  String _formatShortDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _monthShortLabel(int month, AppLanguage language) {
    if (language == AppLanguage.id) {
      return const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ][(month - 1).clamp(0, 11)];
    }
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][(month - 1).clamp(0, 11)];
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

  List<ActivityChartBucket> _computePeriodBuckets(
    List<SavedRecording> sourceRecordings,
  ) {
    final now = (widget.referenceDate ?? DateTime.now()).toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final lang = widget.profile.language;

    if (_selectedRange == ActivityTimeRange.week) {
      return _buildFixedDayBuckets(
        sourceRecordings: sourceRecordings,
        todayStart: todayStart,
        bucketCount: 7,
        daysPerBucket: 1,
        labelBuilder: (start, end, isCurrent) => (
          _weekdayShortLabel(start.weekday, lang),
          '${_weekdayShortLabel(start.weekday, lang)}, ${_formatShortDate(start)}',
        ),
      );
    }

    if (_selectedRange == ActivityTimeRange.month) {
      return _buildFixedDayBuckets(
        sourceRecordings: sourceRecordings,
        todayStart: todayStart,
        bucketCount: 5,
        daysPerBucket: 6,
        labelBuilder: (start, end, isCurrent) => (
          _formatShortDate(end),
          '${_formatShortDate(start)} - ${_formatShortDate(end)}',
        ),
      );
    }

    if (_selectedRange == ActivityTimeRange.quarter) {
      return _buildFixedDayBuckets(
        sourceRecordings: sourceRecordings,
        todayStart: todayStart,
        bucketCount: 6,
        daysPerBucket: 15,
        labelBuilder: (start, end, isCurrent) => (
          _formatShortDate(end),
          '${_formatShortDate(start)} - ${_formatShortDate(end)}',
        ),
      );
    }

    // ActivityTimeRange.all -> 6 monthly buckets ending at current month
    final buckets = <ActivityChartBucket>[];
    for (var mOffset = 5; mOffset >= 0; mOffset--) {
      final monthStart = DateTime(todayStart.year, todayStart.month - mOffset);
      final nextMonthStart = DateTime(monthStart.year, monthStart.month + 1);
      final monthEnd = nextMonthStart.subtract(const Duration(days: 1));
      var walkSteps = 0;
      var jogSteps = 0;
      var distKm = 0.0;
      var sessions = 0;

      for (final rec in sourceRecordings) {
        final localRec = rec.createdAt.toLocal();
        final recDay = DateTime(localRec.year, localRec.month, localRec.day);
        if (!recDay.isBefore(monthStart) && recDay.isBefore(nextMonthStart)) {
          final steps = rec.effectiveStepCount;
          if (rec.config.activity == Activity.jogging) {
            jogSteps += steps;
          } else {
            walkSteps += steps;
          }
          distKm += RunMetricsCalculator.estimateDistanceKm(
            steps: steps,
            activity: rec.config.activity,
            heightCm: widget.profile.validHeightCm,
          );
          sessions++;
        }
      }

      final monthLabel = _monthShortLabel(monthStart.month, lang);
      buckets.add(
        ActivityChartBucket(
          startDate: monthStart,
          endDate: monthEnd,
          shortLabel: monthLabel,
          periodLabel: '$monthLabel ${monthStart.year}',
          walkingSteps: walkSteps,
          joggingSteps: jogSteps,
          distanceKm: distKm,
          sessionCount: sessions,
          daySpanCount: monthEnd.day,
          isCurrentBucket: mOffset == 0,
        ),
      );
    }
    return buckets;
  }

  List<ActivityChartBucket> _buildFixedDayBuckets({
    required List<SavedRecording> sourceRecordings,
    required DateTime todayStart,
    required int bucketCount,
    required int daysPerBucket,
    required (String, String) Function(
      DateTime start,
      DateTime end,
      bool isCurrent,
    )
    labelBuilder,
  }) {
    final buckets = <ActivityChartBucket>[];
    final totalDays = bucketCount * daysPerBucket;
    final windowStart = todayStart.subtract(Duration(days: totalDays - 1));

    for (var i = 0; i < bucketCount; i++) {
      final start = windowStart.add(Duration(days: i * daysPerBucket));
      final end = start.add(Duration(days: daysPerBucket - 1));
      final exclusiveEnd = end.add(const Duration(days: 1));
      var walkSteps = 0;
      var jogSteps = 0;
      var distKm = 0.0;
      var sessions = 0;

      for (final rec in sourceRecordings) {
        final localRec = rec.createdAt.toLocal();
        final recDay = DateTime(localRec.year, localRec.month, localRec.day);
        if (!recDay.isBefore(start) && recDay.isBefore(exclusiveEnd)) {
          final steps = rec.effectiveStepCount;
          if (rec.config.activity == Activity.jogging) {
            jogSteps += steps;
          } else {
            walkSteps += steps;
          }
          distKm += RunMetricsCalculator.estimateDistanceKm(
            steps: steps,
            activity: rec.config.activity,
            heightCm: widget.profile.validHeightCm,
          );
          sessions++;
        }
      }

      final isCurrent = i == bucketCount - 1;
      final (shortLabel, periodLabel) = labelBuilder(start, end, isCurrent);
      buckets.add(
        ActivityChartBucket(
          startDate: start,
          endDate: end,
          shortLabel: shortLabel,
          periodLabel: periodLabel,
          walkingSteps: walkSteps,
          joggingSteps: jogSteps,
          distanceKm: distKm,
          sessionCount: sessions,
          daySpanCount: daysPerBucket,
          isCurrentBucket: isCurrent,
        ),
      );
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);
    final bottomClearance = 112.0 + MediaQuery.paddingOf(context).bottom;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

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

    final periodBuckets = _computePeriodBuckets(filteredRecordings);
    final activeSelectedIndex =
        _selectedBucketIndex != null &&
            _selectedBucketIndex! >= 0 &&
            _selectedBucketIndex! < periodBuckets.length
        ? _selectedBucketIndex
        : null;

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

                  // 1. Interactive Analytics & Trend Summary Card (28px Pebble)
                  _buildAnalyticsSummaryCard(
                    palette: palette,
                    strings: strings,
                    buckets: periodBuckets,
                    selectedBucketIndex: activeSelectedIndex,
                    disableAnimations: disableAnimations,
                  ),
                  const SizedBox(height: 18),

                  // 2. Symmetrical Activity Filter Chips Row (999px Pill, 48x48 dp)
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

  Widget _buildAnalyticsSummaryCard({
    required StradioPalette palette,
    required StradioStrings strings,
    required List<ActivityChartBucket> buckets,
    required int? selectedBucketIndex,
    required bool disableAnimations,
  }) {
    final totalSteps = buckets.fold<int>(0, (s, b) => s + b.totalSteps);
    final totalDistKm = buckets.fold<double>(0.0, (s, b) => s + b.distanceKm);
    final totalSessions = buckets.fold<int>(0, (s, b) => s + b.sessionCount);

    final dailyGoal = widget.profile.dailyStepGoal > 0
        ? widget.profile.dailyStepGoal
        : StradioUserProfile.defaultDailyStepGoal;
    final avgSpan = buckets.isNotEmpty ? buckets.first.daySpanCount : 1;
    final periodTarget = dailyGoal * avgSpan;
    final maxBucketSteps = buckets.fold<int>(
      math.max(100, periodTarget),
      (m, b) => math.max(m, b.totalSteps),
    );

    final selectedBucket = selectedBucketIndex != null
        ? buckets[selectedBucketIndex]
        : null;

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
          // Header Title + Session Pill
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_rounded,
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
                  strings.activitySessionsCount(totalSessions),
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

          // Totals Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNumber(totalSteps),
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
                      '${totalDistKm.toStringAsFixed(2)} km',
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
          const SizedBox(height: 14),

          // Range Selector + Chart Type Switcher Controls
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRangePill(
                        key: const Key('activity_range_week'),
                        palette: palette,
                        range: ActivityTimeRange.week,
                        label: strings.activityRangeWeek,
                      ),
                      _buildRangePill(
                        key: const Key('activity_range_month'),
                        palette: palette,
                        range: ActivityTimeRange.month,
                        label: strings.activityRangeMonth,
                      ),
                      _buildRangePill(
                        key: const Key('activity_range_quarter'),
                        palette: palette,
                        range: ActivityTimeRange.quarter,
                        label: strings.activityRangeQuarter,
                      ),
                      _buildRangePill(
                        key: const Key('activity_range_all'),
                        palette: palette,
                        range: ActivityTimeRange.all,
                        label: strings.activityRangeAll,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: palette.surfaceSubtle,
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartTypeButton(
                      key: const Key('activity_chart_type_bar'),
                      palette: palette,
                      type: ActivityChartType.bar,
                      icon: Icons.bar_chart_rounded,
                      tooltip: strings.activityChartBarLabel,
                    ),
                    _buildChartTypeButton(
                      key: const Key('activity_chart_type_line'),
                      palette: palette,
                      type: ActivityChartType.line,
                      icon: Icons.show_chart_rounded,
                      tooltip: strings.activityChartLineLabel,
                    ),
                    _buildChartTypeButton(
                      key: const Key('activity_chart_type_split'),
                      palette: palette,
                      type: ActivityChartType.split,
                      icon: Icons.stacked_bar_chart_rounded,
                      tooltip: strings.activityChartSplitLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Interactive Chart Area
          SizedBox(
            key: const Key('activity_weekly_bar_chart'),
            height: 112,
            child: switch (_selectedChartType) {
              ActivityChartType.bar => _buildBarChartView(
                palette: palette,
                buckets: buckets,
                maxSteps: maxBucketSteps,
                dailyGoal: dailyGoal,
                selectedIndex: selectedBucketIndex,
                disableAnimations: disableAnimations,
              ),
              ActivityChartType.line => _buildLineChartView(
                palette: palette,
                buckets: buckets,
                maxSteps: maxBucketSteps,
                selectedIndex: selectedBucketIndex,
              ),
              ActivityChartType.split => _buildSplitChartView(
                palette: palette,
                buckets: buckets,
                maxSteps: maxBucketSteps,
                selectedIndex: selectedBucketIndex,
                disableAnimations: disableAnimations,
              ),
            },
          ),

          if (_selectedChartType == ActivityChartType.split) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(
                  color: palette.accentViolet,
                  label: strings.activityFilterWalking,
                  palette: palette,
                ),
                const SizedBox(width: 14),
                _buildLegendDot(
                  color: palette.accentCoral,
                  label: strings.activityFilterJogging,
                  palette: palette,
                ),
              ],
            ),
          ],

          // Click-to-Inspect Frosted Glass Info Popover (targeted accent 2 of 2)
          AnimatedSwitcher(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: selectedBucket == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey('popover_${selectedBucket.periodLabel}'),
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildBucketFrostedPopover(
                      palette: palette,
                      strings: strings,
                      bucket: selectedBucket,
                      dailyGoal: dailyGoal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangePill({
    required Key key,
    required StradioPalette palette,
    required ActivityTimeRange range,
    required String label,
  }) {
    final isSelected = _selectedRange == range;
    return Material(
      color: isSelected ? palette.accentCoral : Colors.transparent,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          setState(() {
            _selectedRange = range;
            _selectedBucketIndex = null;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 42),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: StradioTypography.interLabel(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : palette.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeButton({
    required Key key,
    required StradioPalette palette,
    required ActivityChartType type,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = _selectedChartType == type;
    return Semantics(
      button: true,
      selected: isSelected,
      label: tooltip,
      child: Material(
        color: isSelected ? palette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(StradioRadii.pill),
          onTap: () {
            setState(() {
              _selectedChartType = type;
            });
          },
          child: SizedBox(
            width: 38,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? palette.accentCoral : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartView({
    required StradioPalette palette,
    required List<ActivityChartBucket> buckets,
    required int maxSteps,
    required int dailyGoal,
    required int? selectedIndex,
    required bool disableAnimations,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < buckets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildInteractiveBarColumn(
              index: i,
              palette: palette,
              bucket: buckets[i],
              maxSteps: maxSteps,
              dailyGoal: dailyGoal,
              isSelected: selectedIndex == i,
              disableAnimations: disableAnimations,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveBarColumn({
    required int index,
    required StradioPalette palette,
    required ActivityChartBucket bucket,
    required int maxSteps,
    required int dailyGoal,
    required bool isSelected,
    required bool disableAnimations,
  }) {
    final ratio = maxSteps > 0
        ? (bucket.totalSteps / maxSteps).clamp(0.0, 1.0)
        : 0.0;
    final barHeight = bucket.totalSteps == 0 ? 8.0 : (14.0 + ratio * 64.0);
    final periodTarget = dailyGoal * bucket.daySpanCount;
    final reachedGoal =
        !widget.profile.isOpenGoal &&
        bucket.totalSteps >= periodTarget &&
        bucket.totalSteps > 0;

    final Color barColor;
    if (bucket.totalSteps == 0) {
      barColor = palette.surfaceSubtle;
    } else if (reachedGoal) {
      barColor = StradioColors.statusLive;
    } else if (bucket.isCurrentBucket || isSelected) {
      barColor = palette.accentCoral;
    } else {
      barColor = palette.accentViolet.withValues(alpha: 0.72);
    }

    return InkWell(
      key: Key('activity_chart_bucket_$index'),
      borderRadius: BorderRadius.circular(StradioRadii.control),
      onTap: () {
        setState(() {
          _selectedBucketIndex = isSelected ? null : index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(StradioRadii.pill),
                border: isSelected
                    ? Border.all(color: palette.textPrimary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bucket.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StradioTypography.interLabel(
                fontSize: 10,
                fontWeight: bucket.isCurrentBucket || isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: bucket.isCurrentBucket || isSelected
                    ? palette.accentCoral
                    : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitChartView({
    required StradioPalette palette,
    required List<ActivityChartBucket> buckets,
    required int maxSteps,
    required int? selectedIndex,
    required bool disableAnimations,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < buckets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              key: Key('activity_chart_bucket_$i'),
              borderRadius: BorderRadius.circular(StradioRadii.control),
              onTap: () {
                setState(() {
                  _selectedBucketIndex = selectedIndex == i ? null : i;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        final bucket = buckets[i];
                        final totalRatio = maxSteps > 0
                            ? (bucket.totalSteps / maxSteps).clamp(0.0, 1.0)
                            : 0.0;
                        final totalHeight = bucket.totalSteps == 0
                            ? 8.0
                            : (16.0 + totalRatio * 62.0);

                        return AnimatedContainer(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          height: totalHeight,
                          foregroundDecoration: selectedIndex == i
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    StradioRadii.pill,
                                  ),
                                  border: Border.all(
                                    color: palette.textPrimary,
                                    width: 2,
                                  ),
                                )
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              StradioRadii.pill,
                            ),
                            child: bucket.totalSteps == 0
                                ? ColoredBox(color: palette.surfaceSubtle)
                                : Column(
                                    children: [
                                      if (bucket.joggingSteps > 0)
                                        Expanded(
                                          flex: bucket.joggingSteps,
                                          child: ColoredBox(
                                            color: palette.accentCoral,
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                      if (bucket.walkingSteps > 0)
                                        Expanded(
                                          flex: bucket.walkingSteps,
                                          child: ColoredBox(
                                            color: palette.accentViolet,
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      buckets[i].shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StradioTypography.interLabel(
                        fontSize: 10,
                        fontWeight:
                            buckets[i].isCurrentBucket || selectedIndex == i
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: buckets[i].isCurrentBucket || selectedIndex == i
                            ? palette.accentCoral
                            : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineChartView({
    required StradioPalette palette,
    required List<ActivityChartBucket> buckets,
    required int maxSteps,
    required int? selectedIndex,
  }) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('activity_line_chart_canvas'),
                  painter: _ActivityLineAreaPainter(
                    buckets: buckets,
                    maxSteps: maxSteps,
                    selectedIndex: selectedIndex,
                    lineColor: palette.accentCoral,
                    fillTopColor: palette.accentCoral.withValues(alpha: 0.24),
                    fillBottomColor: palette.accentCoral.withValues(alpha: 0.0),
                    gridColor: palette.textMuted.withValues(alpha: 0.16),
                    nodeCoreColor: palette.surface,
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < buckets.length; i++)
                      Expanded(
                        child: GestureDetector(
                          key: Key('activity_chart_bucket_$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedBucketIndex = selectedIndex == i
                                  ? null
                                  : i;
                            });
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  buckets[i].shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StradioTypography.interLabel(
                    fontSize: 10,
                    fontWeight: buckets[i].isCurrentBucket || selectedIndex == i
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: buckets[i].isCurrentBucket || selectedIndex == i
                        ? palette.accentCoral
                        : palette.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot({
    required Color color,
    required String label,
    required StradioPalette palette,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: StradioTypography.interLabel(
            fontSize: 11,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBucketFrostedPopover({
    required StradioPalette palette,
    required StradioStrings strings,
    required ActivityChartBucket bucket,
    required int dailyGoal,
  }) {
    final periodTarget = dailyGoal * bucket.daySpanCount;
    final goalPct = periodTarget > 0
        ? ((bucket.totalSteps / periodTarget) * 100).round().clamp(0, 999)
        : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(StradioRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          key: const Key('activity_chart_popover'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surfaceSubtle.withValues(
              alpha: palette.isDark ? 0.82 : 0.88,
            ),
            borderRadius: BorderRadius.circular(StradioRadii.card),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: palette.isDark ? 0.08 : 0.55,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bucket.periodLabel,
                      style: StradioTypography.soraHeading(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${_formatNumber(bucket.totalSteps)} ${strings.metricSteps.toLowerCase()}',
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.accentCoral,
                          ),
                        ),
                        Text(
                          '${bucket.distanceKm.toStringAsFixed(2)} km',
                          style: StradioTypography.interBody(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          strings.activitySessionsCount(bucket.sessionCount),
                          style: StradioTypography.interBody(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                        if (!widget.profile.isOpenGoal)
                          Text(
                            '${strings.activityTooltipGoalLabel}: $goalPct%',
                            style: StradioTypography.interBody(
                              fontSize: 12,
                              color: palette.accentViolet,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  key: const Key('activity_popover_close_button'),
                  tooltip: strings.settingsCancelAction,
                  onPressed: () {
                    setState(() {
                      _selectedBucketIndex = null;
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            _selectedBucketIndex = null;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
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
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
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
                  _selectedBucketIndex = null;
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

class _ActivityLineAreaPainter extends CustomPainter {
  _ActivityLineAreaPainter({
    required this.buckets,
    required this.maxSteps,
    required this.selectedIndex,
    required this.lineColor,
    required this.fillTopColor,
    required this.fillBottomColor,
    required this.gridColor,
    required this.nodeCoreColor,
  });

  final List<ActivityChartBucket> buckets;
  final int maxSteps;
  final int? selectedIndex;
  final Color lineColor;
  final Color fillTopColor;
  final Color fillBottomColor;
  final Color gridColor;
  final Color nodeCoreColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    const topPad = 12.0;
    const bottomPad = 10.0;
    final usableHeight = math.max(12.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, topPad + usableHeight * 0.5),
      Offset(size.width, topPad + usableHeight * 0.5),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height - bottomPad),
      Offset(size.width, size.height - bottomPad),
      gridPaint,
    );

    final colWidth = size.width / buckets.length;
    final points = <Offset>[];
    for (var i = 0; i < buckets.length; i++) {
      final ratio = maxSteps > 0
          ? (buckets[i].totalSteps / maxSteps).clamp(0.0, 1.0)
          : 0.0;
      final x = colWidth * i + colWidth / 2;
      final y = size.height - bottomPad - (ratio * usableHeight);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height - bottomPad)
      ..lineTo(points.first.dx, size.height - bottomPad)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTopColor, fillBottomColor],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, usableHeight));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);

    for (var i = 0; i < points.length; i++) {
      final isSelected = selectedIndex == i;
      final radius = isSelected ? 6.5 : 4.5;
      canvas.drawCircle(points[i], radius, Paint()..color = lineColor);
      canvas.drawCircle(
        points[i],
        radius * 0.45,
        Paint()..color = nodeCoreColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityLineAreaPainter oldDelegate) {
    return oldDelegate.buckets != buckets ||
        oldDelegate.maxSteps != maxSteps ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor;
  }
}
