part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class LoadLogin extends LoginEvent{}

class EmailLogin extends LoginEvent{
  final String email;
  final String userPassword;

  EmailLogin(this.email, this.userPassword);

}
