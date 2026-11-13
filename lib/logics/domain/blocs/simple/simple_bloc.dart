import '../base/base_bloc.dart';

enum ErrorType { widget, notification, none }

enum SuccessType { widget, notification, none }

class SimpleBloc extends BaseBloc<dynamic, Map> {
  SimpleBloc()
      : super((params) async {
    try {
      final function = params['function'];
      final args = params['args'];

      if (args is Map<Symbol, dynamic>) {
        return await Function.apply(function, [], args);
      }
      final symbolArgs = convertToSymbolMap(args);
      return await Function.apply(function, [], symbolArgs);
    } catch (e) {
      rethrow;
    }
  });

  void run(
      {required Function function,
        required Map<dynamic, dynamic> args,
        required ErrorType errorType,
        required SuccessType successType}) {
    final data = {'function': function, 'args': convertToSymbolMap(args)};

    if (errorType == ErrorType.widget && successType == SuccessType.widget) {
      add(LoadSuccessWidgetWithErrorWidget(data));
    } else if (errorType == ErrorType.notification && successType == SuccessType.widget) {
      add(LoadSuccessWidgetWithErrorNotification(data));
    } else if (errorType == ErrorType.widget && successType == SuccessType.notification) {
      add(LoadSuccessNotificationWithErrorWidget(data));
    } else if (errorType == ErrorType.notification && successType == SuccessType.notification) {
      add(LoadSuccessNotificationWithErrorNotification(data));
    } else if (errorType == ErrorType.none && successType == SuccessType.widget) {
      add(LoadSuccessWidgetWithErrorNone(data));
    } else if (errorType == ErrorType.widget && successType == SuccessType.none) {
      add(LoadSuccessNoneWithErrorWidget(data));
    } else if (errorType == ErrorType.none && successType == SuccessType.notification) {
      add(LoadSuccessNotificationWithErrorNone(data));
    } else if (errorType == ErrorType.notification && successType == SuccessType.none) {
      add(LoadSuccessNoneWithErrorNotification(data));
    } else if (errorType == ErrorType.none && successType == SuccessType.none) {
      add(LoadSuccessNoneWithErrorNone(data));
    }
  }

  static Map<Symbol, dynamic> convertToSymbolMap(
      Map<dynamic, dynamic> normalMap) {
    Map<Symbol, dynamic> symbolMap = {};
    normalMap.forEach((key, value) {
      String camelCaseKey = _snakeToCamelCase(key.toString());
      var processedValue = value;
      if (value is List) {
        processedValue = List<dynamic>.from(value);
      }

      symbolMap[Symbol(camelCaseKey)] = processedValue;
    });
    return symbolMap;
  }

  static String _snakeToCamelCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'_([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
    );
  }
}
