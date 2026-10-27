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
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.all(20),
            children: [
              // Header condition card
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentCondition,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target ID: ${_recordingId ?? "Generating..."}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sensor Status: ${_checkingSensor ? "Checking..." : _sensorAvailable ? "Accelerometer Ready" : "Sensor Unavailable (Mock/Simulator)"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _sensorAvailable
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Participant & Trial Number
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _participantController,
                      decoration: const InputDecoration(
                        labelText: 'Participant ID',
                        hintText: 'e.g. P01',
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          int.tryParse(val ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Activity selector
              DropdownButtonFormField<Activity>(
                initialValue: _activity,
                decoration: const InputDecoration(
                  labelText: 'Factor C: Activity',
                  border: OutlineInputBorder(),
                ),
                items: Activity.values
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.value.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _activity = val!),
              ),
              const SizedBox(height: 16),

              // Phone Placement selector
              DropdownButtonFormField<PhonePlacement>(
                initialValue: _phonePlacement,
                decoration: const InputDecoration(
                  labelText: 'Factor B: Phone Placement',
                  border: OutlineInputBorder(),
                ),
                items: PhonePlacement.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.value.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _phonePlacement = val!;
                    if (val == PhonePlacement.hand) {
                      _placementDetailController.text = 'right hand';
                    } else {
                      _placementDetailController.text = 'front-right pocket';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _placementDetailController,
                decoration: const InputDecoration(
                  labelText: 'Placement Detail',
                  hintText: 'e.g. right hand, front-right pocket',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Primary live algorithm
              DropdownButtonFormField<ThresholdAlgorithm>(
                initialValue: _primaryLiveAlgorithm,
                decoration: const InputDecoration(
                  labelText: 'Primary Live Algorithm (Factor A)',
                  border: OutlineInputBorder(),
                ),
                items: ThresholdAlgorithm.values
                    .map(
                      (alg) => DropdownMenuItem(
                        value: alg,
                        child: Text(alg.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _primaryLiveAlgorithm = val!),
              ),
              const SizedBox(height: 16),

              // Target Steps & Timeout
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetStepsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ground Truth Steps',
                        hintText: '100',
                        border: OutlineInputBorder(),
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
                        hintText: '0 = disabled',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Protocol Observations / Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Advanced Parameters Expansion
              ExpansionTile(
                title: const Text('Algorithm & Sampling Parameters'),
                subtitle: const Text('Window, smoothing, refractory lockout, k'),
                initiallyExpanded: _showAdvanced,
                onExpansionChanged: (val) => setState(() => _showAdvanced = val),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _samplingRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Requested Sampling Rate (Hz)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _smoothingController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Smoothing Window (samples)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _windowController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Adaptive Window Duration (ms)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _minimumIntervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Step Interval / Lockout (ms)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _kController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'k (Mean + k·SD algorithm)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _startTrial,
                  icon: const Icon(Icons.timer),
                  label: const Text(
                    'Proceed to Live Trial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
