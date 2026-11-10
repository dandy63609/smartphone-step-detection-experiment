import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Top-level callback for flutter_foreground_task execution in background isolate.
@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(StradioWorkoutTaskHandler());
}

/// Background isolate TaskHandler for lockscreen notification interactions.
class StradioWorkoutTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    // Deliver action back to the Flutter main UI isolate
    FlutterForegroundTask.sendDataToMain({'action': id});
    if (id == 'finish') {
      FlutterForegroundTask.launchApp();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}

  @override
  void onReceiveData(Object data) {}
}

/// Abstract contract for workout foreground service and lockscreen notification.
abstract class ForegroundNotificationService {
  Future<void> init();

  Future<bool> requestNotificationPermission();

  Future<void> startWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  });

  Future<void> updateWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  });

  Future<void> stopWorkoutService();

  void addActionListener(void Function(String actionId) listener);

  void removeActionListener(void Function(String actionId) listener);

  bool get isServiceActive;
}

/// Android production implementation of [ForegroundNotificationService]
/// using `flutter_foreground_task`.
class FlutterForegroundNotificationService
    implements ForegroundNotificationService {
  FlutterForegroundNotificationService();

  final List<void Function(String actionId)> _listeners = [];
  bool _initialized = false;
  bool _active = false;
  int _lastUpdateTimestampMs = 0;
  bool? _lastIsRunning;

  @visibleForTesting
  bool shouldDispatchUpdate(bool isRunning, int nowMs) {
    final stateChanged = _lastIsRunning != isRunning;
    if (!stateChanged && nowMs - _lastUpdateTimestampMs < 800) {
      return false;
    }
    _lastUpdateTimestampMs = nowMs;
    _lastIsRunning = isRunning;
    return true;
  }

  @override
  bool get isServiceActive => _active;

  @override
  void addActionListener(void Function(String actionId) listener) {
    _listeners.add(listener);
  }

  @override
  void removeActionListener(void Function(String actionId) listener) {
    _listeners.remove(listener);
  }

  void _dispatchAction(String actionId) {
    for (final listener in List.of(_listeners)) {
      listener(actionId);
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> init() async {
    if (_initialized || !_isAndroid) return;

    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'stradio_workout_channel',
          channelName: 'Stradio Active Workout',
          channelDescription:
              'Real-time step detection and playback controls on lockscreen',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );

      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback((dynamic data) {
        if (data is Map && data['action'] is String) {
          _dispatchAction(data['action'] as String);
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('ForegroundNotificationService init error: $e');
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return true;
    try {
      final status =
          await FlutterForegroundTask.checkNotificationPermission();
      if (status == NotificationPermission.granted) return true;
      final requested =
          await FlutterForegroundTask.requestNotificationPermission();
      return requested == NotificationPermission.granted;
    } catch (_) {
      return false;
    }
  }

  String _formatDuration(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  List<NotificationButton> _buildButtons(bool isRunning) {
    return [
      NotificationButton(
        id: 'pause_resume',
        text: isRunning ? 'Pause' : 'Resume',
      ),
      const NotificationButton(
        id: 'finish',
        text: 'Finish',
      ),
    ];
  }

  @override
  Future<void> startWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  }) async {
    if (!_isAndroid) {
      _active = true;
      return;
    }

    await init();

    final title = 'Stradio · ${isRunning ? "Running" : "Paused"} ($targetBpm BPM)';
    final text =
        'Steps: $steps / $targetSteps ($algorithmName) · ${_formatDuration(activeDurationSeconds)}';

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
          notificationButtons: _buildButtons(isRunning),
        );
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 501,
          serviceTypes: [ForegroundServiceTypes.health],
          notificationTitle: title,
          notificationText: text,
          notificationButtons: _buildButtons(isRunning),
          callback: startForegroundTaskCallback,
        );
      }
      _active = true;
      _lastIsRunning = isRunning;
      _lastUpdateTimestampMs = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('Error starting foreground task: $e');
    }
  }

  @override
  Future<void> updateWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  }) async {
    if (!_active || !_isAndroid) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!shouldDispatchUpdate(isRunning, now)) return;

    final title = 'Stradio · ${isRunning ? "Running" : "Paused"} ($targetBpm BPM)';
    final text =
        'Steps: $steps / $targetSteps ($algorithmName) · ${_formatDuration(activeDurationSeconds)}';

    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationButtons: _buildButtons(isRunning),
      );
    } catch (e) {
      debugPrint('Error updating foreground task: $e');
    }
  }

  @override
  Future<void> stopWorkoutService() async {
    _active = false;
    _lastIsRunning = null;
    if (!_isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('Error stopping foreground task: $e');
    }
  }
}

/// Safe in-memory mock implementation for Widget and Unit tests.
class NoopForegroundNotificationService
    implements ForegroundNotificationService {
  final List<void Function(String actionId)> _listeners = [];
  bool _active = false;
  int lastSteps = 0;
  bool lastIsRunning = false;

  @override
  bool get isServiceActive => _active;

  @override
  void addActionListener(void Function(String actionId) listener) {
    _listeners.add(listener);
  }

  @override
  void removeActionListener(void Function(String actionId) listener) {
    _listeners.remove(listener);
  }

  /// Helper to trigger notification action clicks in tests
  void simulateNotificationAction(String actionId) {
    for (final listener in List.of(_listeners)) {
      listener(actionId);
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<void> startWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  }) async {
    _active = true;
    lastSteps = steps;
    lastIsRunning = isRunning;
  }

  @override
  Future<void> updateWorkoutService({
    required int steps,
    required int targetSteps,
    required double activeDurationSeconds,
    required int targetBpm,
    required String algorithmName,
    required bool isRunning,
  }) async {
    lastSteps = steps;
    lastIsRunning = isRunning;
  }

  @override
  Future<void> stopWorkoutService() async {
    _active = false;
  }
}
