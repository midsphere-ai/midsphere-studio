import 'dart:math' as math;

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';

/// A widget that applies a gradient to its child widget.
class GradientText extends StatelessWidget {
  /// The widget to apply the gradient to.
  final Widget child;

  /// Custom gradient colors (uses theme colors if null).
  final List<Color>? colors;

  /// Gradient alignment start.
  final Alignment begin;

  /// Gradient alignment end.
  final Alignment end;

  /// Creates a new [GradientText] widget.
  ///
  /// The [child] parameter is required.
  const GradientText({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    List<Color> gradientColors = colors ??
        (DataConstants.currentTheme == ThemeMode.light
            ? [colorScheme.primary, colorScheme.secondary]
            : [colorScheme.primary, colorScheme.secondary]);

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors,
        begin: begin,
        end: end,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: child,
    );
  }
}

/// An animated gradient text that slowly shifts colors.
///
/// Creates a mesmerizing effect by animating the gradient angle
/// over a configurable duration (default 15 seconds).
class AnimatedGradientText extends StatefulWidget {
  /// The widget to apply the animated gradient to.
  final Widget child;

  /// Custom gradient colors (uses theme colors if null).
  final List<Color>? colors;

  /// Duration for one complete gradient cycle.
  final Duration duration;

  /// Whether to animate the gradient.
  final bool animate;

  const AnimatedGradientText({
    super.key,
    required this.child,
    this.colors,
    this.duration = AnimationConstants.gradientShift,
    this.animate = true,
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedGradientText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = widget.colors ??
        [
          colorScheme.primary,
          colorScheme.secondary,
          isDark ? colorScheme.primary.withValues(alpha: 0.8) : colorScheme.primary,
        ];

    if (!widget.animate) {
      return GradientText(
        colors: gradientColors,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;

        // Calculate gradient alignment based on animation progress
        final beginX = math.cos(angle);
        final beginY = math.sin(angle);
        final endX = math.cos(angle + math.pi);
        final endY = math.sin(angle + math.pi);

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: gradientColors,
            begin: Alignment(beginX, beginY),
            end: Alignment(endX, endY),
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}

/// A shimmer effect for text and other widgets.
///
/// Creates a moving highlight that sweeps across the widget.
class ShimmerText extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? shimmerColor;
  final bool enabled;

  const ShimmerText({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.shimmerColor,
    this.enabled = true,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = widget.shimmerColor ?? colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final position = _controller.value * 2 - 0.5;
            return LinearGradient(
              colors: [
                Colors.white,
                shimmerColor.withValues(alpha: 0.8),
                Colors.white,
              ],
              stops: [
                (position - 0.3).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}
