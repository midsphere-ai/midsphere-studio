// Google Auth abstraction with conditional imports
// Uses stub on non-web platforms, real implementation on web

export 'google_auth_stub.dart' if (dart.library.html) 'google_auth_web.dart';
