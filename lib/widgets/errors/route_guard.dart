import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/state/simple_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../logics/data/repositories/authentication.dart';
import '../../logics/domain/blocs/simple/simple_bloc.dart';
import '../../logics/domain/usecases/workspace/workspace_usecase.dart';

/// A widget that guards routes based on the user's authentication status.
///
/// This widget checks if the user is authenticated and displays the child
/// widget if they are. If the user is not authenticated, it displays an
/// error message.
class RouteGuard extends StatefulWidget {
  /// The widget to display if the user is authenticated.
  final Widget child;

  /// Creates a new [RouteGuard] widget.
  ///
  /// The [child] parameter is required.
  const RouteGuard({super.key, required this.child});

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SimpleBlocWidget(
        key: Key("RouteGuard"),
        errorWidgetBuilder: (_) {
          return errorBuilder();
        },
        successWidgetBuilder: (data) {
          if (data == null) {
            return invalidAuth();
          }
          return widget.child;
        },
        loadingWidget: widget.child.asSkeleton(),
        blocInit: (SimpleBloc bloc) {
          bloc.run(
            function: WorkSpace.fetchUserInfo,
            args: {},
            successType: SuccessType.widget,
            errorType: ErrorType.widget,
          );
        },
        child: Center(child: CircularProgressIndicator(size: 42)),
      ),
    );
  }

  /// Builds the widget to display when an error occurs.
  Widget errorBuilder() {
    return LimitedWindowBox(
      customWidth: 480,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(LucideIcons.circleAlert, size: 128, color: Colors.red),
          SizedBox(height: 16),
          Text(
            "We’re having trouble connecting to Midsphere right now. Please log out and sign back in to retry.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ).small,
          const SizedBox(height: 16),
          DestructiveButton(
            child: Text("Logout"),
            onPressed: () async {
              String message = await WorkSpace.logout();
              if (message == 'success') {
                context.pushReplacement('/');
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds the widget to display when the user is not authenticated.
  Widget invalidAuth() {
    return LimitedWindowBox(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 4,
          children: [
            Icon(LucideIcons.badgeAlert, size: 128, color: Colors.red),
            Text(
              "You are not authorised to view this page.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlineButton(
                  child: Text('Go back'),
                  onPressed: () {
                    if (AuthenticationProvider().loggedInUser != null) {
                      context.go('/home');
                    } else {
                      context.go('/');
                    }
                  },
                ),
                DestructiveButton(
                  child: Text("Logout"),
                  onPressed: () async {
                    String message = await WorkSpace.logout();
                    if (message == 'success') {
                      context.pushReplacement('/');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
