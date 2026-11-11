import 'package:flutter/material.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../services/export_service.dart';
import '../../services/foreground_notification_service.dart';
import '../../services/posthog_service.dart';
import '../../services/preferences_service.dart';
import '../../services/recording_repository.dart';
import '../../services/recording_service.dart';
import '../../theme/stradio_theme.dart';
import 'active_run_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'post_run_summary_screen.dart';

/// Soundscape tempo theme metadata used across Home, Library, and Active Run.
class StradioSoundscapeTheme {
  const StradioSoundscapeTheme({
    required this.id,
    required this.title,
    required this.subtitleEn,
    required this.subtitleId,
    required this.bpm,
    required this.cadenceRangeLabel,
    required this.category,
    required this.activity,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitleEn;
  final String subtitleId;
  final int bpm;
  final String cadenceRangeLabel;
  final String category; // 'chill' | 'jog' | 'fast'
  final Activity activity;
  final IconData icon;

  String subtitle(AppLanguage language) =>
      language == AppLanguage.id ? subtitleId : subtitleEn;

  static const List<StradioSoundscapeTheme> catalog = [
    StradioSoundscapeTheme(
      id: 'chill_walk',
      title: 'Chill Walk',
      subtitleEn: 'Easy morning stroll & steady breathing',
      subtitleId: 'Jalan santai pagi & napas teratur',
      bpm: 110,
      cadenceRangeLabel: '105-115 SPM',
      category: 'chill',
      activity: Activity.walking,
      icon: Icons.wb_twilight_rounded,
    ),
    StradioSoundscapeTheme(
      id: 'lofi_pace',
      title: 'Lo-Fi Pace',
      subtitleEn: 'Brisk city walk & warm-up groove',
      subtitleId: 'Jalan cepat & ritme pemanasan hangat',
      bpm: 118,
      cadenceRangeLabel: '112-124 SPM',
      category: 'chill',
      activity: Activity.walking,
      icon: Icons.headphones_rounded,
    ),
    StradioSoundscapeTheme(
      id: 'tempo_jog',
      title: 'Tempo Jog',
      subtitleEn: 'Balanced endurance cadence for steady jogging',
      subtitleId: 'Kadensi seimbang untuk jogging konsisten',
      bpm: 145,
      cadenceRangeLabel: '140-152 SPM',
      category: 'jog',
      activity: Activity.jogging,
      icon: Icons.graphic_eq_rounded,
    ),
    StradioSoundscapeTheme(
      id: 'neon_stride',
      title: 'Neon Stride',
      subtitleEn: 'High-energy synth pulse for responsive running',
      subtitleId: 'Ketukan berenergi tinggi untuk lari responsif',
      bpm: 165,
      cadenceRangeLabel: '158-172 SPM',
      category: 'jog',
      activity: Activity.jogging,
      icon: Icons.bolt_rounded,
    ),
    StradioSoundscapeTheme(
      id: 'sprint_surge',
      title: 'Sprint Surge',
      subtitleEn: 'Peak-cadence drive for fast intervals',
      subtitleId: 'Dorongan kadensi puncak untuk interval cepat',
      bpm: 180,
      cadenceRangeLabel: '174-186 SPM',
      category: 'fast',
      activity: Activity.jogging,
      icon: Icons.speed_rounded,
    ),
  ];

  static StradioSoundscapeTheme byId(String? id) {
    for (final item in catalog) {
      if (item.id == id) return item;
    }
    return catalog[3]; // Default: Neon Stride 165 BPM
  }

  static StradioSoundscapeTheme byBpm(int bpm) {
    for (final item in catalog) {
      if (item.bpm == bpm) return item;
    }
    return catalog[3];
  }
}

/// Aggregated same-day workout progress across all sessions recorded today.
class DailyProgressSummary {
  const DailyProgressSummary({
    required this.todaySteps,
    required this.todayDistanceKm,
    required this.todayDurationSeconds,
    required this.todaySessionCount,
  });

  final int todaySteps;
  final double todayDistanceKm;
  final double todayDurationSeconds;
  final int todaySessionCount;

  /// Remaining steps needed today to reach [dailyStepGoal] (clamped >= 0).
  int remainingSteps(int dailyStepGoal) {
    final diff = dailyStepGoal - todaySteps;
    return diff > 0 ? diff : 0;
  }

  /// Calculates accumulated steps, distance, and active time for sessions on the same calendar day as [referenceDate].
  factory DailyProgressSummary.fromRecordings(
    List<SavedRecording> recordings, {
    double? heightCm,
    DateTime? referenceDate,
  }) {
    final now = (referenceDate ?? DateTime.now()).toLocal();
    var steps = 0;
    var distanceKm = 0.0;
    var durationSec = 0.0;
    var count = 0;

    for (final rec in recordings) {
      final createdLocal = rec.createdAt.toLocal();
      final isSameDay =
          createdLocal.year == now.year &&
          createdLocal.month == now.month &&
          createdLocal.day == now.day;
      if (!isSameDay) continue;

      final sessionSteps = rec.effectiveStepCount;
      steps += sessionSteps;
      distanceKm += RunMetricsCalculator.estimateDistanceKm(
        steps: sessionSteps,
        activity: rec.config.activity,
        heightCm: heightCm,
      );
      durationSec += rec.durationSeconds;
      count++;
    }

    return DailyProgressSummary(
      todaySteps: steps,
      todayDistanceKm: distanceKm,
      todayDurationSeconds: durationSec,
      todaySessionCount: count,
    );
  }
}

/// Signature for building a custom Home tab inside [RootNavigationShell].
typedef StradioHomeTabBuilder =
    Widget Function(
      BuildContext context,
      StradioUserProfile profile,
      List<SavedRecording> recordings,
      DailyProgressSummary dailySummary,
      VoidCallback onStartRunTap,
      void Function({required int targetBpm, required Activity activity, String? soundscapeId})
      onQuickStartPreset,
      ValueChanged<int> onSwitchTab,
    );

/// Root 5-slot navigation shell for Stradio (`v0.2.0`).
///
/// Hosts 4 persistent tabs (`Home`, `Library`, `Activity`, `Settings`) inside an
/// `IndexedStack` plus the elevated center `Run` / `Lari` button per
/// `assets/images/stradio-reference-3-navigation.png`.
class RootNavigationShell extends StatefulWidget {
  const RootNavigationShell({
    super.key,
    this.initialProfile,
    this.initialTabIndex = 0,
    this.store,
    this.recordingService,
    this.exportService,
    this.postHogService,
    this.foregroundService,
    this.onToggleThemeMode,
    this.onProfileChanged,
    this.homeTabBuilder,
    this.referenceDate,
  });

  final StradioUserProfile? initialProfile;
  final int initialTabIndex;
  final RecordingStore? store;
  final RecordingService? recordingService;
  final ExportService? exportService;
  final PostHogTelemetryService? postHogService;
  final ForegroundNotificationService? foregroundService;
  final VoidCallback? onToggleThemeMode;
  final ValueChanged<StradioUserProfile>? onProfileChanged;
  final StradioHomeTabBuilder? homeTabBuilder;
  final DateTime? referenceDate;

  @override
  State<RootNavigationShell> createState() => _RootNavigationShellState();
}

class _RootNavigationShellState extends State<RootNavigationShell> {
  static const int _requiredVersionTaps = 7;

  late final RecordingStore _store;
  late final RecordingService _recordingService;
  late final ExportService _exportService;
  late final PostHogTelemetryService _postHogService;
  late final ForegroundNotificationService _foregroundService;

  late StradioUserProfile _profile;
  late int _selectedTabIndex;
  List<SavedRecording> _recordings = const [];
  bool _isLoadingRecordings = true;

  // Settings Developer Mode unlock counter
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _recordingService = widget.recordingService ?? RecordingService();
    _exportService = widget.exportService ?? ExportService();
    _postHogService = widget.postHogService ?? PostHogTelemetryService();
    _foregroundService =
        widget.foregroundService ?? FlutterForegroundNotificationService();

    _profile =
        widget.initialProfile ?? StradioPreferencesService.loadUserProfile();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _postHogService.enabled = _profile.analyticsEnabled;

    _reloadRecordings();
  }

  Future<void> _reloadRecordings() async {
    final loaded = await _store.list();
    if (!mounted) return;
    setState(() {
      _recordings = loaded;
      _isLoadingRecordings = false;
    });
  }

  Future<void> _updateProfile(StradioUserProfile updated) async {
    setState(() {
      _profile = updated;
    });
    _postHogService.enabled = updated.analyticsEnabled;
    await StradioPreferencesService.saveUserProfile(updated);
    widget.onProfileChanged?.call(updated);
  }

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

  Future<void> _handleCenterRunButtonTap() async {
    final activeTheme = StradioSoundscapeTheme.byId(
      _profile.activeSoundscapeId,
    );
    if (_profile.isOpenGoal) {
      await _launchActiveRun(
        targetSteps: _profile.dailyStepGoal,
        targetBpm: activeTheme.bpm,
        activity: activeTheme.activity,
      );
      return;
    }

    final dailySummary = DailyProgressSummary.fromRecordings(
      _recordings,
      heightCm: _profile.validHeightCm,
      referenceDate: widget.referenceDate,
    );
    final remaining = dailySummary.remainingSteps(_profile.dailyStepGoal);

    if (!mounted) return;
    await _showPreRunGoalSelectorSheet(
      remainingSteps: remaining,
      activeTheme: activeTheme,
    );
  }

  Future<void> _showPreRunGoalSelectorSheet({
    required int remainingSteps,
    required StradioSoundscapeTheme activeTheme,
  }) async {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(_profile.language);
    final continueSubtitle = remainingSteps > 0
        ? strings.preRunRemainingStepsSubtitle(_formatNumber(remainingSteps))
        : strings.preRunDailyAlreadyMetSubtitle;
    final resolvedContinueTarget = remainingSteps > 0
        ? remainingSteps
        : _profile.dailyStepGoal;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(StradioRadii.hero),
                boxShadow: palette.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(StradioRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.preRunSheetTitle,
                              style: StradioTypography.soraHeading(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeTheme.title} · ${activeTheme.bpm} BPM',
                              style: StradioTypography.interLabel(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.accentViolet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Option 1: Continue Daily Target
                  _buildPreRunOptionCard(
                    key: const Key('pre_run_continue_daily_option'),
                    palette: palette,
                    icon: Icons.flag_rounded,
                    accentColor: palette.accentCoral,
                    title: strings.preRunContinueDailyTitle,
                    subtitle: continueSubtitle,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _launchActiveRun(
                        targetSteps: resolvedContinueTarget,
                        targetBpm: activeTheme.bpm,
                        activity: activeTheme.activity,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Open Goal (Free Run)
                  _buildPreRunOptionCard(
                    key: const Key('pre_run_open_goal_option'),
                    palette: palette,
                    icon: Icons.all_inclusive_rounded,
                    accentColor: palette.accentViolet,
                    title: strings.preRunOpenGoalTitle,
                    subtitle: strings.preRunOpenGoalSubtitle,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _launchActiveRun(
                        targetSteps: _profile.dailyStepGoal,
                        targetBpm: activeTheme.bpm,
                        activity: activeTheme.activity,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreRunOptionCard({
    required Key key,
    required StradioPalette palette,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.squircle),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(StradioRadii.control),
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StradioTypography.soraHeading(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: StradioTypography.interBody(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchActiveRun({
    required int targetSteps,
    required int targetBpm,
    required Activity activity,
    String? soundscapeId,
  }) async {
    if (soundscapeId != null && soundscapeId != _profile.activeSoundscapeId) {
      await _updateProfile(
        _profile.copyWith(activeSoundscapeId: soundscapeId),
      );
    }

    final savedLab = StradioPreferencesService.loadLabSettings();
    final runSettings = savedLab.copyWith(
      participantId: _profile.effectiveNickname,
      activity: activity,
      targetSteps: targetSteps > 0
          ? targetSteps
          : StradioUserProfile.defaultDailyStepGoal,
      targetBpm: targetBpm,
      primaryAlgorithm: ThresholdAlgorithm.adaptiveMidpoint,
      developerOverlayEnabled:
          _profile.developerModeEnabled && savedLab.developerOverlayEnabled,
    );
    await StradioPreferencesService.saveLabSettings(runSettings);

    final resolvedSoundscape = StradioSoundscapeTheme.byId(
      soundscapeId ?? _profile.activeSoundscapeId,
    );

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => ActiveRunScreen(
          store: _store,
          recordingService: _recordingService,
          exportService: _exportService,
          postHogService: _postHogService,
          foregroundService: _foregroundService,
          initialLabSettings: runSettings,
          onToggleThemeMode: widget.onToggleThemeMode,
          isConsumerMode: true,
          developerModeEnabled: _profile.developerModeEnabled,
          userHeightCm: _profile.validHeightCm,
          soundscapeTitle: resolvedSoundscape.title,
        ),
      ),
    );

    await _reloadRecordings();
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(_profile.language);
    final dailySummary = DailyProgressSummary.fromRecordings(
      _recordings,
      heightCm: _profile.validHeightCm,
      referenceDate: widget.referenceDate,
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                widget.homeTabBuilder != null
                    ? widget.homeTabBuilder!(
                        context,
                        _profile,
                        _recordings,
                        dailySummary,
                        _handleCenterRunButtonTap,
                        ({
                          required int targetBpm,
                          required Activity activity,
                          String? soundscapeId,
                        }) {
                          final remaining = dailySummary.remainingSteps(
                            _profile.dailyStepGoal,
                          );
                          final resolvedTarget = _profile.isOpenGoal
                              ? _profile.dailyStepGoal
                              : (remaining > 0
                                    ? remaining
                                    : _profile.dailyStepGoal);
                          _launchActiveRun(
                            targetSteps: resolvedTarget,
                            targetBpm: targetBpm,
                            activity: activity,
                            soundscapeId: soundscapeId,
                          );
                        },
                        (tabIndex) {
                          setState(() {
                            _selectedTabIndex = tabIndex.clamp(0, 3);
                          });
                        },
                      )
                    : HomeScreen(
                        profile: _profile,
                        recordings: _recordings,
                        dailySummary: dailySummary,
                        onStartRunTap: _handleCenterRunButtonTap,
                        onQuickStartPreset: ({
                          required int targetBpm,
                          required Activity activity,
                          String? soundscapeId,
                        }) {
                          final remaining = dailySummary.remainingSteps(
                            _profile.dailyStepGoal,
                          );
                          final resolvedTarget = _profile.isOpenGoal
                              ? _profile.dailyStepGoal
                              : (remaining > 0
                                    ? remaining
                                    : _profile.dailyStepGoal);
                          _launchActiveRun(
                            targetSteps: resolvedTarget,
                            targetBpm: targetBpm,
                            activity: activity,
                            soundscapeId: soundscapeId,
                          );
                        },
                        onSwitchTab: (tabIndex) {
                          setState(() {
                            _selectedTabIndex = tabIndex.clamp(0, 3);
                          });
                        },
                        onToggleThemeMode: widget.onToggleThemeMode,
                        onOpenRecording: _openRecordingSummary,
                      ),
                _buildLibraryTab(dailySummary),
                _buildActivityTab(palette, strings, dailySummary),
                _buildSettingsTab(palette, strings),
              ],
            ),
          ),

          // Floating Island 5-Slot Bottom Navigation Bar (Reference 3)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 14,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildFloatingIslandNavBar(palette, strings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIslandNavBar(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Container(
      key: const Key('floating_island_nav_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildNavTabSlot(
              key: const Key('nav_tab_home'),
              palette: palette,
              tabIndex: 0,
              activeIcon: Icons.home_rounded,
              inactiveIcon: Icons.home_outlined,
              label: strings.navHome,
            ),
          ),
          Expanded(
            child: _buildNavTabSlot(
              key: const Key('nav_tab_library'),
              palette: palette,
              tabIndex: 1,
              activeIcon: Icons.graphic_eq_rounded,
              inactiveIcon: Icons.graphic_eq_rounded,
              label: strings.navLibrary,
            ),
          ),
          Expanded(child: _buildCenterRunActionSlot(palette, strings)),
          Expanded(
            child: _buildNavTabSlot(
              key: const Key('nav_tab_activity'),
              palette: palette,
              tabIndex: 2,
              activeIcon: Icons.bar_chart_rounded,
              inactiveIcon: Icons.bar_chart_rounded,
              label: strings.navActivity,
            ),
          ),
          Expanded(
            child: _buildNavTabSlot(
              key: const Key('nav_tab_settings'),
              palette: palette,
              tabIndex: 3,
              activeIcon: Icons.settings_rounded,
              inactiveIcon: Icons.settings_outlined,
              label: strings.navSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabSlot({
    required Key key,
    required StradioPalette palette,
    required int tabIndex,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == tabIndex;
    final tint = isSelected ? palette.accentCoral : palette.textSecondary;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(StradioRadii.card),
          onTap: () {
            if (_selectedTabIndex == tabIndex) return;
            setState(() {
              _selectedTabIndex = tabIndex;
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 22,
                    color: tint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: tint,
                      letterSpacing: 0.2,
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

  /// Elevated center Sonic Coral circle with official vector icon and small
  /// "Run" / "Lari" label underneath per `stradio-reference-3-navigation.png`.
  Widget _buildCenterRunActionSlot(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Semantics(
      button: true,
      label: strings.navRun,
      child: GestureDetector(
        key: const Key('nav_center_run_button'),
        behavior: HitTestBehavior.opaque,
        onTap: _handleCenterRunButtonTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64, minWidth: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: StradioColors.sonicCoral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: StradioColors.sonicCoral.withValues(alpha: 0.34),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.navRun,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StradioTypography.interLabel(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecordingSummary(SavedRecording rec) {
    final steps = rec.effectiveStepCount;
    final primaryDetections =
        rec.replayDetections[rec.config.primaryLiveAlgorithm] ??
        const <DetectionEvent>[];
    final summaryMetrics = RunMetricsCalculator.computeSummary(
      detections: primaryDetections,
      samples: rec.samples,
      activity: rec.config.activity,
      activeDurationSeconds: rec.durationSeconds,
      targetBpm: rec.targetBpm,
      heightCm: _profile.validHeightCm,
      overrideStepCount: steps,
      fallbackCadenceBucketsSpm: rec.summaryCadenceBucketsSpm,
    );
    final healthReport = RunMetricsCalculator.analyzeSensorHealth(
      samples: rec.samples,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PostRunSummaryScreen(
          recording: rec,
          metrics: summaryMetrics,
          sensorHealth: healthReport,
          store: _store,
          postHogService: _postHogService,
          developerModeEnabled: _profile.developerModeEnabled,
        ),
      ),
    );
  }

  Widget _buildLibraryTab(DailyProgressSummary dailySummary) {
    return LibraryScreen(
      profile: _profile,
      onSelectTheme: (theme) {
        _updateProfile(_profile.copyWith(activeSoundscapeId: theme.id));
      },
      onToggleFavorite: (themeId) {
        final nextFavs = Set<String>.from(_profile.favoriteSoundscapeIds);
        if (nextFavs.contains(themeId)) {
          nextFavs.remove(themeId);
        } else {
          nextFavs.add(themeId);
        }
        _updateProfile(_profile.copyWith(favoriteSoundscapeIds: nextFavs));
      },
      onStartRunWithTheme: (theme) {
        final remaining = dailySummary.remainingSteps(_profile.dailyStepGoal);
        final resolvedTarget = _profile.isOpenGoal
            ? _profile.dailyStepGoal
            : (remaining > 0 ? remaining : _profile.dailyStepGoal);
        _launchActiveRun(
          targetSteps: resolvedTarget,
          targetBpm: theme.bpm,
          activity: theme.activity,
          soundscapeId: theme.id,
        );
      },
      onOpenGoalSelectorForTheme: (theme) async {
        await _updateProfile(_profile.copyWith(activeSoundscapeId: theme.id));
        if (!mounted) return;
        final remaining = dailySummary.remainingSteps(_profile.dailyStepGoal);
        await _showPreRunGoalSelectorSheet(
          remainingSteps: remaining,
          activeTheme: theme,
        );
      },
    );
  }

  Widget _buildActivityTab(
    StradioPalette palette,
    StradioStrings strings,
    DailyProgressSummary dailySummary,
  ) {
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      key: const Key('shell_activity_scroll'),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomClearance),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.navActivity,
                style: StradioTypography.soraHeading(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (_isLoadingRecordings)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recordings.isEmpty)
                Container(
                  key: const Key('activity_empty_state_card'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(StradioRadii.squircle),
                    boxShadow: palette.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_run_rounded,
                        size: 40,
                        color: palette.accentCoral,
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
                    ],
                  ),
                )
              else
                ..._recordings.map((rec) {
                  final steps = rec.effectiveStepCount;
                  final distKm = RunMetricsCalculator.estimateDistanceKm(
                    steps: steps,
                    activity: rec.config.activity,
                    heightCm: _profile.validHeightCm,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(StradioRadii.card),
                      child: InkWell(
                        key: Key('activity_item_${rec.recordingId}'),
                        borderRadius: BorderRadius.circular(StradioRadii.card),
                        onTap: () => _openRecordingSummary(rec),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              StradioRadii.card,
                            ),
                            boxShadow: palette.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: palette.accentCoral.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    StradioRadii.control,
                                  ),
                                ),
                                child: Icon(
                                  rec.config.activity == Activity.jogging
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
                                      '${distKm.toStringAsFixed(2)} km · ${_formatDuration(rec.durationSeconds)}',
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
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(StradioPalette palette, StradioStrings strings) {
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      key: const Key('shell_settings_scroll'),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomClearance),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.navSettings,
                style: StradioTypography.soraHeading(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Language Switch Card (Live instant sync across Shell & Tabs)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(StradioRadii.squircle),
                  boxShadow: palette.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.onboardingLanguageLabel,
                      style: StradioTypography.soraHeading(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSettingsLanguagePill(
                            key: const Key('settings_lang_en'),
                            palette: palette,
                            language: AppLanguage.en,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSettingsLanguagePill(
                            key: const Key('settings_lang_id'),
                            palette: palette,
                            language: AppLanguage.id,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Anonymous Telemetry (PostHog) Opt-Out Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(StradioRadii.squircle),
                  boxShadow: palette.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.telemetryToggleTitle,
                            style: StradioTypography.soraHeading(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.telemetryToggleSubtitle,
                            style: StradioTypography.interBody(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: Switch(
                        key: const Key('settings_telemetry_switch'),
                        value: _profile.analyticsEnabled,
                        onChanged: (enabled) {
                          _updateProfile(
                            _profile.copyWith(analyticsEnabled: enabled),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Hidden Developer & Research Tools Card (Only visible when Developer Mode is ON)
              if (_profile.developerModeEnabled) ...[
                Container(
                  key: const Key('settings_developer_tools_card'),
                  padding: const EdgeInsets.all(18),
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
                          Icon(
                            Icons.science_rounded,
                            size: 20,
                            color: palette.accentViolet,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Developer & Research Tools',
                              style: StradioTypography.soraHeading(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            child: Switch(
                              key: const Key('settings_dev_mode_switch'),
                              value: _profile.developerModeEnabled,
                              onChanged: (enabled) {
                                _versionTapCount = 0;
                                _updateProfile(
                                  _profile.copyWith(
                                    developerModeEnabled: enabled,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      enabled
                                          ? strings.devModeEnabledToast
                                          : strings.devModeDisabledToast,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // App Version 7-Tap Unlock Target
              Center(
                child: InkWell(
                  key: const Key('settings_version_tap_target'),
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                  onTap: () {
                    if (_profile.developerModeEnabled) return;
                    _versionTapCount++;
                    final remaining = _requiredVersionTaps - _versionTapCount;
                    if (remaining <= 0) {
                      _versionTapCount = 0;
                      _updateProfile(
                        _profile.copyWith(developerModeEnabled: true),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.devModeEnabledToast)),
                      );
                    } else if (remaining <= 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 900),
                          content: Text(strings.devModeTapsRemaining(remaining)),
                        ),
                      );
                    }
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 120,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          'Stradio v0.2.0',
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsLanguagePill({
    required Key key,
    required StradioPalette palette,
    required AppLanguage language,
  }) {
    final isSelected = _profile.language == language;
    return Material(
      color: isSelected ? palette.accentCoral : palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          if (_profile.language == language) return;
          _updateProfile(_profile.copyWith(language: language));
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Center(
              child: Text(
                language.nativeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StradioTypography.interLabel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : palette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
