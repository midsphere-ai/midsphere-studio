// ignore_for_file: depend_on_referenced_packages

import 'dart:async' show TimeoutException;

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

part 'base_event.dart';
part 'base_state.dart';

typedef FetchFunction<T, P> = Future<T> Function(P params);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class BaseBloc<T, P> extends Bloc<BaseEvent, BaseState> {
  final FetchFunction<T, P> fetchFunction;

  BaseBloc(this.fetchFunction) : super(LoadingState()) {
    on<LoadInitial>((event, emit) {
      emit(BaseInitial());
    });

    on<LoadSuccessWidgetWithErrorNotification<P>>((event, emit) async {
      emit(LoadingState());
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessState<T>(data));
      } on TimeoutException {
        emit(ErrorNotification('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorNotification(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    on<LoadSuccessNotificationWithErrorNotification<P>>((event, emit) async {
      emit(LoadingState());
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessNotification(data.toString()));
      } on TimeoutException {
        emit(ErrorNotification('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorNotification(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    on<LoadSuccessWidgetWithErrorWidget<P>>((event, emit) async {
      emit(LoadingState());
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessState<T>(data));
      } on TimeoutException {
        emit(ErrorState('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorState(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    on<LoadSuccessNotificationWithErrorWidget<P>>((event, emit) async {
      emit(LoadingState());
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessNotification(data.toString()));
      } on TimeoutException {
        emit(ErrorState('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorState(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    // New event handlers for "none" types
    on<LoadSuccessWidgetWithErrorNone<P>>((event, emit) async {
      emit(LoadingState());
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessState<T>(data));
      } on TimeoutException {
        emit(BaseInitial());
      } catch (e, s) {
        debugPrint('[BaseBloc] Silent error in ${event.runtimeType}: $e');
        debugPrint('$s');
        // Do nothing for error - just stay in current state or emit initial state
        emit(BaseInitial());
      }
    });

    on<LoadSuccessNoneWithErrorWidget<P>>((event, emit) async {
      try {
        await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        // Do nothing for success - just stay in current state or emit initial state
        emit(BaseInitial());
      } on TimeoutException {
        emit(ErrorState('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorState(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    on<LoadSuccessNotificationWithErrorNone<P>>((event, emit) async {
      try {
        final data = await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        emit(SuccessNotification(data.toString()));
      } on TimeoutException {
        emit(BaseInitial());
      } catch (e, s) {
        debugPrint('[BaseBloc] Silent error in ${event.runtimeType}: $e');
        debugPrint('$s');
        // Do nothing for error - just stay in current state or emit initial state
        emit(BaseInitial());
      }
    });

    on<LoadSuccessNoneWithErrorNotification<P>>((event, emit) async {
      try {
        await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        // Do nothing for success - just stay in current state or emit initial state
        emit(BaseInitial());
      } on TimeoutException {
        emit(ErrorNotification('Request timed out after 30 seconds'));
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('$e');
          debugPrint('$s');
        }
        emit(ErrorNotification(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')));
      }
    });

    on<LoadSuccessNoneWithErrorNone<P>>((event, emit) async {
      try {
        await fetchFunction(event.params).timeout(const Duration(seconds: 30));
        // Do nothing for success - just stay in current state or emit initial state
        emit(BaseInitial());
      } on TimeoutException {
        emit(BaseInitial());
      } catch (e, s) {
        debugPrint('[BaseBloc] Silent error in ${event.runtimeType}: $e');
        debugPrint('$s');
        // Do nothing for error - just stay in current state or emit initial state
        emit(BaseInitial());
      }
    });
  }
}
