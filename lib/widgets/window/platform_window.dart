/// Stub file for conditional imports.
/// This file is never actually used - it exists to satisfy the import pattern.
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
