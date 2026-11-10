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
  String get audioComingSoonNotice =>
      'Audio track integration is coming soon. This tempo is active for your next run.';
  @override
  String get emptyActivityBody =>
      'No runs recorded yet. Tap Run below to capture your first steps.';

  // --- Developer Mode ---
  @override
  String get devModeEnabledToast => 'Developer Mode enabled.';
  @override
  String get devModeDisabledToast => 'Developer Mode disabled.';
  @override
  String devModeTapsRemaining(int remaining) =>
      '$remaining taps left to enable Developer Mode.';
}

