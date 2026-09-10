import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VideoQuality { auto, high, medium, low }

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = ThemeMode.values.byName(
      _prefs.getString(_kTheme) ?? ThemeMode.dark.name,
    );
    _notifications = _prefs.getBool(_kNotifications) ?? true;
    _autoplay = _prefs.getBool(_kAutoplay) ?? true;
    _quality = VideoQuality.values.byName(
      _prefs.getString(_kQuality) ?? VideoQuality.auto.name,
    );
  }

  final SharedPreferences _prefs;

  static const String _kTheme = 'pref_theme_mode';
  static const String _kNotifications = 'pref_notifications';
  static const String _kAutoplay = 'pref_autoplay';
  static const String _kQuality = 'pref_quality';

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  late bool _notifications;
  bool get notifications => _notifications;

  late bool _autoplay;
  bool get autoplay => _autoplay;

  late VideoQuality _quality;
  VideoQuality get quality => _quality;

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }

  Future<void> toggleDark(bool value) =>
      setThemeMode(value ? ThemeMode.dark : ThemeMode.light);

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    await _prefs.setBool(_kNotifications, value);
    notifyListeners();
  }

  Future<void> setAutoplay(bool value) async {
    _autoplay = value;
    await _prefs.setBool(_kAutoplay, value);
    notifyListeners();
  }

  Future<void> setQuality(VideoQuality quality) async {
    _quality = quality;
    await _prefs.setString(_kQuality, quality.name);
    notifyListeners();
  }
}
