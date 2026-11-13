part of 'login_bloc.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

class LoadingStart extends LoginState {}

class MSignInError extends LoginState {
  final String error;

  MSignInError({required this.error});
}

class SignInSuccess extends LoginState {}
