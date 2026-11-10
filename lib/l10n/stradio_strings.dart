import 'stradio_strings_en.dart';
import 'stradio_strings_id.dart';

/// Supported application languages for Stradio end-user UI (`v0.2.0`).
enum AppLanguage { en, id }

extension AppLanguageCode on AppLanguage {
  /// Two-letter ISO code (`en` or `id`).
  String get code => name;

  /// Native display label shown in language selectors.
  String get nativeLabel => switch (this) {
    AppLanguage.en => 'English',
    AppLanguage.id => 'Bahasa Indonesia',
  };

  static AppLanguage parse(String? raw) => switch (raw?.trim().toLowerCase()) {
    'id' || 'indonesia' || 'bahasa indonesia' => AppLanguage.id,
    _ => AppLanguage.en,
  };
}

/// Abstract localization contract providing compile-time completeness across
/// every supported language file (`stradio_strings_en.dart`, `stradio_strings_id.dart`).
///
/// Adding a getter here forces the Dart analyzer/compiler to verify every
/// language implementation defines it.
abstract class StradioStrings {
  const StradioStrings();

  static const StradioStrings _en = StradioStringsEn();
  static const StradioStrings _id = StradioStringsId();

  /// Returns the localized string bundle for [language].
  factory StradioStrings.of(AppLanguage language) => switch (language) {
    AppLanguage.en => _en,
    AppLanguage.id => _id,
  };

  // --- Navigation (Floating Island 5-Slot) ---
  String get navHome;
  String get navLibrary;
  String get navRun;
  String get navActivity;
  String get navSettings;

  // --- Onboarding Step 1: Welcome & Privacy ---
  String get onboardingWelcomeTitle;
  String get onboardingWelcomeSubtitle;
  String get onboardingPrivacyBadge;
  String get onboardingPrivacyBody;
  String get onboardingLanguageLabel;
  String get onboardingContinueButton;

  // --- Onboarding Step 2: Quick Personalization ---
  String get onboardingProfileTitle;
  String get onboardingProfileSubtitle;
  String get nicknameLabel;
  String get nicknameHint;
  String get skipNicknameButton;
  String get heightLabel;
  String get heightHint;
  String get heightHelper;
  String get dailyGoalSectionTitle;
  String get openGoalOptionLabel;
  String get customGoalHint;
  String get telemetryToggleTitle;
  String get telemetryToggleSubtitle;
  String get onboardingStartButton;
  String get onboardingBackButton;

  // --- Home Screen ---
  String get homeGreetingPrefix;
  String get homeDailyGoalTitle;
  String get homeOpenGoalBadge;
  String homeStepsOfTarget(String current, String target);
  String get homeGoalReachedBanner;
  String get metricSteps;
  String get metricDistance;
  String get metricActiveTime;
  String get activeSoundscapeLabel;
  String get changeSoundscapeAction;
  String get quickStartTitle;
  String get recentSessionTitle;
  String get emptyHomeHistoryTitle;
  String get emptyHomeHistoryBody;

  // --- Pre-Run Goal Selector Sheet ---
  String get preRunSheetTitle;
  String get preRunContinueDailyTitle;
  String preRunRemainingStepsSubtitle(String remaining);
  String get preRunDailyAlreadyMetSubtitle;
  String get preRunOpenGoalTitle;
  String get preRunOpenGoalSubtitle;

  // --- Library & Audio Placeholder ---
  String get audioComingSoonNotice;
  String get emptyActivityBody;

  // --- Developer Mode ---
  String get devModeEnabledToast;
  String get devModeDisabledToast;
  String devModeTapsRemaining(int remaining);
}
