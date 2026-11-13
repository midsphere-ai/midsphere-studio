import 'package:arcane/arcane.dart';

import '../animations/animations.dart';

/// A widget that displays a grid of cards.
class CardBuilder extends StatefulWidget {
  /// The height of each card.
  final double customHeight;

  /// The width of each card.
  final double? customWidth;

  /// The list of items to display in the grid.
  final List items;

  /// A builder function that is called to build each card.
  final NullableIndexedWidgetBuilder builder;

  /// Whether to animate grid items with staggered entrance. Default: true.
  final bool animateItems;

  /// Creates a new [CardBuilder] widget.
  ///
  /// The [items] and [builder] parameters are required.
  const CardBuilder({
    super.key,
    this.customHeight = 180,
    this.customWidth,
    required this.items,
    required this.builder,
    this.animateItems = true,
  });

  @override
  State<CardBuilder> createState() => _CardBuilderState();
}

class _CardBuilderState extends State<CardBuilder> {
  @override
  Widget build(BuildContext context) {
    const double spacing = 8;
    const double crossAxisSpacing = spacing;
    const double mainAxisSpacing = spacing;
    final double mainAxisExtent = widget.customHeight;
    final double maxCrossAxisExtent = MediaQuery.sizeOf(context).width < 801
        ? (800)
        : (widget.customWidth ?? 300);
    const double childAspectRatio = 4.6;

    if (widget.items.isEmpty) {
      return  Container();
    }

    final delegate = SliverGridDelegateWithMaxCrossAxisExtent(
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        mainAxisExtent: mainAxisExtent,
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      gridDelegate: delegate,
      primary: false,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final child = widget.builder(context, index);
        if (child == null) return const SizedBox.shrink();
        if (widget.animateItems) {
          return AnimatedGridItem(
            index: index,
            child: child,
          );
        }
        return child;
      },
    );
  }
}
