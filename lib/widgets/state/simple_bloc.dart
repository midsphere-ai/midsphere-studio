import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logics/domain/blocs/base/base_bloc.dart';
import '../../logics/domain/blocs/simple/simple_bloc.dart';

/// A widget that simplifies the use of BLoC pattern.
///
/// This widget provides a simple way to handle loading, error, and success
/// states of a BLoC. It also provides a way to show notifications.
class SimpleBlocWidget extends StatefulWidget {
  /// A map of all the instances of this widget.
  static final Map<Key, _SimpleBlocWidgetState> _instances = {};

  /// The BLoC to use.
  final SimpleBloc? customBloc;

  /// A callback function that is called when the BLoC is initialized.
  final Function? blocInit;

  /// A callback function that is called when a success notification is received.
  final Function? successNotificationCallback;

  /// A callback function that is called when an error notification is received.
  final Function? errorNotificationCallback;

  /// The widget to display when the BLoC is in the loading state.
  final Widget? loadingWidget;

  /// A builder function that is called to build the widget when the BLoC
  /// is in the error state.
  final Widget Function(dynamic)? errorWidgetBuilder;

  /// A builder function that is called to build the widget when the BLoC
  /// is in the success state.
  final Widget Function(dynamic)? successWidgetBuilder;

  /// The child widget.
  final Widget child;

  /// Whether to disable the animation when switching between states.
  final bool withoutAnimation;

  /// The duration of the transition animation.
  final Duration transitionDuration;

  /// Creates a new [SimpleBlocWidget] widget.
  const SimpleBlocWidget({
    super.key,
    required this.child,
    this.loadingWidget,
    this.customBloc,
    this.errorNotificationCallback,
    this.errorWidgetBuilder,
    this.successNotificationCallback,
    this.successWidgetBuilder,
    this.blocInit,
    this.withoutAnimation = false,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SimpleBlocWidget> createState() => _SimpleBlocWidgetState();

  /// Returns the [SimpleBloc] for the specified instance of this widget.
  static SimpleBloc getInstance(Key key) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!.simpleBloc;
  }

  static void printInstances() {
  }

  static void clearAll() {
    for (final state in _instances.values) {
      state.simpleBloc.close();
    }
    _instances.clear();
  }

  /// Refreshes the specified instance of this widget.
  static void refresh(Key key) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    _instances[key]!.refresh();
  }

  static void reset(Key key){
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    _instances[key]!.reset();
  }
}

class _SimpleBlocWidgetState extends State<SimpleBlocWidget> {
  late final simpleBloc;
  String toastMessageTitle = "";
  String toastMessageDescription = "";

  @override
  void initState() {
    super.initState();
    if (widget.customBloc != null) {
      simpleBloc = widget.customBloc;
    } else {
      simpleBloc = SimpleBloc();
    }
    simpleBloc.add(LoadInitial());
    if (widget.blocInit != null) {
      widget.blocInit!(simpleBloc);
    }
    if (widget.key != null) {
      SimpleBlocWidget._instances[widget.key!] = this;
    }
  }

  @override
  void dispose() {
    simpleBloc.close();
    if (widget.key != null) {
      // Only remove if this instance is still the one in the map
      if (SimpleBlocWidget._instances[widget.key] == this) {
        SimpleBlocWidget._instances.remove(widget.key);
      } else {
        debugPrint('[SimpleBlocWidget] dispose: instance for key ${widget.key} was already replaced');
      }
    }
    super.dispose();
  }

  /// Refreshes the widget.
  void refresh() {
    setState(() {});
    simpleBloc.add(LoadInitial());
  }

  void reset(){
    widget.blocInit!(simpleBloc);
  }

  /// Builds the content of the widget based on the BLoC state.
  Widget _buildContent(BaseState state) {
    if (state is LoadingState) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }
    if (state is ErrorState) {
      return widget.errorWidgetBuilder != null
          ? widget.errorWidgetBuilder!(state.message)
          : Container();
    }
    if (state is SuccessState) {
      return widget.successWidgetBuilder != null
          ? widget.successWidgetBuilder!(state.data)
          : Container();
    }
    return widget.child;
  }

  /// Builds a toast widget.
  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: Text(toastMessageTitle),
        subtitle: Text(toastMessageDescription),
        trailing: PrimaryButton(
          size: ButtonSize.small,
          onPressed: () {
            overlay.close();
          },
          child: const Text('Undo').bold,
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleBloc, BaseState>(
      bloc: simpleBloc,
      listener: (context, state) {
        if (state is SuccessNotification) {
          toastMessageTitle = "Operation success";
          toastMessageDescription = state.message;
          showToast(
            context: context,
            builder: buildToast,
            location: ToastLocation.topCenter,
          );
          if (widget.successNotificationCallback != null) {
            widget.successNotificationCallback!(state.message);
          } else {
            simpleBloc.add(LoadInitial());
          }
        }
        if (state is ErrorNotification) {
          toastMessageTitle = "Operation failed";
          toastMessageDescription = state.message;
          showToast(
            context: context,
            builder: buildToast,
            location: ToastLocation.topCenter,
          );
          if (widget.errorNotificationCallback != null) {
            widget.errorNotificationCallback!(state.message);
          } else {
            simpleBloc.add(LoadInitial());
          }
        }
      },
      builder: (context, state) {
        if (widget.withoutAnimation) {
          return _buildContent(state);
        } else {
          return AnimatedSwitcher(
            duration: widget.transitionDuration,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildContent(state),
          );
        }
      },
    );
  }
}
