import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

import 'achievement_system.dart';

/// App-wide settings shared by every screen.
///
/// Screens should read this through [SettingsScope.of] so they rebuild
/// automatically when the language or a volume changes.
class AppSettings extends ChangeNotifier {
  static const String english = 'English';
  static const String filipino = 'Filipino';

  static const double defaultMusicVolume = 0.7;
  static const double defaultSfxVolume = 0.8;

  String _language = english;

  double _musicVolume = defaultMusicVolume;
  double _sfxVolume = defaultSfxVolume;

  double _previousMusicVolume = defaultMusicVolume;
  double _previousSfxVolume = defaultSfxVolume;

  final AchievementManager achievements = AchievementManager();

  AppSettings() {
    _startVolumeListener();
  }

  String get language => _language;

  bool get isFilipino => _language == filipino;

  /// Language code used by the situation JSON files (`en` / `fil`).
  String get languageCode => isFilipino ? 'fil' : 'en';

  double get musicVolume => _musicVolume;

  double get sfxVolume => _sfxVolume;

  set language(String value) {
    if (value == _language) return;

    _language = value;
    notifyListeners();
  }

  set musicVolume(double value) {
    final next = value.clamp(0.0, 1.0);

    if (next == _musicVolume) return;

    _musicVolume = next;

    if (next > 0) {
      _previousMusicVolume = next;
    }

    notifyListeners();
  }

  set sfxVolume(double value) {
    final next = value.clamp(0.0, 1.0);

    if (next == _sfxVolume) return;

    _sfxVolume = next;

    if (next > 0) {
      _previousSfxVolume = next;
    }

    notifyListeners();
  }

  void toggleMusic() {
    musicVolume = _musicVolume > 0
        ? 0
        : (_previousMusicVolume > 0
        ? _previousMusicVolume
        : defaultMusicVolume);
  }

  void toggleSfx() {
    sfxVolume = _sfxVolume > 0
        ? 0
        : (_previousSfxVolume > 0
        ? _previousSfxVolume
        : defaultSfxVolume);
  }

  // ============================================================
  // HARDWARE VOLUME BUTTON SUPPORT
  // ============================================================

  void _startVolumeListener() {
    VolumeController.instance.addListener((volume) {
      final next = volume.clamp(0.0, 1.0);

      if (next == _musicVolume) {
        return;
      }

      _musicVolume = next;

      if (next > 0) {
        _previousMusicVolume = next;
      }

      notifyListeners();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    VolumeController.instance.removeListener();
    super.dispose();
  }
}

/// Makes a single [AppSettings] instance available to the whole widget tree.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  /// Returns the shared settings and rebuilds [context] when they change.
  static AppSettings of(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<SettingsScope>();

    assert(
    scope != null,
    'No SettingsScope found in context. '
        'Wrap your app in a SettingsScope.',
    );

    return scope!.notifier!;
  }

  /// Returns the shared settings without subscribing to changes.
  ///
  /// Useful inside callbacks where a rebuild is not needed.
  static AppSettings read(BuildContext context) {
    final scope =
    context.getInheritedWidgetOfExactType<SettingsScope>();

    assert(
    scope != null,
    'No SettingsScope found in context. '
        'Wrap your app in a SettingsScope.',
    );

    return scope!.notifier!;
  }
}