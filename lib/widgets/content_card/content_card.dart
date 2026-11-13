import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';
import 'package:flutter_client/widgets/animations/fade_slide_transition.dart';

/// Minimal content card - just a subtle container with animation.
class ContentCard extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final bool animate;
  final Duration delay;
  final bool scrollable;
  final EdgeInsets contentPadding;
  final bool expanded;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showBorder;

  const ContentCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.animate = true,
    this.delay = Duration.zero,
    this.scrollable = false,
    this.contentPadding = const EdgeInsets.all(6),
    this.expanded = true,
    this.borderColor,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final card = Container(
      padding: showBorder ? EdgeInsets.all(4): EdgeInsets.zero,
      decoration: showBorder ? BoxDecoration(
        color: backgroundColor ?? colors.background,
        borderRadius: theme.borderRadiusSm,
        border: Border.all(
          color: borderColor ?? colors.border,
        ),
      ) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          _buildContent(context),
          if (footer != null) footer!,
        ],
      ),
    );

    if (!animate) return card;

    return FadeSlideTransition(
      duration: AnimationConstants.entranceFadeFast,
      delay: delay,
      curve: AnimationConstants.entranceCurve,
      slideOffset: const Offset(0, 0.015),
      child: card,
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget content;

    if (scrollable) {
      content = SingleChildScrollView(
        padding: contentPadding,
        child: child,
      );
    } else {
      content = Padding(
        padding: contentPadding,
        child: child,
      );
    }

    if (expanded) {
      return Expanded(child: content);
    }

    return content;
  }
}
