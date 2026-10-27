import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../algorithms/step_detector.dart';
import '../models/experiment_models.dart';
import '../services/recording_repository.dart';
import '../services/recording_service.dart';
import 'results_screen.dart';

class LiveRecordingScreen extends StatefulWidget {
  const LiveRecordingScreen({
    super.key,
    required this.config,
    required this.recordingId,
    this.store,
    this.recordingService,
  });

  final ExperimentConfig config;
  final String recordingId;
  final RecordingStore? store;
  final RecordingService? recordingService;

  @override
  State<LiveRecordingScreen> createState() => _LiveRecordingScreenState();
}

class _LiveRecordingScreenState extends State<LiveRecordingScreen>
    with SingleTickerProviderStateMixin {
  late final RecordingStore _store;
  late final RecordingService _recordingService;
  late final StepDetector _liveDetector;

  // Countdown state: 3, 2, 1, 0 (active)
  int _countdown = 3;
  Timer? _countdownTimer;

  bool _isRecording = false;
  int _liveSteps = 0;
  final _stopwatch = Stopwatch();
  Timer? _tickerTimer;
  Timer? _fallbackTimer;

  // For live signal chart: rolling buffer of recent outputs
  static const int _maxChartPoints = 120;
  final ListQueue<DetectorOutput> _recentOutputs = ListQueue<DetectorOutput>();

  // Pulse animation for step detection
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? FileRecordingStore();
    _recordingService = widget.recordingService ?? RecordingService();
    _liveDetector = StepDetector(
      algorithm: widget.config.primaryLiveAlgorithm,
      parameters: widget.config.parameters,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickerTimer?.cancel();
    _fallbackTimer?.cancel();
    _recordingService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _startSensorRecording();
      }
    });
  }

  void _startSensorRecording() {
    setState(() {
      _isRecording = true;
    });
    _stopwatch.start();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });

    if (widget.config.fallbackTimeoutSeconds > 0) {
      _fallbackTimer = Timer(
        Duration(seconds: widget.config.fallbackTimeoutSeconds),
        _stopRecording,
      );
    }

    _recordingService.start(
      widget.recordingId,
      samplingRateHz: widget.config.requestedSamplingRateHz,
      onSample: (sample) {
        final output = _liveDetector.addSample(sample);
        if (!mounted) return;

        setState(() {
          _recentOutputs.addLast(output);
          if (_recentOutputs.length > _maxChartPoints) {
            _recentOutputs.removeFirst();
          }

          if (output.step != null) {
            _liveSteps = _liveDetector.stepCount;
            _pulseController.forward(from: 0.0).then((_) {
              if (mounted) _pulseController.reverse();
            });
          }
        });
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sensor error: $err')),
        );
      },
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _tickerTimer?.cancel();
    _fallbackTimer?.cancel();
    _stopwatch.stop();

    final samples = await _recordingService.stop();

    // Replay both algorithms on exact recorded samples
    final replayResults = StepDetector.replayBoth(
      samples,
      widget.config.parameters,
    );

    final recording = SavedRecording(
      recordingId: widget.recordingId,
      createdAt: DateTime.now(),
      config: widget.config,
      samples: samples,
      liveStepCount: _liveSteps,
      replayDetections: replayResults,
    );

    await _store.save(recording);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(recording: recording),
      ),
    );
  }

  String _formatElapsed() {
    final ms = _stopwatch.elapsedMilliseconds;
    final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.config.targetSteps;
    final progress = target > 0 ? (_liveSteps / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recordingId),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _countdown > 0
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Ready...',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$_countdown',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 96,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Activity: ${widget.config.activity.value.toUpperCase()} | '
                      'Placement: ${widget.config.phonePlacement.value.toUpperCase()}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.directions_walk, size: 18),
                          label: Text(widget.config.activity.value),
                        ),
                        Chip(
                          avatar: const Icon(Icons.phone_android, size: 18),
                          label: Text(widget.config.phonePlacement.value),
                        ),
                        Chip(
                          avatar: const Icon(Icons.speed, size: 18),
                          label: Text(
                            widget.config.primaryLiveAlgorithm.displayName,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Prominent Live Counter with Pulse
                    Center(
                      child: ScaleTransition(
                        scale: _pulseScale,
                        child: Text(
                          '$_liveSteps',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Target: $target Steps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Elapsed Timer
                    Center(
                      child: Text(
                        _formatElapsed(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Live Signal Chart
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Live Acceleration & Threshold',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  _legend(Colors.blue, 'Magnitude'),
                                  const SizedBox(width: 8),
                                  _legend(Colors.orange, 'Threshold'),
                                  const SizedBox(width: 8),
                                  _legend(Colors.green, 'Step'),
                                ],
                              ),
                            ],
                          ),
                          Expanded(
                            child: CustomPaint(
                              painter: _SignalChartPainter(
                                outputs: _recentOutputs.toList(),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stop Button
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop, size: 28),
                        label: const Text(
                          'Stop (100 Steps Completed)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _SignalChartPainter extends CustomPainter {
  _SignalChartPainter({required this.outputs});

  final List<DetectorOutput> outputs;

  @override
  void paint(Canvas canvas, Size size) {
    if (outputs.isEmpty) return;

    final magPaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final threshPaint = Paint()
      ..color = Colors.orange.shade800
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final stepDotPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;

    // Find y range
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final o in outputs) {
      if (o.smoothedMps2 < minY) minY = o.smoothedMps2;
      if (o.smoothedMps2 > maxY) maxY = o.smoothedMps2;
      if (o.thresholdMps2 < minY) minY = o.thresholdMps2;
      if (o.thresholdMps2 > maxY) maxY = o.thresholdMps2;
    }

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    // Add margins
    final range = maxY - minY;
    minY -= range * 0.1;
    maxY += range * 0.1;

    double toY(double v) {
      return size.height - ((v - minY) / (maxY - minY)) * size.height;
    }

    final dx = size.width / (_LiveRecordingScreenState._maxChartPoints - 1);
    final xOffset = (_LiveRecordingScreenState._maxChartPoints - outputs.length) * dx;

    final magPath = Path();
    final threshPath = Path();

    for (var i = 0; i < outputs.length; i++) {
      final x = xOffset + i * dx;
      final my = toY(outputs[i].smoothedMps2);
      final ty = toY(outputs[i].thresholdMps2);

      if (i == 0) {
        magPath.moveTo(x, my);
        threshPath.moveTo(x, ty);
      } else {
        magPath.lineTo(x, my);
        threshPath.lineTo(x, ty);
      }

      if (outputs[i].step != null) {
        canvas.drawCircle(Offset(x, my), 4.0, stepDotPaint);
      }
    }

    canvas.drawPath(magPath, magPaint);
    canvas.drawPath(threshPath, threshPaint);
  }

  @override
  bool shouldRepaint(covariant _SignalChartPainter oldDelegate) => true;
}
