part of 'base_bloc.dart';

@immutable
sealed class BaseState {}

final class BaseInitial extends BaseState {}

final class LoadingState extends BaseState {}

final class SuccessState<T> extends BaseState {
  final T data;
  SuccessState(this.data);
}

final class ErrorNotification extends BaseState {
  final String message;
  ErrorNotification(this.message);
}

final class ErrorState extends BaseState {
  final String message;
  ErrorState(this.message);
}

final class SuccessNotification extends BaseState {
  final String message;
  SuccessNotification(this.message);
}
