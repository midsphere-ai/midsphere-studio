import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/global_logics.dart';
import '../../../data/repositories/authentication.dart';
import '../../entities/workspace/users/user.dart';
import '../base.dart';
import 'endpoint_enums.dart';

class WorkSpace {
  static T handleBooleanResponse<T>(dynamic data) {
    return data;
  }

  static Future<void> initializeGoogleSignIn() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      // Initialization already done in main.dart via initGoogleAuth()
      // Just set up the auth event listener and attempt lightweight auth
      signIn.authenticationEvents
          .listen((event) {})
          .onError((event) {});
      signIn.attemptLightweightAuthentication();
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> loginViaGoogle(token) async {
    const apiEndpoint = 'workspace/google-provider/verify';
    final response = await NetworkConnector.performPost(
      apiEndpoint,
      data: {'id_token': token},
    );

    if (NetworkConnector.isSuccessful(response.statusCode)) {
      final key = response.data['key'] as String?;
      if (key == null) {
        throw Exception('Authentication key missing in response.');
      }

      NetworkConnector.dio.options.headers["Authorization"] = "Bearer $key";
      DataConstants.setToken(key);
      await fetchUserInfo(refresh: true);
      return key;
    }
    throw Exception('Failed to log in: ${response.statusMessage}');
  }

  static Future<String> login(Map<String, dynamic> data) async {
    const apiEndpoint = 'authentication/login/';
    final response = await NetworkConnector.performPost(
      apiEndpoint,
      data: data,
    );

    if (NetworkConnector.isSuccessful(response.statusCode)) {
      final key = response.data['key'] as String?;
      if (key == null) {
        throw Exception('Authentication key missing in response.');
      }

      NetworkConnector.dio.options.headers["Authorization"] = "Bearer $key";
      DataConstants.setToken(key);
      await fetchUserInfo(refresh: true);
      return key;
    }
    throw Exception('Failed to log in: ${response.statusMessage}');
  }

  static Future<String> logout() async {
    const apiEndpoint = 'authentication/logout/';
    final response = await NetworkConnector.performPost(apiEndpoint);

    if (NetworkConnector.isSuccessful(response.statusCode)) {
      NetworkConnector.dio.options.headers["Authorization"] = "";
      await AuthenticationProvider().logout();
      return 'success';
    }
    throw Exception('Failed to log out: ${response.statusMessage}');
  }

  static Future<User?> fetchUserInfo({bool refresh = false}) async {
    const apiEndpoint = 'workspace/users/me/';
    final response = await NetworkConnector.performGet(apiEndpoint);

    if (NetworkConnector.isSuccessful(response.statusCode)) {
      final user = User.fromJson(response.data);
      AuthenticationProvider().login(user);
      return user;
    }
    return null;
  }

  static Future<dynamic> createUser(
    String userName,
    String userEmail,
    String password,
  ) async {
    return NetworkConnector.callEndpoint(WorkspaceEndpoints.createUser, {
      'user_name': userName,
      'user_email': userEmail,
      'password': password,
    });
  }

  static Future<dynamic> removeUser(String userId) async {
    return NetworkConnector.callEndpoint(WorkspaceEndpoints.removeUser, {
      'user_id': userId,
    });
  }

  static Future<dynamic> updateUser({
    required String userName,
    required String userEmail,
    required int userId,
  }) async {
    return NetworkConnector.callEndpoint(WorkspaceEndpoints.updateUser, {
      'user_name': userName,
      'user_email': userEmail,
      'user_id': userId,
    });
  }
}
