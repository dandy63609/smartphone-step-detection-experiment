import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/experiment_models.dart';
import '../screens/stradio/sensor_labs_sheet.dart';

/// Centralized local persistence service using [SharedPreferences] for user preferences,
/// telemetry credentials, target steps, and activity configs.
class StradioPreferencesService {
  StradioPreferencesService._();

  static const _keyPostHogApiKey = 'stradio_posthog_api_key';
  static const _keyTargetBpm = 'stradio_target_bpm';
  static const _keyTargetSteps = 'stradio_target_steps';
  static const _keyDeveloperOverlay = 'stradio_developer_overlay';
  static const _keyParticipantId = 'stradio_participant_id';
  static const _keyActivity = 'stradio_activity';
  static const _keyPhonePlacement = 'stradio_phone_placement';
  static const _keyPrimaryAlgorithm = 'stradio_primary_algorithm';
  static const _keyDarkMode = 'stradio_dark_mode';
  static const _keyUserProfileJson = 'stradio_user_profile_v1';

  static SharedPreferences? _prefs;

  /// Initializes the underlying shared preferences instance.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads saved settings into a [StradioLabSettings] instance.
  static StradioLabSettings loadLabSettings() {
    final p = _prefs;
    if (p == null) return const StradioLabSettings();

    final activityStr = p.getString(_keyActivity);
    final placementStr = p.getString(_keyPhonePlacement);
    final algorithmStr = p.getString(_keyPrimaryAlgorithm);

    final activity = Activity.values.firstWhere(
      (a) => a.value == activityStr,
      orElse: () => Activity.walking,
    );

    final phonePlacement = PhonePlacement.values.firstWhere(
      (pos) => pos.value == placementStr,
      orElse: () => PhonePlacement.hand,
    );

    final primaryAlgorithm = ThresholdAlgorithm.values.firstWhere(
      (algo) => algo.name == algorithmStr,
      orElse: () => ThresholdAlgorithm.adaptiveMidpoint,
    );

    return StradioLabSettings(
      developerOverlayEnabled: p.getBool(_keyDeveloperOverlay) ?? false,
      participantId: p.getString(_keyParticipantId) ?? 'P01',
      activity: activity,
      phonePlacement: phonePlacement,
      placementDetail: phonePlacement == PhonePlacement.hand ? 'Right hand' : 'Front right pocket',
      primaryAlgorithm: primaryAlgorithm,
      targetSteps: p.getInt(_keyTargetSteps) ?? ExperimentConfig.defaultTargetSteps,
      targetBpm: p.getInt(_keyTargetBpm) ?? 165,
    );
  }

  /// Saves updated [StradioLabSettings] to local storage.
  static Future<void> saveLabSettings(StradioLabSettings settings) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;

    await Future.wait([
      p.setBool(_keyDeveloperOverlay, settings.developerOverlayEnabled),
      p.setString(_keyParticipantId, settings.participantId),
      p.setString(_keyActivity, settings.activity.value),
      p.setString(_keyPhonePlacement, settings.phonePlacement.value),
      p.setString(_keyPrimaryAlgorithm, settings.primaryAlgorithm.name),
      p.setInt(_keyTargetSteps, settings.targetSteps),
      p.setInt(_keyTargetBpm, settings.targetBpm),
    ]);
  }

  /// Retrieves the cached PostHog API Key if present.
  static String? getPostHogApiKey() {
    return _prefs?.getString(_keyPostHogApiKey);
  }

  /// Stores the PostHog API Key locally.
  static Future<void> setPostHogApiKey(String apiKey) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setString(_keyPostHogApiKey, apiKey);
  }

  /// Returns true if Dark Mode (Deep Obsidian) is enabled.
  static bool isDarkMode() {
    return _prefs?.getBool(_keyDarkMode) ?? false;
  }

  /// Persists the selected theme mode preference.
  static Future<void> setDarkMode(bool isDark) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setBool(_keyDarkMode, isDark);
  }

  /// Loads the saved [StradioUserProfile] or returns the default profile.
  static StradioUserProfile loadUserProfile() {
    final raw = _prefs?.getString(_keyUserProfileJson);
    if (raw == null || raw.trim().isEmpty) {
      return const StradioUserProfile();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return StradioUserProfile.fromMap(decoded);
      }
    } on Object {
      // Fallback to clean default if stored JSON is malformed.
    }
    return const StradioUserProfile();
  }

  /// Saves the [StradioUserProfile] to local storage.
  static Future<void> saveUserProfile(StradioUserProfile profile) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setString(_keyUserProfileJson, jsonEncode(profile.toMap()));
  }
}

