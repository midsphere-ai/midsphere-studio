// ignore_for_file: file_names

import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/backgrounds/geometric.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:go_router/go_router.dart';

import '../../logics/data/repositories/authentication.dart';

/// A widget that displays a 404 error message.
class ErrorPage extends StatelessWidget {
  /// Creates a new [ErrorPage] widget.
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: BackgroundSvg()),
          LimitedWindowBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 4,
                children: [
                  Text('404').x9Large.bold,
                  Text("The page you are looking for is not available.").muted,
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      OutlineButton(
                          child: Text('Go back'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                      OutlineButton(
                          child: Text('Go home'),
                          onPressed: () {
                            if (AuthenticationProvider().loggedInUser != null) {
                              context.go('/home');
                            } else {
                              context.go('/');
                            }
                          }),
                    ],
                  )
                ],
              ),
          ),
        ],
      ),
    );
  }
}
