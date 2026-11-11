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
  String get libraryHeaderSubtitle;
  String get libraryFilterAll;
  String get libraryFilterFavorites;
  String get libraryEmptyFavoritesTitle;
  String get libraryEmptyFavoritesBody;
  String get libraryRunWithThemeAction;
  String get libraryPreviewingBadge;
  String get audioComingSoonNotice;
  String get emptyActivityBody;

  // --- Activity Journal ---
  String get activityWeeklyTitle;
  String get activityFilterAll;
  String get activityFilterWalking;
  String get activityFilterJogging;
  String activitySessionsCount(int count);
  String get activityEmptyFilterBody;
  String get activityStartFirstRunAction;

  // --- Settings & Profile ---
  String get settingsProfileSectionTitle;
  String get settingsEditProfileAction;
  String get settingsSaveProfileAction;
  String get settingsAppearanceTitle;
  String get settingsAppearanceSubtitle;
  String get settingsBatteryGuideTitle;
  String get settingsBatteryGuideSubtitle;
  String get settingsClearHistoryAction;
  String get settingsClearHistoryConfirmTitle;
  String get settingsClearHistoryConfirmBody;
  String get settingsClearHistoryClearedToast;
  String get settingsCancelAction;
  String get settingsDeleteAction;

  // --- Developer Mode ---
  String get settingsDevToolsTitle;
  String get settingsDevToolsSubtitle;
  String get settingsOpenSensorLabsAction;
  String get settingsExportCsvAction;
  String get settingsOpenLegacyShellAction;
  String get devModeEnabledToast;
  String get devModeDisabledToast;
  String devModeTapsRemaining(int remaining);
}
