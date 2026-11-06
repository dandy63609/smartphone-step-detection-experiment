import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../evaluation/run_metrics_calculator.dart';
import '../../main.dart';
import '../../models/experiment_models.dart';
import '../../services/export_service.dart';
import '../../services/posthog_service.dart';
import '../../services/recording_repository.dart';
import '../../services/recording_service.dart';
import '../../theme/stradio_theme.dart';
import '../dashboard_screen.dart';

/// Mutable configuration state shared between [ActiveRunScreen] and [SensorLabsSheet].
class StradioLabSettings {
  const StradioLabSettings({
    this.developerOverlayEnabled = false,
    this.participantId = 'P01',
    this.activity = Activity.walking,
    this.phonePlacement = PhonePlacement.hand,
    this.placementDetail = 'Right hand',
    this.primaryAlgorithm = ThresholdAlgorithm.adaptiveMidpoint,
    this.targetSteps = ExperimentConfig.defaultTargetSteps,
    this.trialNumber = 1,
    this.targetBpm = 165,
  });

  final bool developerOverlayEnabled;
  final String participantId;
  final Activity activity;
  final PhonePlacement phonePlacement;
  final String placementDetail;
  final ThresholdAlgorithm primaryAlgorithm;
  final int targetSteps;
  final int trialNumber;
  final int targetBpm;

  ExperimentConfig toExperimentConfig() => ExperimentConfig(
    participantId: participantId,
    activity: activity,
    phonePlacement: phonePlacement,
    placementDetail: placementDetail,
    trialNumber: trialNumber,
    primaryLiveAlgorithm: primaryAlgorithm,
    targetSteps: targetSteps,
  );

  StradioLabSettings copyWith({
    bool? developerOverlayEnabled,
    String? participantId,
    Activity? activity,
    PhonePlacement? phonePlacement,
    String? placementDetail,
    ThresholdAlgorithm? primaryAlgorithm,
    int? targetSteps,
    int? trialNumber,
    int? targetBpm,
  }) {
    return StradioLabSettings(
      developerOverlayEnabled:
          developerOverlayEnabled ?? this.developerOverlayEnabled,
      participantId: participantId ?? this.participantId,
      activity: activity ?? this.activity,
      phonePlacement: phonePlacement ?? this.phonePlacement,
      placementDetail: placementDetail ?? this.placementDetail,
      primaryAlgorithm: primaryAlgorithm ?? this.primaryAlgorithm,
      targetSteps: targetSteps ?? this.targetSteps,
      trialNumber: trialNumber ?? this.trialNumber,
      targetBpm: targetBpm ?? this.targetBpm,
    );
  }
}

/// Screen 4: STRADIO Sensor Labs & Experiment Overlay Drawer.
///
/// Triggered by the Labs flask icon on the Active Run Screen.
/// Provides Developer Mode Overlay toggle, 100 Hz Sensor Health diagnostics,
/// Target Ground Truth (100 Steps) calibration, PostHog Cloud status,
/// full CSV dataset export, and access to the Legacy Experiment Screen.
class SensorLabsSheet extends StatefulWidget {
  const SensorLabsSheet({
    super.key,
    required this.initialSettings,
    required this.sensorHealth,
    this.sensorHealthListenable,
    required this.sensorStreamActive,
    required this.store,
    required this.recordingService,
    required this.exportService,
    required this.postHogService,
    required this.onSettingsChanged,
    this.onBeforeOpenLegacyExperiment,
  });

  final StradioLabSettings initialSettings;
  final SensorHealthReport sensorHealth;
  final ValueListenable<SensorHealthReport>? sensorHealthListenable;
  final bool sensorStreamActive;
  final RecordingStore store;
  final RecordingService recordingService;
  final ExportService exportService;
  final PostHogTelemetryService postHogService;
  final ValueChanged<StradioLabSettings> onSettingsChanged;
  final VoidCallback? onBeforeOpenLegacyExperiment;

  @override
  State<SensorLabsSheet> createState() => _SensorLabsSheetState();
}

class _SensorLabsSheetState extends State<SensorLabsSheet> {
  late StradioLabSettings _settings;
  late final TextEditingController _targetStepsController;
  late final TextEditingController _participantIdController;
  late final TextEditingController _postHogKeyController;

  bool _exportingCsv = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _targetStepsController = TextEditingController(
      text: _settings.targetSteps.toString(),
    );
    _participantIdController = TextEditingController(
      text: _settings.participantId,
    );
    _postHogKeyController = TextEditingController(
      text: widget.postHogService.apiKey,
    );
  }

  @override
  void dispose() {
    _targetStepsController.dispose();
    _participantIdController.dispose();
    _postHogKeyController.dispose();
    super.dispose();
  }

  void _updateSettings(StradioLabSettings next) {
    setState(() {
      _settings = next;
    });
    widget.onSettingsChanged(next);
  }

  void _applyTextSettings() {
    final parsedTarget = int.tryParse(_targetStepsController.text.trim());
    final rawParticipant = _participantIdController.text.trim();
    final validTarget = (parsedTarget != null && parsedTarget > 0)
        ? parsedTarget
        : ExperimentConfig.defaultTargetSteps;
    final validParticipant = RegExp(r'^P[0-9]+$').hasMatch(rawParticipant)
        ? rawParticipant
        : 'P01';

    _targetStepsController.text = validTarget.toString();
    _participantIdController.text = validParticipant;

    _updateSettings(
      _settings.copyWith(
        targetSteps: validTarget,
        participantId: validParticipant,
      ),
    );
    setState(() {
      _statusIsError = false;
      _statusMessage =
          'Benchmark target updated: $validTarget Steps ($validParticipant).';
    });
  }

  Future<void> _applyPostHogKey() async {
    final key = _postHogKeyController.text.trim();
    await widget.postHogService.configure(apiKey: key);
    if (!mounted) return;
    setState(() {
      _statusIsError = false;
      _statusMessage = widget.postHogService.isConfigured
          ? 'PostHog Cloud active. Delivered: ${widget.postHogService.deliveredCount} events.'
          : 'PostHog running in local queue mode (enter phc_... key to sync to Cloud).';
    });
  }

  Future<void> _exportFullDataset() async {
    setState(() {
      _exportingCsv = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      final recordings = await widget.store.list();
      if (recordings.isEmpty) {
        if (!mounted) return;
        setState(() {
          _exportingCsv = false;
          _statusIsError = false;
          _statusMessage =
              'No saved recordings yet. Complete and save a run first to export CSV files.';
        });
        return;
      }

      final files = await widget.exportService.writeCsvFiles(recordings);
      final totalSamples = recordings.fold<int>(
        0,
        (sum, r) => sum + r.samples.length,
      );

      await widget.postHogService.captureCsvExported(
        distinctId: _settings.participantId,
        totalRecordingsExported: recordings.length,
        totalSamplesExported: totalSamples,
      );

      try {
        await widget.exportService.share(files);
      } on Object {
        // Sharing sheet may be unavailable in headless tests; files are still written.
      }

      if (!mounted) return;
      setState(() {
        _exportingCsv = false;
        _statusIsError = false;
        _statusMessage =
            'Exported ${files.length} CSV files (${recordings.length} trials, $totalSamples samples).';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _exportingCsv = false;
        _statusIsError = true;
        _statusMessage = 'CSV export failed: $error';
      });
    }
  }

  void _openLegacyExperimentScreen() {
    widget.onBeforeOpenLegacyExperiment?.call();
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => LegacyExperimentShell(
          store: widget.store,
          recordingService: widget.recordingService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: StradioColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StradioRadii.hero),
        ),
        border: Border(
          top: BorderSide(color: StradioColors.borderDark, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top grab handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: StradioColors.borderDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header: Title "Sensor Labs & Diagnostics" + Close "X" icon
                Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: StradioColors.rhythmViolet,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sensor Labs & Diagnostics',
                        style: StradioTypography.soraHeading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close Sensor Labs',
                      child: IconButton(
                        key: const Key('sensor_labs_close_button'),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close Sensor Labs',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(
                          Icons.close,
                          color: StradioColors.warmIvory,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Developer Mode Overlay Toggle Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StradioColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.card),
                    border: Border.all(
                      color: _settings.developerOverlayEnabled
                          ? StradioColors.sonicCoral
                          : StradioColors.borderDark,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Mode Overlay (${_settings.developerOverlayEnabled ? "ON" : "OFF"})',
                              style: StradioTypography.soraHeading(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Displays live 100Hz X/Y/Z telemetry and 4-algorithm step comparison directly over the active run screen',
                              style: StradioTypography.interBody(
                                fontSize: 13,
                                color: StradioColors.mutedIvory,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Developer Mode Overlay switch',
                        toggled: _settings.developerOverlayEnabled,
                        child: Switch(
                          key: const Key('developer_overlay_switch'),
                          value: _settings.developerOverlayEnabled,
                          onChanged: (enabled) {
                            _updateSettings(
                              _settings.copyWith(
                                developerOverlayEnabled: enabled,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Sensor Health Card (Live reactive updates via ValueListenable)
                ValueListenableBuilder<SensorHealthReport>(
                  valueListenable:
                      widget.sensorHealthListenable ??
                      ValueNotifier<SensorHealthReport>(widget.sensorHealth),
                  builder: (context, health, _) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: StradioColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(StradioRadii.card),
                        border: Border.all(color: StradioColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.sensorStreamActive
                                      ? StradioColors.statusLive
                                      : StradioColors.statusPaused,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'SensorManager Active (100 Hz)',
                                  style: StradioTypography.soraHeading(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${health.effectiveRateHz > 0 ? health.effectiveRateHz.toStringAsFixed(0) : "100"} Hz',
                                style: StradioTypography.interLabel(
                                  fontSize: 12,
                                  color: StradioColors.rhythmViolet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _DiagnosticStatItem(
                                label: 'LIVE TIMESTAMP (NS)',
                                value: health.latestTimestampNs > 0
                                    ? '${health.latestTimestampNs}'
                                    : 'Awaiting stream',
                              ),
                              _DiagnosticStatItem(
                                label: 'SAMPLE DROPS',
                                value: '${health.sampleDrops} drops',
                              ),
                              _DiagnosticStatItem(
                                label: 'BUFFERED SAMPLES',
                                value: '${health.sampleCount}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 3. Target Ground Truth Setting & Trial Protocol Config
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StradioColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.card),
                    border: Border.all(color: StradioColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Ground Truth Setting',
                        style: StradioTypography.soraHeading(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Physical step count benchmark used to compute algorithm margin of error.',
                        style: StradioTypography.interBody(
                          fontSize: 12,
                          color: StradioColors.mutedIvory,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              key: const Key('target_ground_truth_input'),
                              controller: _targetStepsController,
                              keyboardType: TextInputType.number,
                              style: StradioTypography.soraHeading(fontSize: 15),
                              decoration: const InputDecoration(
                                labelText: 'Target Ground Truth (Steps)',
                                suffixText: 'Steps',
                              ),
                              onSubmitted: (_) => _applyTextSettings(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: const Key('participant_id_input'),
                              controller: _participantIdController,
                              style: StradioTypography.soraHeading(fontSize: 15),
                              decoration: const InputDecoration(
                                labelText: 'Participant',
                                hintText: 'P01',
                              ),
                              onSubmitted: (_) => _applyTextSettings(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProtocolChip(
                            label: 'Walking',
                            selected: _settings.activity == Activity.walking,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                activity: Activity.walking,
                                targetBpm: RunMetricsCalculator.defaultTargetBpm(
                                  Activity.walking,
                                ),
                              ),
                            ),
                          ),
                          _ProtocolChip(
                            label: 'Jogging',
                            selected: _settings.activity == Activity.jogging,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                activity: Activity.jogging,
                                targetBpm: RunMetricsCalculator.defaultTargetBpm(
                                  Activity.jogging,
                                ),
                              ),
                            ),
                          ),
                          _ProtocolChip(
                            label: 'Hand',
                            selected:
                                _settings.phonePlacement == PhonePlacement.hand,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                phonePlacement: PhonePlacement.hand,
                                placementDetail: 'Right hand',
                              ),
                            ),
                          ),
                          _ProtocolChip(
                            label: 'Pocket',
                            selected:
                                _settings.phonePlacement ==
                                PhonePlacement.pocket,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                phonePlacement: PhonePlacement.pocket,
                                placementDetail: 'Front-right pocket',
                              ),
                            ),
                          ),
                          _ProtocolChip(
                            label: 'Midpoint (A1)',
                            selected:
                                _settings.primaryAlgorithm ==
                                ThresholdAlgorithm.adaptiveMidpoint,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                primaryAlgorithm:
                                    ThresholdAlgorithm.adaptiveMidpoint,
                              ),
                            ),
                          ),
                          _ProtocolChip(
                            label: 'Mean+SD (B1)',
                            selected:
                                _settings.primaryAlgorithm ==
                                ThresholdAlgorithm.meanStd,
                            onTap: () => _updateSettings(
                              _settings.copyWith(
                                primaryAlgorithm: ThresholdAlgorithm.meanStd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const Key('apply_benchmark_button'),
                          onPressed: _applyTextSettings,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Apply Benchmark Settings'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // PostHog Cloud Telemetry Config Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StradioColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(StradioRadii.card),
                    border: Border.all(color: StradioColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PostHog Cloud Admin Telemetry',
                              style: StradioTypography.soraHeading(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            widget.postHogService.isConfigured
                                ? 'Cloud Active'
                                : 'Local Queue (${widget.postHogService.queuedCount})',
                            style: StradioTypography.interLabel(
                              fontSize: 12,
                              color: widget.postHogService.isConfigured
                                  ? StradioColors.statusLive
                                  : StradioColors.rhythmViolet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('posthog_api_key_input'),
                              controller: _postHogKeyController,
                              style: StradioTypography.interBody(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'PostHog Project API Key (Optional)',
                                hintText: 'phc_your_project_key',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: const Key('sync_posthog_button'),
                            onPressed: _applyPostHogKey,
                            child: const Text('Sync'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _statusIsError
                          ? StradioColors.statusError.withValues(alpha: 0.14)
                          : StradioColors.rhythmViolet.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(StradioRadii.control),
                      border: Border.all(
                        color: _statusIsError
                            ? StradioColors.statusError
                            : StradioColors.rhythmViolet,
                      ),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: StradioTypography.interBody(
                        fontSize: 13,
                        color: StradioColors.warmIvory,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 4. Dataset Actions
                FilledButton.icon(
                  key: const Key('export_full_csv_button'),
                  onPressed: _exportingCsv ? null : _exportFullDataset,
                  icon: _exportingCsv
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: StradioColors.midnight,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _exportingCsv
                        ? 'Exporting Sensor Dataset...'
                        : 'Export Full Sensor Dataset (CSV)',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('open_legacy_experiment_button'),
                  onPressed: _openLegacyExperimentScreen,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text('Open Legacy Experiment Screen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticStatItem extends StatelessWidget {
  const _DiagnosticStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: StradioTypography.interLabel(
            fontSize: 10,
            color: StradioColors.mutedIvory,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: StradioTypography.interLabel(
            fontSize: 13,
            color: StradioColors.warmIvory,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _ProtocolChip extends StatelessWidget {
  const _ProtocolChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StradioRadii.control),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? StradioColors.sonicCoral.withValues(alpha: 0.20)
                : StradioColors.midnight,
            borderRadius: BorderRadius.circular(StradioRadii.control),
            border: Border.all(
              color: selected
                  ? StradioColors.sonicCoral
                  : StradioColors.borderDark,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: StradioTypography.interLabel(
              fontSize: 13,
              color: StradioColors.warmIvory,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hosts the Legacy E1-E8 Experiment screens inside [StepDetectionApp.lightTheme]
/// and an isolated [Navigator] so every legacy route (`DashboardScreen`,
/// `SetupScreen`, `LiveRecordingScreen`, `ResultsScreen`, `ExportScreen`)
/// renders with its intended light palette and WCAG AA contrast (R-25, R-34).
class LegacyExperimentShell extends StatelessWidget {
  const LegacyExperimentShell({
    super.key,
    required this.store,
    this.recordingService,
  });

  final RecordingStore store;
  final RecordingService? recordingService;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: StepDetectionApp.lightTheme,
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(
            store: store,
            recordingService: recordingService,
          ),
        ),
      ),
    );
  }
}

