import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartphone_step_detection_experiment/l10n/stradio_strings.dart';
import 'package:smartphone_step_detection_experiment/models/experiment_models.dart';
import 'package:smartphone_step_detection_experiment/screens/stradio/onboarding_screen.dart';
import 'package:smartphone_step_detection_experiment/services/preferences_service.dart';
import 'package:smartphone_step_detection_experiment/theme/stradio_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StradioPreferencesService.init();
  });

  Widget buildTestApp({
    Key? onboardingKey,
    StradioUserProfile initialProfile = const StradioUserProfile(),
    required ValueChanged<StradioUserProfile> onComplete,
    ValueChanged<AppLanguage>? onLanguageChanged,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? StradioTheme.lightTheme,
      home: OnboardingScreen(
        key: onboardingKey,
        initialProfile: initialProfile,
        onComplete: onComplete,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }

  testWidgets(
    'Step 1 switches language live between English and Bahasa Indonesia',
    (tester) async {
      AppLanguage? reportedLanguage;
      await tester.pumpWidget(
        buildTestApp(
          onComplete: (_) {},
          onLanguageChanged: (lang) => reportedLanguage = lang,
        ),
      );

      // Default is English
      expect(find.text('Find Your Stride Rhythm'), findsOneWidget);
      expect(find.text('100% Local Privacy'), findsOneWidget);

      // Switch to Bahasa Indonesia
      await tester.tap(find.byKey(const Key('onboarding_lang_id')));
      await tester.pumpAndSettle();

      expect(reportedLanguage, AppLanguage.id);
      expect(find.text('Temukan Ritme Langkahmu'), findsOneWidget);
      expect(find.text('Privasi Lokal 100%'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);

      // Switch back to English
      await tester.tap(find.byKey(const Key('onboarding_lang_en')));
      await tester.pumpAndSettle();

      expect(reportedLanguage, AppLanguage.en);
      expect(find.text('Continue'), findsOneWidget);
    },
  );

  testWidgets(
    'Step 2 Skip button defaults nickname to Runner and persists completed profile',
    (tester) async {
      StradioUserProfile? completed;
      await tester.pumpWidget(
        buildTestApp(onComplete: (profile) => completed = profile),
      );

      // Advance to Step 2
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_nickname_field')), findsOneWidget);

      // Type a partial nickname, then tap Skip -> should force default 'Runner'
      await tester.enterText(
        find.byKey(const Key('onboarding_nickname_field')),
        'TempName',
      );
      await tester.tap(find.byKey(const Key('onboarding_skip_nickname_button')));
      await tester.pumpAndSettle();

      expect(completed, isNotNull);
      expect(completed!.effectiveNickname, 'Runner');
      expect(completed!.hasCompletedOnboarding, isTrue);

      final persisted = StradioPreferencesService.loadUserProfile();
      expect(persisted.effectiveNickname, 'Runner');
      expect(persisted.hasCompletedOnboarding, isTrue);
    },
  );

  testWidgets(
    'Step 2 saves custom nickname, height, custom step goal, Open Goal, and PostHog opt-out',
    (tester) async {
      StradioUserProfile? completed;
      await tester.pumpWidget(
        buildTestApp(onComplete: (profile) => completed = profile),
      );

      // Advance to Step 2
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      // Enter nickname and height
      await tester.enterText(
        find.byKey(const Key('onboarding_nickname_field')),
        'Ayu',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_height_field')),
        '168',
      );

      // Select Custom step goal and enter 7500
      final customChip = find.byKey(const Key('onboarding_goal_custom'));
      await tester.ensureVisible(customChip);
      await tester.tap(customChip);
      await tester.pumpAndSettle();

      final customField = find.byKey(const Key('onboarding_custom_goal_field'));
      expect(customField, findsOneWidget);
      await tester.enterText(customField, '7500');

      // Toggle PostHog telemetry OFF
      final telemetrySwitch = find.byKey(
        const Key('onboarding_telemetry_switch'),
      );
      await tester.ensureVisible(telemetrySwitch);
      await tester.tap(telemetrySwitch);
      await tester.pumpAndSettle();

      // Complete onboarding
      await tester.tap(find.byKey(const Key('onboarding_start_button')));
      await tester.pumpAndSettle();

      expect(completed, isNotNull);
      expect(completed!.effectiveNickname, 'Ayu');
      expect(completed!.validHeightCm, 168.0);
      expect(completed!.dailyStepGoal, 7500);
      expect(completed!.isOpenGoal, isFalse);
      expect(completed!.analyticsEnabled, isFalse);
      expect(completed!.hasCompletedOnboarding, isTrue);
    },
  );

  testWidgets(
    'Renders cleanly without overflow on narrow mobile (360x640) and tablet (768x1024)',
    (tester) async {
      for (final size in const [Size(360, 640), Size(768, 1024)]) {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestApp(
            onboardingKey: ValueKey('onboarding_${size.width}x${size.height}'),
            theme: StradioTheme.darkTheme,
            onComplete: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('onboarding_continue_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Select Open Goal on Step 2
        final openChip = find.byKey(const Key('onboarding_goal_open'));
        await tester.ensureVisible(openChip);
        await tester.tap(openChip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}

