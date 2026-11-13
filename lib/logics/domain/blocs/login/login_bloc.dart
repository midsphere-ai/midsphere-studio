// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:meta/meta.dart';

import '../../usecases/workspace/workspace_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoadLogin>(load);
    on<EmailLogin>(login);
  }

  FutureOr<void> login(EmailLogin event, Emitter<LoginState> emit) async {
    emit(LoadingStart());
    try {
      Map<String, String> data = {
        'email': event.email,
        'password': event.userPassword,
      };

      await WorkSpace.login(data);
      emit(SignInSuccess());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        emit(MSignInError(error: "Connection timed out to the server. Please try again."));
      } else if (e.response?.statusCode == 401) {
        emit(MSignInError(error: "Connection error 401. Please try again after some time."));
      } else {
        emit(MSignInError(error: "This account does not exist with us."));
      }
    } catch (e, s) {
      // Handle other errors
      // ignore: avoid_print
      debugPrint('$s');
      emit(MSignInError(error: "The account may not exist, or the email/password is incorrect."));
    }
  }

  FutureOr<void> load(LoadLogin event, Emitter<LoginState> emit) {
    emit(LoginInitial());
  }
}
