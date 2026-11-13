// Copyright (c) 2025-2026 Midsphere AI
import 'dart:async';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/hive/hive_registrar.g.dart';
import 'package:flutter_client/widgets/window/platform_window.dart'
    if (dart.library.io) 'package:flutter_client/widgets/window/platform_window_io.dart'
    if (dart.library.html) 'package:flutter_client/widgets/window/platform_window_web.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/pages/chat/base.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/pages/navigator.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:sentry/sentry.dart';
import 'logics/data/helpers/notifications.dart';
import 'logics/data/repositories/authentication.dart';
import 'configure_nonweb.dart' if (dart.library.html) 'configure_web.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'logics/services/google_auth/google_auth.dart';

final postHogInstance = Posthog();
final platform = googleAuthPlatform;

Future<void> initHiveAdapters() async {
  await Hive.initFlutter();
  await Hive.openBox('authentication');
  await initGoogleAuth(const String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: ''));
  DataConstants.settingsBox = await Hive.openBox('settings');
  DataConstants.box = await Hive.openBox('storage');
  Hive.registerAdapters();
  AuthenticationProvider().initialize();
}

void setupSentryAndRunApp() async {
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options.debug = false;
      options.sendDefaultPii = true;
      options.dsn = sentryDsn;
    });
  }
  runApp('app', BaseApp(key: ValueKey('mainKey')));

  // Initialize window for desktop platforms
  initializeDesktopWindow(
    initialSize: const Size(1280, 720),
    minSize: const Size(800, 600),
    title: "Midsphere Studio",
  );
}

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final notificationService = LocalNotificationService();
      await notificationService.initialize(
        onNotificationClick: (payload) {
          if (payload?.contains('conversation-') ?? false) {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              ChatUI(
                key: ValueKey(payload!.split('-').last),
                conversationId: payload.split('-').last,
                isBusy: true,
              ),
              "Chat",
              LucideIcons.messagesSquare,
              shouldShowBorder: true,
            );
          }
        },
      );
      await notificationService.requestPermissions();

      WidgetsBinding.instance.platformDispatcher.views.first;
      await initHiveAdapters();
      configureApp();
      DataConstants.validateApiUrl();
      setupSentryAndRunApp();
    },
    (exception, stackTrace) async {
      if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
        await Sentry.captureException(exception, stackTrace: stackTrace);
      }
    },
  );
}
