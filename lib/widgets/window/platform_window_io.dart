/// Desktop implementation using bitsdojo_window.
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

void minimizeWindow() => appWindow.minimize();

void maximizeOrRestoreWindow() => appWindow.maximizeOrRestore();

void closeWindow() => appWindow.close();

void startDragging() => appWindow.startDragging();

bool get isWindowMaximized => appWindow.isMaximized;

void initializeDesktopWindow({
  required Size initialSize,
  required Size minSize,
  required String title,
}) {
  if (!isDesktopPlatform) return;

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = minSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = title;
    win.show();
  });
}
