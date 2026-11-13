/// Web implementation - no-ops since window controls don't apply.
import 'package:flutter/widgets.dart';

bool get isDesktopPlatform => false;

void minimizeWindow() {}

void maximizeOrRestoreWindow() {}

void closeWindow() {}

void startDragging() {}

bool get isWindowMaximized => false;

void initializeDesktopWindow({
  required Size initialSize,
  required Size minSize,
  required String title,
}) {}
