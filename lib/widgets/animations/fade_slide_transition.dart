import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// A composite transition widget that combines fade and slide animations.
///
/// Use this widget to wrap content that should animate in with both
/// opacity and position transitions.
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;
  final bool animate;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = AnimationConstants.entranceFade,
    this.delay = Duration.zero,
    this.curve = AnimationConstants.entranceCurve,
    this.slideOffset = AnimationConstants.slideFromBottom,
    this.animate = true,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
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
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A variant that also includes scale animation for more dynamic entrances.
class FadeSlideScaleTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;
  final double scaleStart;
  final bool animate;

  const FadeSlideScaleTransition({
    super.key,
    required this.child,
    this.duration = AnimationConstants.entranceFade,
    this.delay = Duration.zero,
    this.curve = AnimationConstants.entranceCurve,
    this.slideOffset = AnimationConstants.slideFromBottom,
    this.scaleStart = AnimationConstants.scaleStart,
    this.animate = true,
  });

  @override
  State<FadeSlideScaleTransition> createState() => _FadeSlideScaleTransitionState();
}

class _FadeSlideScaleTransitionState extends State<FadeSlideScaleTransition>
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
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
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
