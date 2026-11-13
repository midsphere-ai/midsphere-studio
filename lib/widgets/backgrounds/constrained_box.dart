import 'package:arcane/arcane.dart';

/// A widget that centers its child and constrains its width.
///
/// This widget is useful for displaying content in a limited width,
/// such as a chat window or a form.
class LimitedWindowBox extends StatefulWidget {
  /// The maximum width of the content.
  final double customWidth;

  /// The widget to display.
  final Widget child;

  /// Creates a new [LimitedWindowBox] widget.
  ///
  /// The [child] parameter is required.
  /// The [customWidth] parameter defaults to 640.
  const LimitedWindowBox({
    super.key,
    required this.child,
    this.customWidth = 640,
  });

  @override
  State<LimitedWindowBox> createState() => _LimitedWindowBoxState();
}

class _LimitedWindowBoxState extends State<LimitedWindowBox> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.customWidth),
        child: widget.child,
      ),
    );
  }
}
