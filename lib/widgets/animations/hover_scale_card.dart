import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// A widget that scales up slightly when hovered (desktop) or pressed (mobile).
///
/// Use this wrapper to add subtle hover feedback to cards and interactive elements.
class HoverScaleCard extends StatefulWidget {
  /// The child widget to wrap with hover effect.
  final Widget child;

  /// The scale factor when hovered. Default: 1.02 (2% larger).
  final double hoverScale;

  /// Duration of the scale animation. Default: 150ms.
  final Duration duration;

  /// The curve for the hover animation. Default: easeOut.
  final Curve curve;

  /// Whether the hover effect is enabled. Default: true.
  final bool enabled;

  /// Optional callback when the widget is hovered.
  final VoidCallback? onHoverStart;

  /// Optional callback when the hover ends.
  final VoidCallback? onHoverEnd;

  const HoverScaleCard({
    super.key,
    required this.child,
    this.hoverScale = AnimationConstants.hoverScaleDefault,
    this.duration = AnimationConstants.pressHover,
    this.curve = AnimationConstants.pressHoverCurve,
    this.enabled = true,
    this.onHoverStart,
    this.onHoverEnd,
  });

  /// Creates a HoverScaleCard with subtle scale (1.01).
  const HoverScaleCard.subtle({
    super.key,
    required this.child,
    this.hoverScale = AnimationConstants.hoverScaleSubtle,
    this.duration = AnimationConstants.pressHover,
    this.curve = AnimationConstants.pressHoverCurve,
    this.enabled = true,
    this.onHoverStart,
    this.onHoverEnd,
  });

  /// Creates a HoverScaleCard with pronounced scale (1.03).
  const HoverScaleCard.pronounced({
    super.key,
    required this.child,
    this.hoverScale = AnimationConstants.hoverScalePronounced,
    this.duration = AnimationConstants.pressHover,
    this.curve = AnimationConstants.pressHoverCurve,
    this.enabled = true,
    this.onHoverStart,
    this.onHoverEnd,
  });

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;

  void _handleHoverChanged(bool isHovered) {
    if (!widget.enabled) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      widget.onHoverStart?.call();
    } else {
      widget.onHoverEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => _handleHoverChanged(true),
      onExit: (_) => _handleHoverChanged(false),
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// A stateful hover indicator that can be queried by child widgets.
///
/// Use this when you need to know hover state in child widgets,
/// for example to animate a chevron icon.
class HoverStateNotifier extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;
  final Duration duration;
  final bool enabled;

  const HoverStateNotifier({
    super.key,
    required this.builder,
    this.duration = AnimationConstants.pressHover,
    this.enabled = true,
  });

  @override
  State<HoverStateNotifier> createState() => _HoverStateNotifierState();
}

class _HoverStateNotifierState extends State<HoverStateNotifier> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, false);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(context, _isHovered),
    );
  }
}

/// A widget that combines hover scale with animated chevron movement.
///
/// Useful for list items that indicate navigation with a right chevron.
class HoverScaleWithChevron extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final double chevronOffset;

  const HoverScaleWithChevron({
    super.key,
    required this.child,
    this.hoverScale = AnimationConstants.hoverScaleSubtle,
    this.duration = AnimationConstants.pressHover,
    this.curve = AnimationConstants.pressHoverCurve,
    this.enabled = true,
    this.chevronOffset = 4.0,
  });

  @override
  State<HoverScaleWithChevron> createState() => _HoverScaleWithChevronState();

  /// Get the chevron offset based on hover state.
  /// Use this in child widgets to animate chevron position.
  static double getChevronOffset(bool isHovered, double maxOffset) {
    return isHovered ? maxOffset : 0.0;
  }
}

class _HoverScaleWithChevronState extends State<HoverScaleWithChevron> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: _HoverStateInherited(
          isHovered: _isHovered,
          chevronOffset: widget.chevronOffset,
          duration: widget.duration,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Inherited widget to pass hover state down the tree.
class _HoverStateInherited extends InheritedWidget {
  final bool isHovered;
  final double chevronOffset;
  final Duration duration;

  const _HoverStateInherited({
    required this.isHovered,
    required this.chevronOffset,
    required this.duration,
    required super.child,
  });

  static _HoverStateInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverStateInherited>();
  }

  @override
  bool updateShouldNotify(_HoverStateInherited oldWidget) {
    return isHovered != oldWidget.isHovered;
  }
}

/// An animated chevron icon that moves right when hovered.
///
/// Use this inside a [HoverScaleWithChevron] widget to get automatic
/// hover animation.
class AnimatedChevron extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final double maxOffset;

  const AnimatedChevron({
    super.key,
    this.icon = Icons.chevron_right,
    this.size = 20,
    this.color,
    this.maxOffset = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final inherited = _HoverStateInherited.of(context);
    final isHovered = inherited?.isHovered ?? false;
    final duration = inherited?.duration ?? AnimationConstants.pressHover;

    return AnimatedContainer(
      duration: duration,
      curve: AnimationConstants.pressHoverCurve,
      transform: Matrix4.translationValues(
        isHovered ? maxOffset : 0.0,
        0,
        0,
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
