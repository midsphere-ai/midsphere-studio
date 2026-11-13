import 'package:flutter/material.dart';

/// Centralized animation constants for consistent timing across the app.
class AnimationConstants {
  AnimationConstants._();

  // Durations
  static const Duration pressHover = Duration(milliseconds: 100);
  static const Duration entranceFade = Duration(milliseconds: 250);
  static const Duration entranceFadeFast = Duration(milliseconds: 200);
  static const Duration entranceFadeSlow = Duration(milliseconds: 300);
  static const Duration contentSwitch = Duration(milliseconds: 250);
  static const Duration contentSwitchSlow = Duration(milliseconds: 300);
  static const Duration scaleElastic = Duration(milliseconds: 300);
  static const Duration progressBar = Duration(milliseconds: 800);

  // Stagger delays
  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const Duration staggerDelayFast = Duration(milliseconds: 50);
  static const Duration staggerDelaySlow = Duration(milliseconds: 80);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve pressHoverCurve = Curves.easeOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  // Slide offsets
  static const Offset slideFromRight = Offset(0.05, 0);
  static const Offset slideFromLeft = Offset(-0.05, 0);
  static const Offset slideFromBottom = Offset(0, 0.05);
  static const Offset slideFromTop = Offset(0, -0.05);

  // Scale values
  static const double scaleStart = 0.95;
  static const double scaleEnd = 1.0;

  // Hover scale values
  static const double hoverScaleSubtle = 1.01;
  static const double hoverScaleDefault = 1.02;
  static const double hoverScalePronounced = 1.03;

  // Image fade durations
  static const Duration imageFadeIn = Duration(milliseconds: 200);

  // Incognito mode constants
  static const Duration incognitoTransition = Duration(milliseconds: 300);
  static const Duration incognitoPulseCycle = Duration(milliseconds: 4000);
  static const double incognitoGlowAlpha = 0.08;
  static const double incognitoBorderAlpha = 0.1;
  static const double incognitoTintAlpha = 0.02;

  // Login page constants
  static const Duration modeTransition = Duration(milliseconds: 600);
  static const Duration fieldStagger = Duration(milliseconds: 70);
  static const Duration glowPulse = Duration(milliseconds: 2000);
  static const Duration gradientShift = Duration(milliseconds: 15000);
  static const Duration typewriterSpeed = Duration(milliseconds: 50);
  static const Duration orbDrift = Duration(seconds: 30);
  static const Duration backgroundBlobCycle = Duration(seconds: 20);
  static const Curve bounceEntrance = Curves.elasticOut;
  static const Curve smoothExit = Curves.easeOutQuart;
  static const Curve smoothEntrance = Curves.easeOutCubic;

  // Login button states
  static const Duration buttonHover = Duration(milliseconds: 150);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration buttonLoading = Duration(milliseconds: 300);
  static const double buttonHoverScale = 1.02;
  static const double buttonPressScale = 0.98;

  // Glass card constants
  static const double glassBlur = 12.0;
  static const double glassOpacity = 0.08;
  static const double glassBorderOpacity = 0.15;
  static const double glassGlowIntensity = 0.3;

  // Form field animation constants
  static const Duration fieldFocusTransition = Duration(milliseconds: 200);
  static const Duration fieldShakeDuration = Duration(milliseconds: 500);
  static const double fieldFocusScale = 1.01;
  static const double fieldShakeOffset = 8.0;
}
