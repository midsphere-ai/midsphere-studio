import 'package:arcane/arcane.dart';

/// A base widget for the sidebar.
///
/// This widget provides a container with a background color and a stack
/// to layer the sidebar content.
class SideBarBase extends StatelessWidget {
  /// The widget to display as the content of the sidebar.
  final Widget child;

  /// Creates a new [SideBarBase] widget.
  ///
  /// The [child] parameter is required.
  const SideBarBase({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 255,
      height: double.infinity,
      color: colors.background,
      child: child,
    );
  }
}
