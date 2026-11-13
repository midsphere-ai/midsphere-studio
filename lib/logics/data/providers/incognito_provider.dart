import 'package:flutter/foundation.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';

/// Global singleton for incognito mode state.
/// Usage: IncognitoModeProvider().value to check, .toggle() to switch
class IncognitoModeProvider extends ValueNotifier<bool> {
  static final IncognitoModeProvider _instance =
      IncognitoModeProvider._internal(false);

  IncognitoModeProvider._internal(super.initialValue);

  factory IncognitoModeProvider() => _instance;

  /// Toggle incognito mode on/off
  void toggle() {
    value = !value;
    _persist();
  }

  void _persist() {
    final email = AuthenticationProvider().loggedInUser?.email;
    if (email == null) return;

    final key = 'settings_$email';
    final settings = Map<String, dynamic>.from(
      DataConstants.settingsBox?.get(key) ?? {},
    );
    settings['incognito_mode'] = value;
    DataConstants.settingsBox?.put(key, settings);
  }

  /// Load saved state (call after login)
  static void initialize() {
    final email = AuthenticationProvider().loggedInUser?.email;
    if (email == null) return;

    final key = 'settings_$email';
    final settings = DataConstants.settingsBox?.get(key);
    if (settings is Map && settings['incognito_mode'] == true) {
      _instance.value = true;
    } else {
      _instance.value = false;
    }
  }
}
