// Web implementation for Google Sign-In
// This file is only used when compiling for web

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/web_only.dart';

// Re-export all types from the web package
export 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    show
        GoogleSignInUserData,
        AuthenticationEvent,
        AuthenticationEventSignIn,
        AuthenticationEventSignOut,
        AuthenticationEventException,
        InitParameters,
        SignOutParams;

export 'package:google_sign_in_web/web_only.dart'
    show
        GSIButtonConfiguration,
        GSIButtonLogoAlignment,
        GSIButtonShape,
        GSIButtonType,
        GSIButtonTheme,
        GSIButtonSize,
        GSIButtonText,
        renderButton;

/// The platform instance for web
final googleAuthPlatform = GoogleSignInPlatform.instance;

/// Initialize Google Auth for web
Future<void> initGoogleAuth(String clientId) async {
  await GoogleSignInPlatform.instance.init(
    InitParameters(clientId: clientId),
  );
}
