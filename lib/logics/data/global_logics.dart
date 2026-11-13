// ignore_for_file: depend_on_referenced_packages
import 'package:arcane/arcane.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// A class that holds global data constants and logic for the application.
class DataConstants {
  /// The base URL for the API.
  static const String url = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8000/');

  /// The version of the application.
  static const String version = "0.1";

  /// The build type of the application.
  static const String build = "Self Hosted";

  /// The current theme of the application.
  static ThemeMode currentTheme = ThemeMode.dark;

  /// The width of the page.
  static const double pageWidth = 768;

  static ColorScheme Function(ThemeMode mode) colorScheme =
      ColorSchemes.defaultcolor;

  static final List<Map<String, dynamic>> availableAccents = [
    {"color": "Blue", "scheme": ColorSchemes.blue},
    {"color": "Green", "scheme": ColorSchemes.green},
    {"color": "Default", "scheme": ColorSchemes.defaultcolor},
    {"color": "Orange", "scheme": ColorSchemes.orange},
    {"color": "Red", "scheme": ColorSchemes.red},
    {"color": "Rose", "scheme": ColorSchemes.rose},
    {"color": "Violet", "scheme": ColorSchemes.violet},
    {"color": "Yellow", "scheme": ColorSchemes.yellow},
  ];

  static  Map<String, dynamic> activeAccent = {
    "color": "Default",
    "scheme": ColorSchemes.defaultcolor,
  };

  /// The Hive box used for storing data.
  static Box? box;
  static Box? settingsBox;
  /// Returns the authentication token from the Hive box.
  ///
  /// Returns `null` if the token is not found.
  static String? getToken() {
    try {
      final token = box?.get('loggedInUser');
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Sets the authentication token in the Hive box.
  static void setToken(String token) {
    if (box == null) throw Exception('Hive storage box not initialized');
    box!.put('loggedInUser', token);
  }

  /// Checks if the API URL is pointing to localhost in release mode and logs a warning.
  static void validateApiUrl() {
    if (kReleaseMode && (url.contains('127.0.0.1') || url.contains('localhost'))) {
      debugPrint('WARNING: API URL is pointing to localhost in release mode. Set API_URL environment variable.');
    }
  }

  /// Clears the authentication token from the Hive box.
  static void clearToken() {
    if (box == null) throw Exception('Hive storage box not initialized');
    box!.delete('loggedInUser');
  }
}
