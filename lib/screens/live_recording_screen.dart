import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

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
  int _sampleCount = 0;
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
      duration: const Duration(milliseconds: 180),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
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
          _sampleCount = sample.sampleIndex + 1;
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

    // Replay both primary algorithms and all 4 variants (A1, A2, B1, B2)
    final replayResults = StepDetector.replayBoth(
      samples,
      widget.config.parameters,
    );
    final replayVariantResults = StepDetector.replayAllFour(
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
      replayVariantDetections: replayVariantResults,
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
    final target = widget.config.targetSteps;
    final progress = target > 0 ? (_liveSteps / target).clamp(0.0, 1.0) : 0.0;
    final latestOutput = _recentOutputs.isEmpty ? null : _recentOutputs.last;
    final isStationary = latestOutput?.isStationary ?? true;
    final currentCond = conditionId(
      widget.config.activity,
      widget.config.phonePlacement,
      widget.config.primaryLiveAlgorithm,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recordingId),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentCond,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _countdown > 0
            ? _buildCountdownView()
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata Pill Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _infoPill(
                            icon: widget.config.activity == Activity.walking
                                ? Icons.directions_walk_rounded
                                : Icons.directions_run_rounded,
                            label: widget.config.activity.value.toUpperCase(),
                          ),
                          const SizedBox(width: 8),
                          _infoPill(
                            icon:
                                widget.config.phonePlacement ==
                                    PhonePlacement.hand
                                ? Icons.back_hand_outlined
                                : Icons.checkroom_rounded,
                            label:
                                widget.config.phonePlacement.value.toUpperCase(),
                          ),
                          const SizedBox(width: 8),
                          _infoPill(
                            icon: Icons.auto_graph_rounded,
                            label:
                                widget.config.primaryLiveAlgorithm.displayName,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Google Fit Circular Gauge with Step Counter
                    Center(
                      child: ScaleTransition(
                        scale: _pulseScale,
                        child: SizedBox(
                          width: 210,
                          height: 210,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 210,
                                height: 210,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 12,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: const Color(0xFFE8F0FE),
                                  color: _liveSteps >= target
                                      ? const Color(0xFF1E8E3E)
                                      : const Color(0xFF1A73E8),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_liveSteps',
                                    style: TextStyle(
                                      fontSize: 68,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                      color: _liveSteps >= target
                                          ? const Color(0xFF137333)
                                          : const Color(0xFF1A73E8),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Target: $target Steps',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5F6368),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F6FC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatElapsed(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F1F1F),
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
                    const Spacer(),

                    // Live Signal Waveform Card (Locked Minimum Scale when Stationary)
                    Container(
                      height: 165,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE1E6EF)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Live Acceleration',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isStationary
                                          ? const Color(0xFFF1F3F4)
                                          : const Color(0xFFE6F4EA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isStationary
                                                ? const Color(0xFF80868B)
                                                : const Color(0xFF1E8E3E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isStationary
                                              ? 'Stationary (Idle)'
                                              : 'Motion Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isStationary
                                                ? const Color(0xFF5F6368)
                                                : const Color(0xFF137333),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _legend(
                                    const Color(0xFF1A73E8),
                                    'Mag',
                                  ),
                                  const SizedBox(width: 8),
                                  _legend(
                                    const Color(0xFFF29900),
                                    'Thresh',
                                  ),
                                  const SizedBox(width: 8),
                                  _legend(
                                    const Color(0xFF1E8E3E),
                                    'Step',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Live telemetry numerical readout
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                latestOutput != null
                                    ? 'm(t): ${latestOutput.smoothedMps2.toStringAsFixed(2)} m/s²  •  T(t): ${latestOutput.thresholdMps2.toStringAsFixed(2)} m/s²'
                                    : 'Waiting for sensor stream...',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5F6368),
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                '$_sampleCount smp',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF80868B),
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CustomPaint(
                                painter: _SignalChartPainter(
                                  outputs: _recentOutputs.toList(),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stop Button (Google M3 Pill Button)
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD93025),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop_circle_outlined, size: 22),
                        label: const Text(
                          'Stop (100 Steps Completed)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

  Widget _buildCountdownView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
                  width: 6,
                ),
              ),
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Get Ready...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assume starting posture (${widget.config.activity.value.toUpperCase()} • ${widget.config.phonePlacement.value.toUpperCase()})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E6EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F6368),
          ),
        ),
      ],
    );
  }
}

class _SignalChartPainter extends CustomPainter {
  _SignalChartPainter({required this.outputs});

  final List<DetectorOutput> outputs;

  /// Minimum vertical range (m/s²) so stationary MEMS micro-noise (~0.02 m/s²)
  /// renders as a steady flat line instead of auto-zooming to fill the chart.
  static const double _minVerticalSpanMps2 = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF8FAFD);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle horizontal reference grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EEF7)
      ..strokeWidth = 1.0;
    for (final frac in [0.2, 0.5, 0.8]) {
      final y = size.height * frac;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (outputs.isEmpty) return;

    final magPaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final threshPaint = Paint()
      ..color = const Color(0xFFF29900)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final stepHaloPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final stepDotPaint = Paint()
      ..color = const Color(0xFF1E8E3E)
      ..style = PaintingStyle.fill;

    // Compute raw min/max
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    var sumMag = 0.0;
    for (final o in outputs) {
      sumMag += o.smoothedMps2;
      if (o.smoothedMps2 < minY) minY = o.smoothedMps2;
      if (o.smoothedMps2 > maxY) maxY = o.smoothedMps2;
      if (o.thresholdMps2 < minY) minY = o.thresholdMps2;
      if (o.thresholdMps2 > maxY) maxY = o.thresholdMps2;
    }
    final meanMag = sumMag / outputs.length;

    // Enforce minimum vertical span so stationary table noise stays flat
    final rawSpan = maxY - minY;
    if (rawSpan < _minVerticalSpanMps2) {
      final center = (maxY + minY) / 2.0;
      minY = center - _minVerticalSpanMps2 / 2.0;
      maxY = center + _minVerticalSpanMps2 / 2.0;
    } else {
      final pad = rawSpan * 0.12;
      minY -= pad;
      maxY += pad;
    }

    double toY(double v) {
      return size.height - ((v - minY) / (maxY - minY)) * size.height;
    }

    final dx = size.width / (_LiveRecordingScreenState._maxChartPoints - 1);
    final xOffset =
        (_LiveRecordingScreenState._maxChartPoints - outputs.length) * dx;

    final magPath = Path();
    final fillPath = Path();
    final threshPath = Path();

    for (var i = 0; i < outputs.length; i++) {
      final out = outputs[i];
      final x = xOffset + i * dx;
      // When stationary, suppress sub-0.08 m/s² MEMS jitter around meanMag for visual stillness
      final displayMag =
          (out.isStationary && (out.smoothedMps2 - meanMag).abs() < 0.08)
          ? meanMag
          : out.smoothedMps2;
      final my = toY(displayMag);
      final ty = toY(out.thresholdMps2);

      if (i == 0) {
        magPath.moveTo(x, my);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, my);
        threshPath.moveTo(x, ty);
      } else {
        magPath.lineTo(x, my);
        fillPath.lineTo(x, my);
        threshPath.lineTo(x, ty);
      }

      if (i == outputs.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // Soft gradient fill under magnitude curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A73E8).withValues(alpha: 0.18),
          const Color(0xFF1A73E8).withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    _drawDashedPath(canvas, threshPath, threshPaint);
    canvas.drawPath(magPath, magPaint);

    // Draw step confirmation markers on top
    for (var i = 0; i < outputs.length; i++) {
      if (outputs[i].step != null) {
        final x = xOffset + i * dx;
        final my = toY(outputs[i].smoothedMps2);
        canvas.drawCircle(Offset(x, my), 5.5, stepHaloPaint);
        canvas.drawCircle(Offset(x, my), 4.0, stepDotPaint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 5.0;
      const gapLength = 3.5;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignalChartPainter oldDelegate) => true;
}
