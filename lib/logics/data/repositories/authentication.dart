import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_client/logics/domain/entities/billing/all.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';
import 'package:hive_ce/hive.dart';

import '../../../main.dart';
import '../../domain/entities/workspace/users/user.dart';
import '../global_logics.dart';

class AuthenticationProvider extends ChangeNotifier {
  static final AuthenticationProvider _instance =
      AuthenticationProvider._internal();
  static const _userKey = 'loggedInUser';

  late Box box;
  AuthenticationProvider._internal();

  factory AuthenticationProvider() {
    return _instance;
  }

  User? _loggedInUser;
  Subscription? _activeSubscription;

  User? get loggedInUser => _loggedInUser;

  Subscription? get activeSubscription => _activeSubscription;

  Future<void> initialize() async {
    box = Hive.box('authentication');
    String? userData = box.get(_userKey);
    if (userData != null) {
      final userJson = jsonDecode(userData);
      _loggedInUser = User.fromJson(userJson);
      await _ensureSettings(_loggedInUser!);
      await _fetchSubscription();
      notifyListeners();
      await notifyPostHog(_loggedInUser!);
    }
  }

  Future<void> login(User user) async {
    _loggedInUser = user;
    box.put(_userKey, jsonEncode(user.toJson()));
    await _ensureSettings(user);
    await _fetchSubscription();
    await notifyPostHog(user);
    notifyListeners();
  }

  Future<void> notifyPostHog(User user) async {
    await postHogInstance.identify(
        userId: user.id.toString(),
        userProperties: {"name": user.name ?? "Unknown", "email": user.email ?? ""},
        userPropertiesSetOnce: {"date_of_last_login": user.lastLogin ?? DateTime.now().toIso8601String()}
    );
  }

  Future<void> refreshSubscription() async {
    await _fetchSubscription();
    notifyListeners();
  }

  Future<void> _fetchSubscription() async {
    try {
      final response = await Billing.getCurrentSubscription();
      if (response != null && response is Map<String, dynamic>) {
        _activeSubscription = Subscription.fromJson(response);
      } else {
        _activeSubscription = null;
      }
    } catch (e) {
      _activeSubscription = null;
    }
  }

  Future<void> _ensureSettings(User user) async {
    if (user.email != null) {
      final key = 'settings_${user.email}';
      if (DataConstants.settingsBox?.containsKey(key) == false) {
        final defaultSettings = {
          'general': {
            'theme': 'Dark',
            'accent': 'Default',
          },
          'customise': {
            'custom_instructions': '',
            'nickname': user.name ?? '',
            'occupation': '',
            'more_about_you': '',
            'web_search': true,
            'browser': true,
            'shell_commands': true,
            'complex_reasoning': true,
            'computer_use': true,
          },
          'notifications': {
            'responses': true,
            'task_completion': true,
            'suggestions': true,
            'computer_use_notification': true,
          },
          'data_controls': {
            'send_product_usage_analytics': true,
            'send_error_updates': true,
            'use_system_wide_memory': true,
          },
          'advanced': {
            'backend_url': DataConstants.url,
          }
        };
        await DataConstants.settingsBox?.put(key, defaultSettings);
      }
    }
  }

  Future<void> logout() async {
    _loggedInUser = null;
    box.delete(_userKey);
    DataConstants.clearToken();
    notifyListeners();
  }

  bool isAuthenticated() {
    return _loggedInUser != null;
  }

  String? getToken() {
    return DataConstants.getToken();
  }
}
