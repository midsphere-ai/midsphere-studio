import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// A widget that animates a list item with a staggered entrance animation.
///
/// Use this widget to wrap individual list items for smooth staggered
/// entrance animations. The [index] determines the animation delay.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final bool animate;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = AnimationConstants.staggerDelay,
    this.duration = AnimationConstants.entranceFade,
    this.curve = AnimationConstants.entranceCurve,
    this.slideOffset = AnimationConstants.slideFromBottom,
    this.animate = true,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate) {
      final delay = widget.staggerDelay * widget.index;
      Future.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A builder function type for creating animated list items.
typedef AnimatedListItemBuilder = Widget Function(
  BuildContext context,
  int index,
  Widget child,
);

/// Creates a default animated list item builder.
AnimatedListItemBuilder defaultAnimatedListItemBuilder({
  Duration staggerDelay = AnimationConstants.staggerDelay,
  Duration duration = AnimationConstants.entranceFade,
  Curve curve = AnimationConstants.entranceCurve,
  Offset slideOffset = AnimationConstants.slideFromBottom,
}) {
  return (context, index, child) => AnimatedListItem(
        index: index,
        staggerDelay: staggerDelay,
        duration: duration,
        curve: curve,
        slideOffset: slideOffset,
        child: child,
      );
}
