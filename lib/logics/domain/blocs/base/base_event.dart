part of 'base_bloc.dart';

@immutable
sealed class BaseEvent {}

class LoadInitial extends BaseEvent {}

class LoadSuccessWidgetWithErrorNotification<P> extends BaseEvent {
  final P params;
  LoadSuccessWidgetWithErrorNotification(this.params);
}

class LoadSuccessNotificationWithErrorNotification<P> extends BaseEvent {
  final P params;
  LoadSuccessNotificationWithErrorNotification(this.params);
}

class LoadSuccessWidgetWithErrorWidget<P> extends BaseEvent {
  final P params;
  LoadSuccessWidgetWithErrorWidget(this.params);
}

class LoadSuccessNotificationWithErrorWidget<P> extends BaseEvent {
  final P params;
  LoadSuccessNotificationWithErrorWidget(this.params);
}

// New event classes for "none" types
class LoadSuccessWidgetWithErrorNone<P> extends BaseEvent {
  final P params;
  LoadSuccessWidgetWithErrorNone(this.params);
}

class LoadSuccessNoneWithErrorWidget<P> extends BaseEvent {
  final P params;
  LoadSuccessNoneWithErrorWidget(this.params);
}

class LoadSuccessNotificationWithErrorNone<P> extends BaseEvent {
  final P params;
  LoadSuccessNotificationWithErrorNone(this.params);
}

class LoadSuccessNoneWithErrorNotification<P> extends BaseEvent {
  final P params;
  LoadSuccessNoneWithErrorNotification(this.params);
}

class LoadSuccessNoneWithErrorNone<P> extends BaseEvent {
  final P params;
  LoadSuccessNoneWithErrorNone(this.params);
}
