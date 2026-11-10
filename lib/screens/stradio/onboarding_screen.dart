import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../services/preferences_service.dart';
import '../../theme/stradio_theme.dart';
import '../../widgets/stradio_logo_widget.dart';

/// Two-step first-run onboarding flow for Stradio (`v0.2.0`).
///
/// - **Step 1 (Welcome & Local Privacy Promise):** Live language selector
///   (`English` / `Bahasa Indonesia`), brand emblem, local-first storage promise,
///   and primary Continue CTA.
/// - **Step 2 (Quick Personalization):** Optional nickname (with explicit Skip
///   button that defaults to `Runner`), optional height in cm (`100` to `240 cm`)
///   for stride-length calibration, Daily Step Goal preset chips (`3,000`,
///   `5,000`, `8,000`, `10,000`, `Custom`, or `Open Goal`), and a transparent
///   Anonymous Performance Stats (PostHog) toggle (default ON).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initialProfile = const StradioUserProfile(),
    required this.onComplete,
    this.onLanguageChanged,
  });

  final StradioUserProfile initialProfile;
  final ValueChanged<StradioUserProfile> onComplete;
  final ValueChanged<AppLanguage>? onLanguageChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _GoalPreset {
  steps3000(3000, '3,000'),
  steps5000(5000, '5,000'),
  steps8000(8000, '8,000'),
  steps10000(10000, '10,000'),
  custom(null, 'Custom'),
  openGoal(null, 'Open');

  const _GoalPreset(this.steps, this.shortLabel);
  final int? steps;
  final String shortLabel;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<int> _presetStepValues = [3000, 5000, 8000, 10000];

  int _currentStep = 0;
  late AppLanguage _language;
  late final TextEditingController _nicknameController;
  late final TextEditingController _heightController;
  late final TextEditingController _customGoalController;
  late _GoalPreset _selectedGoalPreset;
  late bool _analyticsEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProfile;
    _language = initial.language;

    final hasCustomNickname =
        initial.nickname.trim().isNotEmpty &&
        initial.nickname.trim() != StradioUserProfile.defaultNickname;
    _nicknameController = TextEditingController(
      text: hasCustomNickname ? initial.nickname.trim() : '',
    );

    _heightController = TextEditingController(
      text: initial.validHeightCm != null
          ? initial.validHeightCm!.round().toString()
          : '',
    );

    _analyticsEnabled = initial.analyticsEnabled;

    if (initial.isOpenGoal) {
      _selectedGoalPreset = _GoalPreset.openGoal;
      _customGoalController = TextEditingController(
        text: initial.dailyStepGoal.toString(),
      );
    } else if (_presetStepValues.contains(initial.dailyStepGoal)) {
      _selectedGoalPreset = switch (initial.dailyStepGoal) {
        3000 => _GoalPreset.steps3000,
        5000 => _GoalPreset.steps5000,
        8000 => _GoalPreset.steps8000,
        10000 => _GoalPreset.steps10000,
        _ => _GoalPreset.steps5000,
      };
      _customGoalController = TextEditingController(text: '6000');
    } else {
      _selectedGoalPreset = _GoalPreset.custom;
      _customGoalController = TextEditingController(
        text: initial.dailyStepGoal.toString(),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  void _selectLanguage(AppLanguage lang) {
    if (_language == lang) return;
    setState(() {
      _language = lang;
    });
    widget.onLanguageChanged?.call(lang);
  }

  StradioUserProfile _buildCompletedProfile({bool forceDefaultNickname = false}) {
    final rawNickname = forceDefaultNickname
        ? StradioUserProfile.defaultNickname
        : _nicknameController.text.trim();
    final effectiveName = rawNickname.isEmpty
        ? StradioUserProfile.defaultNickname
        : rawNickname;

    final parsedHeight = double.tryParse(_heightController.text.trim());
    final validHeight =
        (parsedHeight != null && parsedHeight >= 100.0 && parsedHeight <= 240.0)
        ? parsedHeight
        : null;

    final isOpen = _selectedGoalPreset == _GoalPreset.openGoal;
    int resolvedGoal = widget.initialProfile.dailyStepGoal;
    if (_selectedGoalPreset.steps != null) {
      resolvedGoal = _selectedGoalPreset.steps!;
    } else if (_selectedGoalPreset == _GoalPreset.custom) {
      final parsedGoal = int.tryParse(
        _customGoalController.text.replaceAll(',', '').trim(),
      );
      resolvedGoal = (parsedGoal != null && parsedGoal >= 500)
          ? parsedGoal.clamp(500, 100000)
          : StradioUserProfile.defaultDailyStepGoal;
    }

    return widget.initialProfile.copyWith(
      nickname: effectiveName,
      heightCm: validHeight,
      clearHeight: validHeight == null,
      dailyStepGoal: resolvedGoal,
      isOpenGoal: isOpen,
      language: _language,
      analyticsEnabled: _analyticsEnabled,
      hasCompletedOnboarding: true,
    );
  }

  Future<void> _completeOnboarding({bool forceDefaultNickname = false}) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });
    if (forceDefaultNickname) {
      _nicknameController.clear();
    }
    final completedProfile = _buildCompletedProfile(
      forceDefaultNickname: forceDefaultNickname,
    );
    await StradioPreferencesService.saveUserProfile(completedProfile);
    if (!mounted) return;
    widget.onComplete(completedProfile);
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(_language);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final switchDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                _buildTopBar(palette, strings),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _currentStep == 0
                        ? _buildStepOneWelcome(palette, strings)
                        : _buildStepTwoPersonalization(palette, strings),
                  ),
                ),
                _buildBottomActionBar(palette, strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(StradioPalette palette, StradioStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          if (_currentStep == 1)
            SizedBox(
              height: 48,
              child: TextButton.icon(
                key: const Key('onboarding_back_button'),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _currentStep = 0;
                  });
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: palette.textPrimary,
                ),
                label: Text(
                  strings.onboardingBackButton,
                  style: StradioTypography.interLabel(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StradioLogoWidget(
                  size: 36,
                  showWordmark: false,
                  showAmbientGlow: false,
                ),
                const SizedBox(width: 10),
                Text(
                  'STRADIO',
                  style: StradioTypography.soraHeading(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: 2.8,
                  ),
                ),
              ],
            ),
          const Spacer(),
          _buildStepPillIndicator(palette),
        ],
      ),
    );
  }

  Widget _buildStepPillIndicator(StradioPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceSubtle,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepDot(palette, isActive: _currentStep == 0),
          const SizedBox(width: 6),
          _buildStepDot(palette, isActive: _currentStep == 1),
          const SizedBox(width: 8),
          Text(
            '${_currentStep + 1} / 2',
            style: StradioTypography.interLabel(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(StradioPalette palette, {required bool isActive}) {
    return Container(
      width: isActive ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? palette.accentCoral : palette.textMuted,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
      ),
    );
  }

  Widget _buildStepOneWelcome(StradioPalette palette, StradioStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_1'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector card
          Container(
            padding: const EdgeInsets.all(16),
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
                      Icons.translate_rounded,
                      size: 18,
                      color: palette.accentViolet,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.onboardingLanguageLabel,
                        style: StradioTypography.interLabel(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageOptionPill(
                        key: const Key('onboarding_lang_en'),
                        palette: palette,
                        language: AppLanguage.en,
                        label: AppLanguage.en.nativeLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildLanguageOptionPill(
                        key: const Key('onboarding_lang_id'),
                        palette: palette,
                        language: AppLanguage.id,
                        label: AppLanguage.id.nativeLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hero Welcome & Local Privacy Card (28px Deep Pebble)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.hero),
              boxShadow: palette.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const StradioLogoWidget(
                      size: 96,
                      showWordmark: false,
                      showAmbientGlow: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.onboardingWelcomeTitle,
                  style: StradioTypography.soraHeading(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.onboardingWelcomeSubtitle,
                  style: StradioTypography.interBody(
                    fontSize: 15,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Local-first privacy assurance capsule
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: StradioColors.statusLive.withValues(
                                alpha: 0.16,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              size: 18,
                              color: StradioColors.statusLive,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.onboardingPrivacyBadge,
                              style: StradioTypography.soraHeading(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.onboardingPrivacyBody,
                        style: StradioTypography.interBody(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptionPill({
    required Key key,
    required StradioPalette palette,
    required AppLanguage language,
    required String label,
  }) {
    final isSelected = _language == language;
    return Material(
      color: isSelected ? palette.accentCoral : palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () => _selectLanguage(language),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.language_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : palette.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StradioTypography.interLabel(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : palette.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTwoPersonalization(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    final customSelected = _selectedGoalPreset == _GoalPreset.custom;
    final customLabel = _language == AppLanguage.id ? 'Kustom' : 'Custom';

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_2'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.onboardingProfileTitle,
            style: StradioTypography.soraHeading(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.onboardingProfileSubtitle,
            style: StradioTypography.interBody(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Profile & Stride Calibration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.squircle),
              boxShadow: palette.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      strings.nicknameLabel,
                      style: StradioTypography.interLabel(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        key: const Key('onboarding_skip_nickname_button'),
                        onPressed: () =>
                            _completeOnboarding(forceDefaultNickname: true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          strings.skipNicknameButton,
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.accentCoral,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  key: const Key('onboarding_nickname_field'),
                  controller: _nicknameController,
                  textInputAction: TextInputAction.next,
                  style: StradioTypography.interBody(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.nicknameHint,
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.heightLabel,
                  style: StradioTypography.interLabel(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('onboarding_height_field'),
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: StradioTypography.interBody(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.heightHint,
                    suffixText: 'cm',
                    prefixIcon: Icon(
                      Icons.straighten_rounded,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.heightHelper,
                  style: StradioTypography.interBody(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Daily Step Goal Card
          Container(
            padding: const EdgeInsets.all(20),
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
                      Icons.flag_rounded,
                      size: 18,
                      color: palette.accentCoral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.dailyGoalSectionTitle,
                        style: StradioTypography.soraHeading(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_3000'),
                      palette: palette,
                      preset: _GoalPreset.steps3000,
                      label: _GoalPreset.steps3000.shortLabel,
                    ),
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_5000'),
                      palette: palette,
                      preset: _GoalPreset.steps5000,
                      label: _GoalPreset.steps5000.shortLabel,
                    ),
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_8000'),
                      palette: palette,
                      preset: _GoalPreset.steps8000,
                      label: _GoalPreset.steps8000.shortLabel,
                    ),
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_10000'),
                      palette: palette,
                      preset: _GoalPreset.steps10000,
                      label: _GoalPreset.steps10000.shortLabel,
                    ),
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_custom'),
                      palette: palette,
                      preset: _GoalPreset.custom,
                      label: customLabel,
                    ),
                    _buildGoalPresetChip(
                      key: const Key('onboarding_goal_open'),
                      palette: palette,
                      preset: _GoalPreset.openGoal,
                      label: strings.openGoalOptionLabel,
                    ),
                  ],
                ),
                if (customSelected) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('onboarding_custom_goal_field'),
                    controller: _customGoalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: StradioTypography.interBody(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.customGoalHint,
                      prefixIcon: Icon(
                        Icons.directions_walk_rounded,
                        size: 20,
                        color: palette.accentCoral,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Anonymous Performance Stats (PostHog) Opt-Out Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(StradioRadii.squircle),
              boxShadow: palette.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accentViolet.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(StradioRadii.control),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 20,
                    color: palette.accentViolet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.telemetryToggleTitle,
                        style: StradioTypography.soraHeading(
                          fontSize: 14,
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
                  child: Center(
                    child: Switch(
                      key: const Key('onboarding_telemetry_switch'),
                      value: _analyticsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _analyticsEnabled = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPresetChip({
    required Key key,
    required StradioPalette palette,
    required _GoalPreset preset,
    required String label,
  }) {
    final isSelected = _selectedGoalPreset == preset;
    final isOpen = preset == _GoalPreset.openGoal;
    final activeBg = isOpen ? palette.accentViolet : palette.accentCoral;

    return Material(
      color: isSelected ? activeBg : palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          setState(() {
            _selectedGoalPreset = preset;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ] else if (isOpen) ...[
                  Icon(
                    Icons.all_inclusive_rounded,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: StradioTypography.interLabel(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : palette.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(StradioPalette palette, StradioStrings strings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(color: palette.canvas),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: _currentStep == 0
            ? FilledButton.icon(
                key: const Key('onboarding_continue_button'),
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(strings.onboardingContinueButton),
              )
            : FilledButton.icon(
                key: const Key('onboarding_start_button'),
                onPressed: _isSaving ? null : () => _completeOnboarding(),
                icon: const Icon(Icons.directions_run_rounded, size: 20),
                label: Text(strings.onboardingStartButton),
              ),
      ),
    );
  }
}

