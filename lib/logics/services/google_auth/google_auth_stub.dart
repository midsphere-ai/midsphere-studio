// Stub implementation for non-web platforms
// This file is used when compiling for desktop/mobile platforms

import 'dart:async';
import 'package:flutter/widgets.dart';

/// Stub class for GoogleSignInUserData on non-web platforms
class GoogleSignInUserData {
  final String? displayName;
  final String? email;
  final String? id;
  final String? photoUrl;

  GoogleSignInUserData({
    this.displayName,
    this.email,
    this.id,
    this.photoUrl,
  });
}

/// Stub class for GSIButtonConfiguration on non-web platforms
class GSIButtonConfiguration {
  final String? locale;
  final double? minimumWidth;
  final GSIButtonType? type;
  final GSIButtonTheme? theme;
  final GSIButtonSize? size;
  final GSIButtonText? text;
  final GSIButtonShape? shape;
  final GSIButtonLogoAlignment? logoAlignment;

  const GSIButtonConfiguration({
    this.locale,
    this.minimumWidth,
    this.type,
    this.theme,
    this.size,
    this.text,
    this.shape,
    this.logoAlignment,
  });
}

/// Stub enums for button configuration
enum GSIButtonLogoAlignment { left, center }
enum GSIButtonShape { rectangular, pill, circle, square }
enum GSIButtonType { standard, icon }
enum GSIButtonTheme { outline, filledBlue, filledBlack }
enum GSIButtonSize { large, medium, small }
enum GSIButtonText { signinWith, signin, continueWith, signup }

/// Stub for authentication events
abstract class AuthenticationEvent {}

class AuthenticationEventSignIn extends AuthenticationEvent {
  final GoogleSignInUserData user;
  final AuthenticationTokens authenticationTokens;

  AuthenticationEventSignIn({required this.user, required this.authenticationTokens});
}

class AuthenticationEventSignOut extends AuthenticationEvent {}

class AuthenticationEventException extends AuthenticationEvent {}

class AuthenticationTokens {
  final String? idToken;
  final String? accessToken;

  AuthenticationTokens({this.idToken, this.accessToken});
}

/// Stub platform that does nothing on non-web
class GoogleAuthPlatformStub {
  Stream<AuthenticationEvent>? get authenticationEvents => null;

  Future<void> init(InitParameters params) async {}

  Future<void> signOut(SignOutParams params) async {}
}

class InitParameters {
  final String clientId;
  const InitParameters({required this.clientId});
}

class SignOutParams {
  const SignOutParams();
}

/// The platform instance - stub on non-web
final googleAuthPlatform = GoogleAuthPlatformStub();

/// Initialize Google Auth - no-op on non-web
Future<void> initGoogleAuth(String clientId) async {
  // No-op on non-web platforms
}

/// Render the Google sign-in button - returns empty container on non-web
Widget renderButton({GSIButtonConfiguration? configuration}) {
  return const SizedBox.shrink();
}
