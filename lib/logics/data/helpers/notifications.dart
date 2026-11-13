import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:windows_notification/notification_message.dart';
import 'dart:io' show Platform;

// Import Windows notification package conditionally
import 'package:windows_notification/windows_notification.dart'
    if (dart.library.html) 'package:windows_notification/windows_notification.dart';

/// A service class to handle local notifications across all Flutter platforms
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Windows notification plugin
  WindowsNotification? _winNotifyPlugin;

  bool _isInitialized = false;

  // Callback for notification taps
  Function(String? payload)? _onNotificationClick;

  // Store last notification payload for Windows workaround
  String? _lastWindowsPayload;

  /// Initialize the notification service
  Future<void> initialize({
    Function(String? payload)? onNotificationClick,
  }) async {
    if (_isInitialized) return;

    // Store the click callback
    _onNotificationClick = onNotificationClick;

    // Initialize Windows-specific plugin
    if (!kIsWeb && Platform.isWindows) {
      try {
        _winNotifyPlugin = WindowsNotification(
          applicationId: "Midsphere Studio",
        );
        _winNotifyPlugin!.initNotificationCallBack((callback) {
          // Window restore handled by system
        });
        _isInitialized = true;

        return;
      } catch (e) {
        debugPrint('Windows notification error: $e');
      }
    }

    // Initialize for other platforms
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const DarwinInitializationSettings macosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
          macOS: macosSettings,
          linux: linuxSettings,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request permissions (mainly for iOS/macOS/Android)
  Future<bool> requestPermissions() async {
    // Windows doesn't need explicit permission request
    if (!kIsWeb && Platform.isWindows) {
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted = await androidImplementation
          ?.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Windows-specific notification
    if (!kIsWeb && Platform.isWindows) {
      if (_winNotifyPlugin != null) {
        try {
          NotificationMessage message = NotificationMessage.fromPluginTemplate(
            id.toString(),
            title,
            body,
            group: 'local',
          );

          _winNotifyPlugin!.showNotificationPluginTemplate(message);
        } catch (e) {
          debugPrint('❌ Windows notification error: $e');
        }
      }
      return;
    }

    // Other platforms
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'Default notification channel',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const DarwinNotificationDetails macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show a notification with custom sound
  Future<void> showNotificationWithSound({
    required int id,
    required String title,
    required String body,
    required String soundFileName,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Windows doesn't support custom sounds easily, use default
    if (!kIsWeb && Platform.isWindows) {
      return showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'sound_channel',
          'Sound Channel',
          channelDescription: 'Notification channel with custom sound',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundFileName),
        );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: soundFileName,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final DarwinNotificationDetails macosDetails = DarwinNotificationDetails(
      sound: soundFileName,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show a notification with progress bar (Android only)
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required int progress,
    int maxProgress = 100,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Not supported on Windows
    if (!kIsWeb && Platform.isWindows) {
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'progress_channel',
          'Progress Channel',
          channelDescription: 'Notification channel for progress updates',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          onlyAlertOnce: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    if (!kIsWeb && Platform.isWindows) {
      _winNotifyPlugin?.removeNotificationId(id.toString(), 'local');
      return;
    }
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!kIsWeb && Platform.isWindows) {
      _winNotifyPlugin?.clearNotificationHistory();
      return;
    }
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications (not supported on Windows)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!kIsWeb && Platform.isWindows) {
      return [];
    }
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      return await androidImplementation?.getActiveNotifications() ?? [];
    }
    return [];
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {

    // Call the custom callback if provided
    if (_onNotificationClick != null) {
      _onNotificationClick!(response.payload);
    }
  }

  /// Set or update the notification click handler
  void setNotificationClickHandler(Function(String? payload) handler) {
    _onNotificationClick = handler;
  }

  /// Get the last Windows notification payload (workaround for Windows)
  String? getLastWindowsPayload() {
    return _lastWindowsPayload;
  }

  /// Clear the last Windows payload after handling
  void clearLastWindowsPayload() {
    _lastWindowsPayload = null;
  }
}
