import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  // persisted keys
  static const _kSavedCities = 'saved_cities';
  static const _kWeatherNotificationsEnabled = 'weather_notifications';
  static const _kHighTempThreshold = 'high_temp_threshold';
  static const _kFcmToken = 'fcm_token';
  static const _kTheme = 'theme';
  static const _kUnits = 'units';
  static const _kUseLocation = 'use_location';
  static const _kLocation = 'manual_location';

  // state (private)
  List<String> _savedCities = [];
  bool _weatherNotificationsEnabled = true;
  double _highTempThreshold = 95.0; // Fahrenheit default
  String? _fcmToken;
  String _theme = 'system';
  String _units = 'fahrenheit';
  bool _useLocation = true;
  String _location = '';

  // Public getters
  List<String> get savedCities => List.unmodifiable(_savedCities);
  bool get weatherNotificationsEnabled => _weatherNotificationsEnabled;
  double get highTempThreshold => _highTempThreshold;
  String? get fcmToken => _fcmToken;
  String get theme => _theme;
  String get units => _units;
  bool get useLocation => _useLocation;
  String get location => _location;

  // Load persisted values
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedCities = prefs.getStringList(_kSavedCities) ?? [];
    _weatherNotificationsEnabled =
        prefs.getBool(_kWeatherNotificationsEnabled) ?? true;
    _highTempThreshold = prefs.getDouble(_kHighTempThreshold) ?? 95.0;
    _fcmToken = prefs.getString(_kFcmToken);
    _theme = prefs.getString(_kTheme) ?? 'system';
    _units = prefs.getString(_kUnits) ?? 'fahrenheit';
    _useLocation = prefs.getBool(_kUseLocation) ?? true;
    _location = prefs.getString(_kLocation) ?? '';
    notifyListeners();
  }

  // Setters with persistence
  Future<void> setWeatherNotificationsEnabled(bool v) async {
    _weatherNotificationsEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWeatherNotificationsEnabled, v);
  }

  Future<void> setHighTempThreshold(double v) async {
    _highTempThreshold = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kHighTempThreshold, v);
  }

  Future<void> setFcmToken(String? token) async {
    _fcmToken = token;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_kFcmToken);
    } else {
      await prefs.setString(_kFcmToken, token);
    }
  }

  Future<void> setTheme(String t) async {
    _theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, t);
  }

  Future<void> setUnits(String u) async {
    _units = u;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnits, u);
  }

  Future<void> setUseLocation(bool v) async {
    _useLocation = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseLocation, v);
  }

  Future<void> setLocation(String v) async {
    _location = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocation, v);
  }

  // Saved cities
  Future<void> addSavedCity(String city) async {
    if (!_savedCities.contains(city)) {
      _savedCities.add(city);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSavedCities, _savedCities);
    }
  }

  Future<void> removeSavedCity(String city) async {
    _savedCities.remove(city);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSavedCities, _savedCities);
  }

  Future<void> clearSavedCities() async {
    _savedCities.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedCities);
  }

  // Convenience: clear all persisted settings (used by some UIs)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedCities);
    await prefs.remove(_kWeatherNotificationsEnabled);
    await prefs.remove(_kHighTempThreshold);
    await prefs.remove(_kFcmToken);
    await prefs.remove(_kTheme);
    await prefs.remove(_kUnits);
    await prefs.remove(_kUseLocation);
    await prefs.remove(_kLocation);
    // reset in-memory
    _savedCities = [];
    _weatherNotificationsEnabled = true;
    _highTempThreshold = 95.0;
    _fcmToken = null;
    _theme = 'system';
    _units = 'fahrenheit';
    _useLocation = true;
    _location = '';
    notifyListeners();
  }
}
