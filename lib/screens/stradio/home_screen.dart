import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../theme/stradio_theme.dart';
import 'root_navigation_shell.dart';

/// Callback signature for launching a Quick Start preset directly from [HomeScreen].
typedef QuickStartPresetCallback =
    void Function({
      required int targetBpm,
      required Activity activity,
      String? soundscapeId,
    });

/// Primary consumer Home Screen for Stradio (`v0.2.0` Stage 4D).
///
/// Features:
/// - **Asymmetric Greeting Header (Reference 2):** Two-tone greeting with the
///   runner's nickname in `Sonic Coral` and a `48x48 dp` Light/Dark theme toggle.
/// - **Daily Goal Hero Card (`28px` Pebble):** Same-day accumulated step count,
///   animated circular progress ring (`450ms` `Curves.easeOutCubic`, respecting
///   `MediaQuery.disableAnimationsOf`), celebratory goal-reached banner, and
///   3 real metric columns (`Steps`, `Distance`, `Active Time`).
/// - **Active Soundscape Strip (`16px` Card):** Displays active tempo theme with
///   1-tap shortcut to the `Library` tab.
/// - **Quick Start Presets (`20px` Squircle Deck):** 3 tactile preset cards
///   (*Lo-Fi Pace · 118 BPM*, *Tempo Jog · 145 BPM*, *Neon Stride · 165 BPM*)
///   with `0.97x` press-scale micro-interaction.
/// - **Recent Session Highlight / Honest Empty State:** Shows the latest saved
///   run or an inviting first-run card when history is empty.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.recordings,
    required this.dailySummary,
    required this.onStartRunTap,
    required this.onQuickStartPreset,
    required this.onSwitchTab,
    this.onToggleThemeMode,
    this.onOpenRecording,
    this.referenceDate,
  });

  final StradioUserProfile profile;
  final List<SavedRecording> recordings;
  final DailyProgressSummary dailySummary;
  final VoidCallback onStartRunTap;
  final QuickStartPresetCallback onQuickStartPreset;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback? onToggleThemeMode;
  final ValueChanged<SavedRecording>? onOpenRecording;
  final DateTime? referenceDate;

  static const List<String> _quickStartIds = [
    'lofi_pace',
    'tempo_jog',
    'neon_stride',
  ];

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

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(profile.language);
    final activeTheme = StradioSoundscapeTheme.byId(profile.activeSoundscapeId);
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 20.0;

        return SingleChildScrollView(
          key: const Key('home_screen_scroll'),
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
                  _buildAsymmetricGreetingHeader(palette, strings),
                  const SizedBox(height: 18),
                  _buildDailyGoalHeroCard(
                    context: context,
                    palette: palette,
                    strings: strings,
                    disableAnimations: disableAnimations,
                  ),
                  const SizedBox(height: 14),
                  _buildActiveSoundscapeStrip(palette, strings, activeTheme),
                  const SizedBox(height: 20),
                  _buildQuickStartSection(
                    palette: palette,
                    strings: strings,
                    isTablet: isTablet,
                    disableAnimations: disableAnimations,
                  ),
                  const SizedBox(height: 20),
                  _buildRecentSessionSection(palette, strings),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsymmetricGreetingHeader(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    final nowLocal = (referenceDate ?? DateTime.now()).toLocal();
    final timeGreeting = strings.homeTimeGreeting(nowLocal.hour);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                timeGreeting,
                key: const Key('home_greeting_prefix'),
                style: StradioTypography.soraHeading(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                profile.effectiveNickname,
                key: const Key('home_greeting_nickname'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StradioTypography.soraHeading(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.accentCoral,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (onToggleThemeMode != null)
          Semantics(
            button: true,
            label: palette.isDark
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            child: SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: palette.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('home_theme_toggle_button'),
                  customBorder: const CircleBorder(),
                  onTap: onToggleThemeMode,
                  child: Icon(
                    palette.isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 20,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailyGoalHeroCard({
    required BuildContext context,
    required StradioPalette palette,
    required StradioStrings strings,
    required bool disableAnimations,
  }) {
    final goal = profile.dailyStepGoal > 0
        ? profile.dailyStepGoal
        : StradioUserProfile.defaultDailyStepGoal;
    final rawRatio = profile.isOpenGoal
        ? 1.0
        : (dailySummary.todaySteps / goal).clamp(0.0, 1.0);
    final goalReached =
        !profile.isOpenGoal && dailySummary.todaySteps >= goal;
    final ringDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 450);

    return Container(
      key: const Key('home_daily_goal_hero_card'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title + Target Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                strings.homeDailyGoalTitle,
                style: StradioTypography.soraHeading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: profile.isOpenGoal
                      ? palette.accentViolet.withValues(alpha: 0.16)
                      : palette.accentCoral.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                ),
                child: Text(
                  profile.isOpenGoal
                      ? strings.homeOpenGoalBadge
                      : strings.homeStepsOfTarget(
                          _formatNumber(dailySummary.todaySteps),
                          _formatNumber(goal),
                        ),
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: profile.isOpenGoal
                        ? palette.accentViolet
                        : palette.accentCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Center Row: Animated Progress Ring + Large Step Readout
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: rawRatio),
                duration: ringDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  final percentLabel = profile.isOpenGoal
                      ? 'OPEN'
                      : '${(animatedProgress * 100).round()}%';
                  return SizedBox(
                    width: 88,
                    height: 88,
                    child: CustomPaint(
                      painter: _DailyGoalRingPainter(
                        progress: animatedProgress,
                        trackColor: palette.surfaceSubtle,
                        activeColor: profile.isOpenGoal
                            ? palette.accentViolet
                            : (goalReached
                                  ? StradioColors.statusLive
                                  : palette.accentCoral),
                      ),
                      child: Center(
                        child: Text(
                          percentLabel,
                          style: StradioTypography.soraHeading(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNumber(dailySummary.todaySteps),
                      key: const Key('home_today_steps_value'),
                      style: StradioTypography.soraMetric(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.metricSteps,
                      style: StradioTypography.interLabel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (goalReached) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('home_goal_reached_banner'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: StradioColors.statusLive.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(StradioRadii.control),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: StradioColors.statusLive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.homeGoalReachedBanner,
                      style: StradioTypography.interBody(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 3-Column Sub-Metrics Deck (Steps | Distance | Active Time)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              borderRadius: BorderRadius.circular(StradioRadii.card),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeroSubMetric(
                    palette: palette,
                    label: strings.metricSteps,
                    value: _formatNumber(dailySummary.todaySteps),
                  ),
                ),
                Expanded(
                  child: _buildHeroSubMetric(
                    palette: palette,
                    label: strings.metricDistance,
                    value:
                        '${dailySummary.todayDistanceKm.toStringAsFixed(2)} km',
                  ),
                ),
                Expanded(
                  child: _buildHeroSubMetric(
                    palette: palette,
                    label: strings.metricActiveTime,
                    value: _formatDuration(dailySummary.todayDurationSeconds),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubMetric({
    required StradioPalette palette,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StradioTypography.interLabel(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: palette.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StradioTypography.soraHeading(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSoundscapeStrip(
    StradioPalette palette,
    StradioStrings strings,
    StradioSoundscapeTheme activeTheme,
  ) {
    return Container(
      key: const Key('home_active_soundscape_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.card),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.accentViolet.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(StradioRadii.control),
            ),
            child: Icon(
              activeTheme.icon,
              size: 22,
              color: palette.accentViolet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.activeSoundscapeLabel,
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activeTheme.title} · ${activeTheme.bpm} BPM',
                  style: StradioTypography.soraHeading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              key: const Key('home_change_soundscape_button'),
              onPressed: () => onSwitchTab(1),
              child: Text(
                strings.changeSoundscapeAction,
                style: StradioTypography.interLabel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.accentCoral,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection({
    required StradioPalette palette,
    required StradioStrings strings,
    required bool isTablet,
    required bool disableAnimations,
  }) {
    final presets = _quickStartIds
        .map(StradioSoundscapeTheme.byId)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.quickStartTitle,
          style: StradioTypography.soraHeading(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (isTablet)
          Row(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _PressableQuickStartCard(
                    cardKey: Key('home_quick_start_${presets[i].id}'),
                    palette: palette,
                    theme: presets[i],
                    language: profile.language,
                    disableAnimations: disableAnimations,
                    onTap: () => onQuickStartPreset(
                      targetBpm: presets[i].bpm,
                      activity: presets[i].activity,
                      soundscapeId: presets[i].id,
                    ),
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _PressableQuickStartCard(
                  cardKey: Key('home_quick_start_${presets[i].id}'),
                  palette: palette,
                  theme: presets[i],
                  language: profile.language,
                  disableAnimations: disableAnimations,
                  onTap: () => onQuickStartPreset(
                    targetBpm: presets[i].bpm,
                    activity: presets[i].activity,
                    soundscapeId: presets[i].id,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildRecentSessionSection(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.recentSessionTitle,
          style: StradioTypography.soraHeading(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (recordings.isEmpty)
          Container(
            key: const Key('home_empty_history_card'),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.squircle),
              boxShadow: palette.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.accentCoral.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run_rounded,
                        size: 20,
                        color: palette.accentCoral,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.emptyHomeHistoryTitle,
                        style: StradioTypography.soraHeading(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.emptyHomeHistoryBody,
                  style: StradioTypography.interBody(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('home_empty_start_run_button'),
                    onPressed: onStartRunTap,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(strings.navRun),
                  ),
                ),
              ],
            ),
          )
        else
          _buildLatestRecordingCard(palette, strings, recordings.first),
      ],
    );
  }

  Widget _buildLatestRecordingCard(
    StradioPalette palette,
    StradioStrings strings,
    SavedRecording latest,
  ) {
    final steps = latest.effectiveStepCount;
    final distKm = RunMetricsCalculator.estimateDistanceKm(
      steps: steps,
      activity: latest.config.activity,
      heightCm: profile.validHeightCm,
    );
    final bpm =
        latest.targetBpm ??
        RunMetricsCalculator.defaultTargetBpm(latest.config.activity);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(StradioRadii.squircle),
      child: InkWell(
        key: const Key('home_recent_session_card'),
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        onTap: onOpenRecording != null ? () => onOpenRecording!(latest) : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StradioRadii.squircle),
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
                  latest.config.activity == Activity.jogging
                      ? Icons.directions_run_rounded
                      : Icons.directions_walk_rounded,
                  size: 24,
                  color: palette.accentCoral,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatNumber(steps)} ${strings.metricSteps.toLowerCase()}',
                      style: StradioTypography.soraHeading(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distKm.toStringAsFixed(2)} km · ${_formatDuration(latest.durationSeconds)} · $bpm BPM',
                      style: StradioTypography.interBody(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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
}

class _PressableQuickStartCard extends StatefulWidget {
  const _PressableQuickStartCard({
    required this.cardKey,
    required this.palette,
    required this.theme,
    required this.language,
    required this.disableAnimations,
    required this.onTap,
  });

  final Key cardKey;
  final StradioPalette palette;
  final StradioSoundscapeTheme theme;
  final AppLanguage language;
  final bool disableAnimations;
  final VoidCallback onTap;

  @override
  State<_PressableQuickStartCard> createState() =>
      _PressableQuickStartCardState();
}

class _PressableQuickStartCardState extends State<_PressableQuickStartCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final theme = widget.theme;
    final scaleDuration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 100);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: scaleDuration,
      curve: Curves.easeOutCubic,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        child: InkWell(
          key: widget.cardKey,
          borderRadius: BorderRadius.circular(StradioRadii.squircle),
          onHighlightChanged: (highlighted) {
            if (_isPressed != highlighted) {
              setState(() {
                _isPressed = highlighted;
              });
            }
          },
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StradioRadii.squircle),
              boxShadow: palette.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accentCoral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(StradioRadii.control),
                  ),
                  child: Icon(
                    theme.icon,
                    size: 22,
                    color: palette.accentCoral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              theme.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StradioTypography.soraHeading(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceSubtle,
                              borderRadius: BorderRadius.circular(
                                StradioRadii.tag,
                              ),
                            ),
                            child: Text(
                              '${theme.bpm} BPM',
                              style: StradioTypography.interLabel(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: palette.accentViolet,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        theme.subtitle(widget.language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StradioTypography.interBody(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accentCoral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyGoalRingPainter extends CustomPainter {
  const _DailyGoalRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
  });

  final double progress;
  final Color trackColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0.0) return;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * clamped,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyGoalRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor;
  }
}

