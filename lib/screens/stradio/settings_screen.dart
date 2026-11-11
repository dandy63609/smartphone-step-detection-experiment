import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../theme/stradio_theme.dart';

/// Consumer Settings & Hidden Developer Suite screen (`v0.2.0` Milestone 6B).
///
/// Follows `docs/DESIGN.md` and `docs/EXPERIENCE.md` Flow 4:
/// - **Runner Profile & Daily Goal Card (`20px` Squircle):** Shows nickname,
///   height (`cm` for stride length calibration), and daily step goal (`3,000`,
///   `5,000`, `8,000`, `10,000`, custom, or `Open Goal`) with a modal editor
///   bottom sheet (`28px` Pebble).
/// - **Language & Theme Mode Card (`20px` Squircle):** Live EN/ID pill switcher
///   and Warm Ivory Light / Carbon Dark toggle.
/// - **Pocket & Screen-Off Guide Card (`20px` Squircle):** Honest guidance on
///   Android battery optimization (*Unrestricted*) for reliable pocket runs.
/// - **Privacy, PostHog Telemetry & Storage Card (`20px` Squircle):** Anonymous
///   telemetry opt-out switch and *Clear Workout History* action with explicit
///   confirmation dialog.
/// - **Hidden Developer & Research Tools (`20px` Squircle):** Revealed by
///   tapping `Stradio v0.2.0` 7 times. Includes 1-tap exit switch, *Open Sensor
///   Labs & Diagnostics*, *Export Research Dataset (CSV)*, and *Open E1-E8
///   Research Shell*.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onUpdateProfile,
    required this.onClearHistory,
    required this.onOpenSensorLabs,
    required this.onExportCsvDataset,
    required this.onOpenLegacyExperiment,
    this.onToggleThemeMode,
  });

  final StradioUserProfile profile;
  final ValueChanged<StradioUserProfile> onUpdateProfile;
  final Future<void> Function() onClearHistory;
  final VoidCallback onOpenSensorLabs;
  final Future<String> Function() onExportCsvDataset;
  final VoidCallback onOpenLegacyExperiment;
  final VoidCallback? onToggleThemeMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _requiredVersionTaps = 7;

  int _versionTapCount = 0;
  bool _isExportingCsv = false;
  String? _csvExportStatusText;

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

  Future<void> _showEditProfileSheet() async {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);

    final nicknameController = TextEditingController(
      text: widget.profile.nickname,
    );
    final heightController = TextEditingController(
      text: widget.profile.validHeightCm != null
          ? widget.profile.validHeightCm!.round().toString()
          : '',
    );
    final customGoalController = TextEditingController(
      text: widget.profile.dailyStepGoal.toString(),
    );

    var selectedGoal = widget.profile.dailyStepGoal;
    var isOpenGoal = widget.profile.isOpenGoal;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                child: SingleChildScrollView(
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
                              borderRadius: BorderRadius.circular(
                                StradioRadii.pill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.settingsProfileSectionTitle,
                          style: StradioTypography.soraHeading(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nickname input
                        Text(
                          strings.nicknameLabel,
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('settings_nickname_input'),
                          controller: nicknameController,
                          style: StradioTypography.interBody(
                            fontSize: 14,
                            color: palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: strings.nicknameHint,
                            filled: true,
                            fillColor: palette.surfaceSubtle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                StradioRadii.control,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Height input
                        Text(
                          strings.heightLabel,
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('settings_height_input'),
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: StradioTypography.interBody(
                            fontSize: 14,
                            color: palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: strings.heightHint,
                            suffixText: 'cm',
                            filled: true,
                            fillColor: palette.surfaceSubtle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                StradioRadii.control,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Daily Step Goal Presets + Open Goal
                        Text(
                          strings.dailyGoalSectionTitle,
                          style: StradioTypography.interLabel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final preset in const [
                              3000,
                              5000,
                              8000,
                              10000,
                            ])
                              _buildSheetGoalChip(
                                key: Key('settings_goal_chip_$preset'),
                                palette: palette,
                                label: _formatNumber(preset),
                                isSelected:
                                    !isOpenGoal && selectedGoal == preset,
                                onTap: () {
                                  setSheetState(() {
                                    isOpenGoal = false;
                                    selectedGoal = preset;
                                    customGoalController.text = preset
                                        .toString();
                                  });
                                },
                              ),
                            _buildSheetGoalChip(
                              key: const Key('settings_open_goal_chip'),
                              palette: palette,
                              label: strings.openGoalOptionLabel,
                              isSelected: isOpenGoal,
                              onTap: () {
                                setSheetState(() {
                                  isOpenGoal = true;
                                });
                              },
                            ),
                          ],
                        ),
                        if (!isOpenGoal) ...[
                          const SizedBox(height: 10),
                          TextField(
                            key: const Key('settings_custom_goal_input'),
                            controller: customGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null && parsed >= 100) {
                                setSheetState(() {
                                  selectedGoal = parsed;
                                });
                              }
                            },
                            style: StradioTypography.interBody(
                              fontSize: 14,
                              color: palette.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '5000',
                              suffixText: strings.metricSteps.toLowerCase(),
                              filled: true,
                              fillColor: palette.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  StradioRadii.control,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  child: Text(strings.settingsCancelAction),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  key: const Key(
                                    'settings_save_profile_button',
                                  ),
                                  onPressed: () {
                                    final parsedHeight = double.tryParse(
                                      heightController.text.trim(),
                                    );
                                    final validHeight =
                                        parsedHeight != null &&
                                            parsedHeight >= 100 &&
                                            parsedHeight <= 250
                                        ? parsedHeight
                                        : null;
                                    final parsedCustomGoal = int.tryParse(
                                      customGoalController.text.trim(),
                                    );
                                    final finalGoal =
                                        parsedCustomGoal != null &&
                                            parsedCustomGoal >= 100
                                        ? parsedCustomGoal
                                        : selectedGoal;

                                    widget.onUpdateProfile(
                                      widget.profile.copyWith(
                                        nickname: nicknameController.text
                                            .trim(),
                                        heightCm: validHeight,
                                        clearHeight: validHeight == null,
                                        dailyStepGoal: finalGoal,
                                        isOpenGoal: isOpenGoal,
                                      ),
                                    );
                                    Navigator.of(sheetContext).pop();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: palette.accentCoral,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    strings.settingsSaveProfileAction,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetGoalChip({
    required Key key,
    required StradioPalette palette,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? palette.accentCoral : palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Center(
              child: Text(
                label,
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

  Future<void> _confirmAndClearHistory() async {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StradioRadii.squircle),
        ),
        title: Text(
          strings.settingsClearHistoryConfirmTitle,
          style: StradioTypography.soraHeading(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        content: Text(
          strings.settingsClearHistoryConfirmBody,
          style: StradioTypography.interBody(
            fontSize: 13,
            color: palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.settingsCancelAction),
          ),
          FilledButton(
            key: const Key('confirm_clear_history_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: StradioColors.sonicCoral,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.settingsDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await widget.onClearHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.settingsClearHistoryClearedToast)),
    );
  }

  Future<void> _handleExportCsv() async {
    setState(() {
      _isExportingCsv = true;
      _csvExportStatusText = null;
    });
    final message = await widget.onExportCsvDataset();
    if (!mounted) return;
    setState(() {
      _isExportingCsv = false;
      _csvExportStatusText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;

    final heightDisplay = widget.profile.validHeightCm != null
        ? '${widget.profile.validHeightCm!.round()} cm'
        : '-';
    final goalDisplay = widget.profile.isOpenGoal
        ? strings.openGoalOptionLabel
        : '${_formatNumber(widget.profile.dailyStepGoal)} ${strings.metricSteps.toLowerCase()}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 20.0;

        return SingleChildScrollView(
          key: const Key('shell_settings_scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            16,
            horizontalPad,
            bottomClearance,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.navSettings,
                    style: StradioTypography.soraHeading(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Runner Profile & Daily Goal Card (20px Squircle)
                  Container(
                    key: const Key('settings_profile_card'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(
                        StradioRadii.squircle,
                      ),
                      boxShadow: palette.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: palette.accentCoral.withValues(
                                  alpha: 0.14,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: palette.accentCoral,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.profile.effectiveNickname,
                                    key: const Key(
                                      'settings_profile_nickname_text',
                                    ),
                                    style: StradioTypography.soraHeading(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$heightDisplay · $goalDisplay',
                                    key: const Key(
                                      'settings_profile_summary_text',
                                    ),
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
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('settings_edit_profile_button'),
                            onPressed: _showEditProfileSheet,
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(strings.settingsEditProfileAction),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Language & Theme Appearance Card (20px Squircle)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(
                        StradioRadii.squircle,
                      ),
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
                        if (widget.onToggleThemeMode != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.settingsAppearanceTitle,
                                      style: StradioTypography.soraHeading(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      strings.settingsAppearanceSubtitle,
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
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  key: const Key(
                                    'settings_theme_toggle_button',
                                  ),
                                  tooltip: strings.settingsAppearanceTitle,
                                  onPressed: widget.onToggleThemeMode,
                                  style: IconButton.styleFrom(
                                    backgroundColor: palette.surfaceSubtle,
                                    shape: const CircleBorder(),
                                  ),
                                  icon: Icon(
                                    palette.isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: palette.accentCoral,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Android Pocket & Screen-Off Guide Card (20px Squircle)
                  Container(
                    key: const Key('settings_battery_guide_card'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(
                        StradioRadii.squircle,
                      ),
                      boxShadow: palette.cardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: palette.accentViolet.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(
                              StradioRadii.control,
                            ),
                          ),
                          child: Icon(
                            Icons.battery_charging_full_rounded,
                            color: palette.accentViolet,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.settingsBatteryGuideTitle,
                                style: StradioTypography.soraHeading(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.settingsBatteryGuideSubtitle,
                                style: StradioTypography.interBody(
                                  fontSize: 12,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Privacy, Anonymous Telemetry (PostHog) & Clear History Card (20px Squircle)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(
                        StradioRadii.squircle,
                      ),
                      boxShadow: palette.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
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
                                value: widget.profile.analyticsEnabled,
                                onChanged: (enabled) {
                                  widget.onUpdateProfile(
                                    widget.profile.copyWith(
                                      analyticsEnabled: enabled,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('settings_clear_history_button'),
                            onPressed: _confirmAndClearHistory,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: StradioColors.sonicCoral,
                              size: 18,
                            ),
                            label: Text(
                              strings.settingsClearHistoryAction,
                              style: StradioTypography.interLabel(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: StradioColors.sonicCoral,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Hidden Developer & Research Tools Card (Only visible when Developer Mode is ON)
                  if (widget.profile.developerModeEnabled) ...[
                    Container(
                      key: const Key('settings_developer_tools_card'),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(
                          StradioRadii.squircle,
                        ),
                        boxShadow: palette.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  strings.settingsDevToolsTitle,
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
                                  value: widget.profile.developerModeEnabled,
                                  onChanged: (enabled) {
                                    _versionTapCount = 0;
                                    widget.onUpdateProfile(
                                      widget.profile.copyWith(
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
                          const SizedBox(height: 4),
                          Text(
                            strings.settingsDevToolsSubtitle,
                            style: StradioTypography.interBody(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action 1: Open Sensor Labs & Diagnostics
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              key: const Key(
                                'settings_open_sensor_labs_button',
                              ),
                              onPressed: widget.onOpenSensorLabs,
                              icon: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: palette.accentViolet,
                              ),
                              label: Text(strings.settingsOpenSensorLabsAction),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Action 2: Export 3-CSV Research Dataset
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              key: const Key('settings_export_csv_button'),
                              onPressed: _isExportingCsv
                                  ? null
                                  : _handleExportCsv,
                              icon: Icon(
                                Icons.download_rounded,
                                size: 18,
                                color: palette.accentCoral,
                              ),
                              label: Text(strings.settingsExportCsvAction),
                            ),
                          ),
                          if (_csvExportStatusText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _csvExportStatusText!,
                              key: const Key('settings_csv_export_status'),
                              style: StradioTypography.interBody(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),

                          // Action 3: Open E1-E8 Legacy Experiment Shell
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              key: const Key(
                                'settings_open_legacy_experiment_button',
                              ),
                              onPressed: widget.onOpenLegacyExperiment,
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                              ),
                              label: Text(
                                strings.settingsOpenLegacyShellAction,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 6. App Version 7-Tap Unlock Target
                  Center(
                    child: InkWell(
                      key: const Key('settings_version_tap_target'),
                      borderRadius: BorderRadius.circular(StradioRadii.pill),
                      onTap: () {
                        if (widget.profile.developerModeEnabled) return;
                        _versionTapCount++;
                        final remaining =
                            _requiredVersionTaps - _versionTapCount;
                        if (remaining <= 0) {
                          _versionTapCount = 0;
                          widget.onUpdateProfile(
                            widget.profile.copyWith(developerModeEnabled: true),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.devModeEnabledToast),
                            ),
                          );
                        } else if (remaining <= 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(milliseconds: 900),
                              content: Text(
                                strings.devModeTapsRemaining(remaining),
                              ),
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
      },
    );
  }

  Widget _buildSettingsLanguagePill({
    required Key key,
    required StradioPalette palette,
    required AppLanguage language,
  }) {
    final isSelected = widget.profile.language == language;
    return Material(
      color: isSelected ? palette.accentCoral : palette.surfaceSubtle,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          if (widget.profile.language == language) return;
          widget.onUpdateProfile(widget.profile.copyWith(language: language));
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

