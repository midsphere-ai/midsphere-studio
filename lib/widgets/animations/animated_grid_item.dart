import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// A widget that animates a grid item with a staggered entrance animation.
///
/// Use this widget to wrap individual grid/card items for smooth staggered
/// entrance animations. The [index] determines the animation delay.
/// Includes scale animation in addition to fade and slide for a more
/// dynamic card entrance effect.
class AnimatedGridItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final double scaleStart;
  final bool animate;

  const AnimatedGridItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = AnimationConstants.staggerDelaySlow,
    this.duration = AnimationConstants.entranceFade,
    this.curve = AnimationConstants.entranceCurve,
    this.slideOffset = AnimationConstants.slideFromBottom,
    this.scaleStart = AnimationConstants.scaleStart,
    this.animate = true,
  });

  @override
  State<AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = curvedAnimation;

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    _scaleAnimation = Tween<double>(
      begin: widget.scaleStart,
      end: AnimationConstants.scaleEnd,
    ).animate(curvedAnimation);

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
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A builder function type for creating animated grid items.
typedef AnimatedGridItemBuilder = Widget Function(
  BuildContext context,
  int index,
  Widget child,
);

/// Creates a default animated grid item builder.
AnimatedGridItemBuilder defaultAnimatedGridItemBuilder({
  Duration staggerDelay = AnimationConstants.staggerDelaySlow,
  Duration duration = AnimationConstants.entranceFade,
  Curve curve = AnimationConstants.entranceCurve,
  Offset slideOffset = AnimationConstants.slideFromBottom,
  double scaleStart = AnimationConstants.scaleStart,
}) {
  return (context, index, child) => AnimatedGridItem(
        index: index,
        staggerDelay: staggerDelay,
        duration: duration,
        curve: curve,
        slideOffset: slideOffset,
        scaleStart: scaleStart,
        child: child,
      );
}
