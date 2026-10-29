import 'package:flutter/material.dart';

import '../models/experiment_models.dart';
import '../services/recording_repository.dart';
import '../services/recording_service.dart';
import 'live_recording_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    this.initialConfig,
    this.store,
    this.recordingService,
  });

  final ExperimentConfig? initialConfig;
  final RecordingStore? store;
  final RecordingService? recordingService;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final RecordingStore _store;
  late final RecordingService _recordingService;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _participantController;
  late final TextEditingController _placementDetailController;
  late final TextEditingController _trialNumberController;
  late final TextEditingController _targetStepsController;
  late final TextEditingController _fallbackTimeoutController;
  late final TextEditingController _notesController;

  // Advanced parameters
  late final TextEditingController _samplingRateController;
  late final TextEditingController _smoothingController;
  late final TextEditingController _windowController;
  late final TextEditingController _minimumIntervalController;
  late final TextEditingController _kController;
  late final TextEditingController _noiseFloorController;

  late Activity _activity;
  late PhonePlacement _phonePlacement;
  late ThresholdAlgorithm _primaryLiveAlgorithm;

  String? _recordingId;
  bool _checkingSensor = true;
  bool _sensorAvailable = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _recordingService = widget.recordingService ?? RecordingService();

    final c = widget.initialConfig ??
        const ExperimentConfig(
          participantId: 'P01',
          activity: Activity.walking,
          phonePlacement: PhonePlacement.hand,
          placementDetail: 'right hand',
          trialNumber: 1,
        );

    _activity = c.activity;
    _phonePlacement = c.phonePlacement;
    _primaryLiveAlgorithm = c.primaryLiveAlgorithm;

    _participantController = TextEditingController(text: c.participantId);
    _placementDetailController = TextEditingController(text: c.placementDetail);
    _trialNumberController = TextEditingController(text: '${c.trialNumber}');
    _targetStepsController = TextEditingController(text: '${c.targetSteps}');
    _fallbackTimeoutController = TextEditingController(
      text: c.fallbackTimeoutSeconds > 0 ? '${c.fallbackTimeoutSeconds}' : '0',
    );
    _notesController = TextEditingController(text: c.notes);

    _samplingRateController = TextEditingController(
      text: '${c.requestedSamplingRateHz.toInt()}',
    );
    _smoothingController = TextEditingController(
      text: '${c.parameters.smoothingSamples}',
    );
    _windowController = TextEditingController(
      text: '${c.parameters.windowDurationMs}',
    );
    _minimumIntervalController = TextEditingController(
      text: '${c.parameters.minimumStepIntervalMs}',
    );
    _kController = TextEditingController(text: '${c.parameters.k}');
    _noiseFloorController = TextEditingController(
      text: '${c.parameters.minWindowSpreadMps2}',
    );

    _initAsync();
  }

  Future<void> _initAsync() async {
    final nextId = await _store.nextId(DateTime.now());
    final sensorOk = await _recordingService.isAccelerometerAvailable();
    if (!mounted) return;
    setState(() {
      _recordingId = nextId;
      _sensorAvailable = sensorOk;
      _checkingSensor = false;
    });
  }

  @override
  void dispose() {
    _participantController.dispose();
    _placementDetailController.dispose();
    _trialNumberController.dispose();
    _targetStepsController.dispose();
    _fallbackTimeoutController.dispose();
    _notesController.dispose();
    _samplingRateController.dispose();
    _smoothingController.dispose();
    _windowController.dispose();
    _minimumIntervalController.dispose();
    _kController.dispose();
    _noiseFloorController.dispose();
    super.dispose();
  }

  ExperimentConfig _buildConfig() {
    return ExperimentConfig(
      participantId: _participantController.text.trim(),
      activity: _activity,
      phonePlacement: _phonePlacement,
      placementDetail: _placementDetailController.text.trim(),
      trialNumber: int.tryParse(_trialNumberController.text) ?? 1,
      primaryLiveAlgorithm: _primaryLiveAlgorithm,
      targetSteps: int.tryParse(_targetStepsController.text) ?? 100,
      fallbackTimeoutSeconds:
          int.tryParse(_fallbackTimeoutController.text) ?? 0,
      notes: _notesController.text.trim(),
      requestedSamplingRateHz:
          double.tryParse(_samplingRateController.text) ?? 100.0,
      parameters: AlgorithmParameters(
        smoothingSamples: int.tryParse(_smoothingController.text) ?? 3,
        windowDurationMs: int.tryParse(_windowController.text) ?? 1000,
        minimumStepIntervalMs:
            int.tryParse(_minimumIntervalController.text) ?? 250,
        k: double.tryParse(_kController.text) ?? 1.5,
        minWindowSpreadMps2:
            double.tryParse(_noiseFloorController.text) ?? 1.2,
      ),
    );
  }

  void _startTrial() {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    final errors = config.validate();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }

    final recId = _recordingId;
    if (recId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveRecordingScreen(
          config: config,
          recordingId: recId,
          store: _store,
          recordingService: _recordingService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCondition = conditionId(
      _activity,
      _phonePlacement,
      _primaryLiveAlgorithm,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Experiment Trial'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Condition & Sensor Status Header Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE1E6EF)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        currentCondition,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _recordingId ?? 'Generating ID...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _checkingSensor
                                  ? const Color(0xFFF3F6FC)
                                  : _sensorAvailable
                                  ? const Color(0xFFE6F4EA)
                                  : const Color(0xFFFEF7E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _checkingSensor
                                      ? Icons.hourglass_top_rounded
                                      : _sensorAvailable
                                      ? Icons.sensors_rounded
                                      : Icons.info_outline_rounded,
                                  size: 14,
                                  color: _checkingSensor
                                      ? const Color(0xFF5F6368)
                                      : _sensorAvailable
                                      ? const Color(0xFF137333)
                                      : const Color(0xFFB06000),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _checkingSensor
                                        ? 'Checking accelerometer...'
                                        : _sensorAvailable
                                        ? 'Accelerometer Ready'
                                        : 'Simulator / Mock Sensor Mode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _checkingSensor
                                          ? const Color(0xFF5F6368)
                                          : _sensorAvailable
                                          ? const Color(0xFF137333)
                                          : const Color(0xFFB06000),
                                    ),
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
              ),
              const SizedBox(height: 16),

              // Section 1: Participant & Trial Info
              _sectionCard(
                title: 'Participant & Trial Protocol',
                icon: Icons.badge_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _participantController,
                          decoration: const InputDecoration(
                            labelText: 'Participant ID',
                            hintText: 'e.g. P01',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _trialNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Trial #',
                            hintText: '1-5',
                          ),
                          validator: (val) =>
                              int.tryParse(val ?? '') == null ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _targetStepsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ground Truth Steps',
                            hintText: '100',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fallbackTimeoutController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fallback Timeout (s)',
                            hintText: '0 = manual',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Experimental Factors (M3 Segmented Controls)
              _sectionCard(
                title: 'Experimental Factors',
                icon: Icons.tune_rounded,
                children: [
                  const Text(
                    'Factor C: Activity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444746),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<Activity>(
                      segments: const [
                        ButtonSegment(
                          value: Activity.walking,
                          icon: Icon(Icons.directions_walk_rounded, size: 18),
                          label: Text('Walking'),
                        ),
                        ButtonSegment(
                          value: Activity.jogging,
                          icon: Icon(Icons.directions_run_rounded, size: 18),
                          label: Text('Jogging'),
                        ),
                      ],
                      selected: {_activity},
                      onSelectionChanged: (s) =>
                          setState(() => _activity = s.first),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Factor B: Phone Placement',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444746),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<PhonePlacement>(
                      segments: const [
                        ButtonSegment(
                          value: PhonePlacement.hand,
                          icon: Icon(Icons.back_hand_outlined, size: 18),
                          label: Text('Hand-held'),
                        ),
                        ButtonSegment(
                          value: PhonePlacement.pocket,
                          icon: Icon(Icons.checkroom_rounded, size: 18),
                          label: Text('Pocket'),
                        ),
                      ],
                      selected: {_phonePlacement},
                      onSelectionChanged: (s) {
                        final val = s.first;
                        setState(() {
                          _phonePlacement = val;
                          if (val == PhonePlacement.hand) {
                            _placementDetailController.text = 'right hand';
                          } else {
                            _placementDetailController.text =
                                'front-right pocket';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placementDetailController,
                    decoration: const InputDecoration(
                      labelText: 'Placement Detail',
                      hintText: 'e.g. right hand, front-right pocket',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Primary Live Algorithm (Factor A)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444746),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThresholdAlgorithm>(
                      segments: const [
                        ButtonSegment(
                          value: ThresholdAlgorithm.adaptiveMidpoint,
                          icon: Icon(Icons.align_vertical_center_rounded, size: 18),
                          label: Text('Midpoint'),
                        ),
                        ButtonSegment(
                          value: ThresholdAlgorithm.meanStd,
                          icon: Icon(Icons.show_chart_rounded, size: 18),
                          label: Text('Mean + k·SD'),
                        ),
                      ],
                      selected: {_primaryLiveAlgorithm},
                      onSelectionChanged: (s) =>
                          setState(() => _primaryLiveAlgorithm = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes field
              _sectionCard(
                title: 'Observations & Signal Parameters',
                icon: Icons.notes_rounded,
                children: [
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Protocol Observations / Notes (Optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Algorithm & Sampling Parameters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      subtitle: const Text(
                        '100 Hz • 1000 ms window • 250 ms lockout • stationary gate',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                      ),
                      initiallyExpanded: _showAdvanced,
                      onExpansionChanged: (val) =>
                          setState(() => _showAdvanced = val),
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _samplingRateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Sampling Rate (Hz)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _smoothingController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Smoothing (samples)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _windowController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Window Duration (ms)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _minimumIntervalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Step Lockout (ms)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _kController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'k (Mean + k·SD)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _noiseFloorController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Stationary Gate (m/s²)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _startTrial,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Proceed to Live Trial'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE1E6EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
