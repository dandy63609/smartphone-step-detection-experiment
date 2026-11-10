import 'dart:convert';
import 'dart:io';

import '../evaluation/run_metrics_calculator.dart';
import '../evaluation/step_count_evaluation.dart';
import '../models/experiment_models.dart';

/// Signature for sending a JSON payload to a PostHog Cloud endpoint.
typedef PostHogTransport =
    Future<int> Function(Uri endpoint, Map<String, Object?> payload);

/// Single telemetry event captured by [PostHogTelemetryService].
class PostHogEventRecord {
  const PostHogEventRecord({
    required this.event,
    required this.distinctId,
    required this.timestampIso,
    required this.properties,
    required this.delivered,
  });

  final String event;
  final String distinctId;
  final String timestampIso;
  final Map<String, Object?> properties;
  final bool delivered;

  Map<String, Object?> toPostHogJson(String apiKey) => {
    'api_key': apiKey,
    'event': event,
    'distinct_id': distinctId,
    'timestamp': timestampIso,
    'properties': {
      'distinct_id': distinctId,
      '\$lib': 'stradio-flutter-telemetry',
      '\$lib_version': '1.0.0',
      ...properties,
    },
  };
}

/// Lightweight, testable PostHog Cloud Telemetry service for the STRADIO app
/// and its PostHog Admin Dashboard.
///
/// Supports `--dart-define=POSTHOG_API_KEY=phc_...` and runtime configuration
/// inside the Sensor Labs Drawer.
class PostHogTelemetryService {
  PostHogTelemetryService({
    String? apiKey,
    String? host,
    PostHogTransport? transport,
    this.enabled = true,
  }) : _apiKey =
           apiKey ??
           const String.fromEnvironment('POSTHOG_API_KEY', defaultValue: ''),
       _host =
           host ??
           const String.fromEnvironment(
             'POSTHOG_HOST',
             defaultValue: 'https://us.i.posthog.com',
           ),
       _transport = transport ?? _defaultHttpTransport;

  String _apiKey;
  String _host;
  final PostHogTransport _transport;
  bool enabled;

  final List<PostHogEventRecord> _recordedEvents = [];
  String? _lastError;

  String get apiKey => _apiKey;
  String get host => _host;
  bool get isConfigured => _apiKey.trim().isNotEmpty;
  String? get lastError => _lastError;

  /// Enables or disables network telemetry dispatch per user opt-in/opt-out preference.
  void setEnabled(bool value) {
    enabled = value;
  }

  List<PostHogEventRecord> get recordedEvents =>
      List.unmodifiable(_recordedEvents);

  int get deliveredCount => _recordedEvents.where((e) => e.delivered).length;
  int get queuedCount => _recordedEvents.where((e) => !e.delivered).length;

  /// Updates the PostHog Project API Key (`phc_...`) and/or Instance Host at
  /// runtime (e.g. from Sensor Labs Drawer) and flushes any queued events.
  Future<void> configure({required String apiKey, String? host}) async {
    _apiKey = apiKey.trim();
    if (host != null && host.trim().isNotEmpty) {
      _host = host.trim();
    }
    if (isConfigured) {
      await flushQueuedEvents();
    }
  }

  Uri get _captureUri {
    final normalized = _host.endsWith('/')
        ? _host.substring(0, _host.length - 1)
        : _host;
    return Uri.parse('$normalized/capture/');
  }

  /// Captures a generic PostHog event and dispatches it if an API key is set.
  Future<PostHogEventRecord> capture({
    required String event,
    required String distinctId,
    required Map<String, Object?> properties,
    DateTime? timestamp,
  }) async {
    final ts = (timestamp ?? DateTime.now()).toUtc().toIso8601String();
    var delivered = false;

    if (isConfigured && enabled) {
      final draft = PostHogEventRecord(
        event: event,
        distinctId: distinctId,
        timestampIso: ts,
        properties: properties,
        delivered: false,
      );
      try {
        final status = await _transport(
          _captureUri,
          draft.toPostHogJson(_apiKey),
        );
        delivered = status >= 200 && status < 300;
        if (!delivered) {
          _lastError = 'HTTP $status from PostHog Cloud';
        } else {
          _lastError = null;
        }
      } on Object catch (error) {
        _lastError = error.toString();
        delivered = false;
      }
    }

    final record = PostHogEventRecord(
      event: event,
      distinctId: distinctId,
      timestampIso: ts,
      properties: properties,
      delivered: delivered,
    );
    _recordedEvents.add(record);
    return record;
  }

  /// Re-sends any queued events that were recorded before the API key was set.
  Future<int> flushQueuedEvents() async {
    if (!isConfigured || !enabled) return 0;
    var newlyDelivered = 0;
    for (var i = 0; i < _recordedEvents.length; i++) {
      final item = _recordedEvents[i];
      if (item.delivered) continue;
      try {
        final status = await _transport(
          _captureUri,
          item.toPostHogJson(_apiKey),
        );
        if (status >= 200 && status < 300) {
          _recordedEvents[i] = PostHogEventRecord(
            event: item.event,
            distinctId: item.distinctId,
            timestampIso: item.timestampIso,
            properties: item.properties,
            delivered: true,
          );
          newlyDelivered++;
          _lastError = null;
        }
      } on Object catch (error) {
        _lastError = error.toString();
      }
    }
    return newlyDelivered;
  }

  Future<PostHogEventRecord> captureAppOpened({
    required String distinctId,
    required bool developerOverlayEnabled,
  }) => capture(
    event: 'stradio_app_opened',
    distinctId: distinctId,
    properties: {
      'app_name': 'Stradio',
      'app_version': '1.0.0+1',
      'developer_overlay_enabled': developerOverlayEnabled,
    },
  );

  Future<PostHogEventRecord> captureRunStarted({
    required String recordingId,
    required ExperimentConfig config,
    required int targetBpm,
  }) => capture(
    event: 'run_started',
    distinctId: config.participantId,
    properties: {
      'recording_id': recordingId,
      'participant_id': config.participantId,
      'activity': config.activity.value,
      'phone_placement': config.phonePlacement.value,
      'placement_detail': config.placementDetail,
      'trial_number': config.trialNumber,
      'target_steps': config.targetSteps,
      'target_bpm': targetBpm,
      'primary_algorithm': config.primaryLiveAlgorithm.value,
    },
  );

  Future<PostHogEventRecord> captureRunPaused({
    required String recordingId,
    required String participantId,
    required double elapsedSeconds,
    required int currentSteps,
  }) => capture(
    event: 'run_paused',
    distinctId: participantId,
    properties: {
      'recording_id': recordingId,
      'elapsed_seconds': double.parse(elapsedSeconds.toStringAsFixed(2)),
      'current_steps': currentSteps,
    },
  );

  Future<PostHogEventRecord> captureRunResumed({
    required String recordingId,
    required String participantId,
    required double elapsedSeconds,
    required int currentSteps,
  }) => capture(
    event: 'run_resumed',
    distinctId: participantId,
    properties: {
      'recording_id': recordingId,
      'elapsed_seconds': double.parse(elapsedSeconds.toStringAsFixed(2)),
      'current_steps': currentSteps,
    },
  );

  /// Sends the consumer workout summary (`run_completed`) AND all 4 algorithm
  /// benchmark evaluations (`algorithm_benchmark_evaluated` for A1, A2, B1, B2)
  /// to power the PostHog Admin Dashboard.
  Future<List<PostHogEventRecord>> captureWorkoutAndBenchmarks({
    required SavedRecording recording,
    required RunSummaryMetrics metrics,
    required SensorHealthReport health,
  }) async {
    final sent = <PostHogEventRecord>[];
    final config = recording.config;

    final completedEvent = await capture(
      event: 'run_completed',
      distinctId: config.participantId,
      properties: {
        'recording_id': recording.recordingId,
        'participant_id': config.participantId,
        'trial_number': config.trialNumber,
        'activity': config.activity.value,
        'phone_placement': config.phonePlacement.value,
        'placement_detail': config.placementDetail,
        'duration_seconds': double.parse(
          metrics.activeDurationSeconds.toStringAsFixed(2),
        ),
        'total_steps': metrics.totalSteps,
        'ground_truth_steps': config.targetSteps,
        'avg_cadence_spm': double.parse(
          metrics.averageCadenceSpm.toStringAsFixed(2),
        ),
        'estimated_distance_km': double.parse(
          metrics.distanceKm.toStringAsFixed(3),
        ),
        'estimated_speed_kmh': double.parse(
          metrics.speedKmh.toStringAsFixed(2),
        ),
        'target_bpm': metrics.targetBpm,
        'rhythm_score_percent': double.parse(
          metrics.rhythmScorePercent.toStringAsFixed(1),
        ),
        'sample_count': health.sampleCount,
        'effective_sampling_hz': double.parse(
          health.effectiveRateHz.toStringAsFixed(1),
        ),
        'sample_drops': health.sampleDrops,
        'live_matches_replay': recording.liveMatchesReplay,
      },
    );
    sent.add(completedEvent);

    final evaluations = evaluateRecordingAllFour(recording);
    for (final eval in evaluations) {
      final variant = eval.variant;
      final benchmarkEvent = await capture(
        event: 'algorithm_benchmark_evaluated',
        distinctId: config.participantId,
        properties: {
          'recording_id': recording.recordingId,
          'participant_id': config.participantId,
          'condition_id': eval.condition,
          'trial_number': eval.trialNumber,
          'activity': eval.activity.value,
          'phone_placement': eval.phonePlacement.value,
          'variant_code': eval.variantCode,
          'algorithm': eval.algorithmValue,
          'algorithm_display_name': eval.variantDisplayName,
          'sensor_stream': (variant?.usesLinearAcceleration ?? false)
              ? 'linear_no_gravity'
              : 'raw_with_gravity',
          'ground_truth_steps': eval.groundTruthSteps,
          'predicted_steps': eval.predictedSteps,
          'absolute_error_steps': eval.absoluteErrorSteps,
          'signed_error_steps': eval.signedErrorSteps,
          'margin_of_error_percent': double.parse(
            eval.marginOfErrorPercent.toStringAsFixed(2),
          ),
          'accuracy_percent': double.parse(
            eval.accuracyPercent.toStringAsFixed(2),
          ),
          'status': eval.status.label,
        },
      );
      sent.add(benchmarkEvent);
    }

    return sent;
  }

  Future<PostHogEventRecord> captureCsvExported({
    required String distinctId,
    required int totalRecordingsExported,
    required int totalSamplesExported,
  }) => capture(
    event: 'csv_dataset_exported',
    distinctId: distinctId,
    properties: {
      'total_recordings_exported': totalRecordingsExported,
      'total_samples_exported': totalSamplesExported,
    },
  );

  static Future<int> _defaultHttpTransport(
    Uri endpoint,
    Map<String, Object?> payload,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      final encoded = utf8.encode(jsonEncode(payload));
      request.contentLength = encoded.length;
      request.add(encoded);
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      await response.drain<void>();
      return response.statusCode;
    } finally {
      client.close(force: true);
    }
  }
}

