import 'stradio_strings.dart';

/// English translation implementation (default application language).
class StradioStringsEn extends StradioStrings {
  const StradioStringsEn();

  // --- Navigation (Floating Island 5-Slot) ---
  @override
  String get navHome => 'Home';
  @override
  String get navLibrary => 'Library';
  @override
  String get navRun => 'Run';
  @override
  String get navActivity => 'Activity';
  @override
  String get navSettings => 'Settings';

  // --- Onboarding Step 1: Welcome & Privacy ---
  @override
  String get onboardingWelcomeTitle => 'Find Your Stride Rhythm';
  @override
  String get onboardingWelcomeSubtitle =>
      'Sync your walking and running steps with responsive musical tempo.';
  @override
  String get onboardingPrivacyBadge => '100% Local Privacy';
  @override
  String get onboardingPrivacyBody =>
      'Your profile and workout history stay on this device. No account needed.';
  @override
  String get onboardingLanguageLabel => 'Choose App Language';
  @override
  String get onboardingContinueButton => 'Continue';

  // --- Onboarding Step 2: Quick Personalization ---
  @override
  String get onboardingProfileTitle => 'Quick Personalization';
  @override
  String get onboardingProfileSubtitle =>
      'Tailor your greeting and stride distance estimate. You can change this anytime in Settings.';
  @override
  String get nicknameLabel => 'Nickname';
  @override
  String get nicknameHint => 'E.g. Raka (optional)';
  @override
  String get skipNicknameButton => 'Skip (Use "Runner")';
  @override
  String get heightLabel => 'Height (cm, optional)';
  @override
  String get heightHint => 'Example: 170';
  @override
  String get heightHelper =>
      'Used to estimate your stride length and distance more accurately.';
  @override
  String get dailyGoalSectionTitle => 'Daily Step Goal';
  @override
  String get openGoalOptionLabel => 'Open Goal (No Limit)';
  @override
  String get customGoalHint => 'Custom step target';
  @override
  String get telemetryToggleTitle => 'Anonymous Performance Stats';
  @override
  String get telemetryToggleSubtitle =>
      'Share anonymous workout & step-accuracy stats to help improve Stradio. Name and raw sensor files stay private.';
  @override
  String get onboardingStartButton => 'Start Using Stradio';
  @override
  String get onboardingBackButton => 'Back';

  // --- Home Screen ---
  @override
  String get homeGreetingPrefix => 'Hello again,';
  @override
  String homeTimeGreeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 21) return 'Good evening,';
    return 'Night stride,';
  }

  @override
  String get homeDailyGoalTitle => 'Today\'s Progress';
  @override
  String get homeOpenGoalBadge => 'Open Goal Today';
  @override
  String homeStepsOfTarget(String current, String target) =>
      '$current / $target steps';
  @override
  String get homeGoalReachedBanner =>
      'Daily goal reached. Keep going or rest whenever you are ready.';
  @override
  String get metricSteps => 'STEPS';
  @override
  String get metricDistance => 'DISTANCE';
  @override
  String get metricActiveTime => 'ACTIVE TIME';
  @override
  String get activeSoundscapeLabel => 'Active Tempo Theme';
  @override
  String get changeSoundscapeAction => 'Change';
  @override
  String get quickStartTitle => 'Quick Start';
  @override
  String get recentSessionTitle => 'Recent Session';
  @override
  String get emptyHomeHistoryTitle => 'Ready for your first stride?';
  @override
  String get emptyHomeHistoryBody =>
      'Pick a Quick Start tempo above or tap the center Run button below.';

  // --- Pre-Run Goal Selector Sheet ---
  @override
  String get preRunSheetTitle => 'Choose Session Goal Mode';
  @override
  String get preRunContinueDailyTitle => 'Continue Daily Target';
  @override
  String preRunRemainingStepsSubtitle(String remaining) =>
      '$remaining steps left to reach today\'s goal.';
  @override
  String get preRunDailyAlreadyMetSubtitle =>
      'Today\'s target is already met. Add bonus steps to your day.';
  @override
  String get preRunOpenGoalTitle => 'Open Goal (Free Run)';
  @override
  String get preRunOpenGoalSubtitle => 'Move freely with no step limit.';

  // --- Library & Audio Placeholder ---
  @override
  String get libraryHeaderSubtitle =>
      'Match your stride cadence with a responsive tempo theme.';
  @override
  String get libraryFilterAll => 'All';
  @override
  String get libraryFilterFavorites => 'Favorites';
  @override
  String get libraryEmptyFavoritesTitle => 'No favorite themes yet';
  @override
  String get libraryEmptyFavoritesBody =>
      'Tap the heart icon on any tempo theme to save it here for quick access.';
  @override
  String get libraryRunWithThemeAction => 'Run This Tempo';
  @override
  String get libraryPreviewingBadge => 'Previewing Tempo';
  @override
  String get audioComingSoonNotice =>
      'Audio track integration is coming soon. This tempo is active for your next run.';
  @override
  String get emptyActivityBody =>
      'No runs recorded yet. Tap Run below to capture your first steps.';

  // --- Activity Journal ---
  @override
  String get activityWeeklyTitle => 'Step Trend';
  @override
  String get activityRangeWeek => '1W';
  @override
  String get activityRangeMonth => '1M';
  @override
  String get activityRangeQuarter => '3M';
  @override
  String get activityRangeAll => 'All';
  @override
  String get activityChartBarLabel => 'Bar';
  @override
  String get activityChartLineLabel => 'Line';
  @override
  String get activityChartSplitLabel => 'Split';
  @override
  String get activityTooltipGoalLabel => 'Daily goal';
  @override
  String get activityFilterAll => 'All';
  @override
  String get activityFilterWalking => 'Walking';
  @override
  String get activityFilterJogging => 'Jogging';
  @override
  String activitySessionsCount(int count) =>
      count == 1 ? '1 session' : '$count sessions';
  @override
  String get activityEmptyFilterBody =>
      'No sessions match this activity filter.';
  @override
  String get activityStartFirstRunAction => 'Start First Run';

  // --- Active Run & Soundscape Picker ---
  @override
  String get tempoPickerTitle => 'Choose Running Tempo';
  @override
  String get tempoPickerSubtitle =>
      'Pick a target BPM soundscape to sync with your stride.';
  @override
  String get placementHandLabel => 'Hand';
  @override
  String get placementPocketLabel => 'Pocket';

  // --- Settings & Profile ---
  @override
  String get settingsProfileSectionTitle => 'Runner Profile & Daily Goal';
  @override
  String get settingsEditProfileAction => 'Edit Profile & Goal';
  @override
  String get settingsSaveProfileAction => 'Save Changes';
  @override
  String get settingsAppearanceTitle => 'Theme Mode';
  @override
  String get settingsAppearanceSubtitle =>
      'Switch between Warm Ivory Light and Carbon Dark';
  @override
  String get settingsBatteryGuideTitle => 'Pocket & Screen-Off Guide';
  @override
  String get settingsBatteryGuideSubtitle =>
      'Set battery usage to Unrestricted so Android does not pause step detection while your phone is in your pocket.';
  @override
  String get settingsClearHistoryAction => 'Clear Workout History';
  @override
  String get settingsClearHistoryConfirmTitle => 'Clear all workout history?';
  @override
  String get settingsClearHistoryConfirmBody =>
      'This permanently deletes all saved runs and resets today\'s progress on this device.';
  @override
  String get settingsClearHistoryClearedToast => 'Workout history cleared.';
  @override
  String get settingsCancelAction => 'Cancel';
  @override
  String get settingsDeleteAction => 'Delete All';

  // --- Developer Mode ---
  @override
  String get settingsDevToolsTitle => 'Developer & Research Tools';
  @override
  String get settingsDevToolsSubtitle =>
      '100 Hz raw sample recording, 4-algorithm scoreboard, and CSV dataset export are active.';
  @override
  String get settingsOpenSensorLabsAction => 'Open Sensor Labs & Diagnostics';
  @override
  String get settingsExportCsvAction => 'Export Research Dataset (CSV)';
  @override
  String get settingsOpenLegacyShellAction => 'Open E1-E8 Research Shell';
  @override
  String get devModeEnabledToast => 'Developer Mode enabled.';
  @override
  String get devModeDisabledToast => 'Developer Mode disabled.';
  @override
  String devModeTapsRemaining(int remaining) =>
      '$remaining taps left to enable Developer Mode.';
}

