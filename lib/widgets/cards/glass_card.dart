import 'dart:ui';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';

/// A frosted glass card with optional animated border glow.
///
/// Creates a premium glassmorphism effect with:
/// - BackdropFilter blur
/// - Semi-transparent background with border
/// - Optional animated border glow (primary color pulse)
class GlassCard extends StatefulWidget {
  /// The content of the card.
  final Widget child;

  /// Blur amount for the frosted effect.
  final double blur;

  /// Background opacity (0.0 - 1.0).
  final double opacity;

  /// Custom glow color (uses primary if null).
  final Color? glowColor;

  /// Glow intensity (0.0 - 1.0).
  final double glowIntensity;

  /// Whether to animate the glow.
  final bool animateGlow;

  /// Border radius.
  final double borderRadius;

  /// Padding inside the card.
  final EdgeInsets padding;

  /// Custom border color.
  final Color? borderColor;

  /// Border width.
  final double borderWidth;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = AnimationConstants.glassBlur,
    this.opacity = AnimationConstants.glassOpacity,
    this.glowColor,
    this.glowIntensity = AnimationConstants.glassGlowIntensity,
    this.animateGlow = true,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(24.0),
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: AnimationConstants.glowPulse,
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.animateGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateGlow && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.animateGlow && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.value = 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glowColor = widget.glowColor ?? colorScheme.primary;
    final borderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: AnimationConstants.glassBorderOpacity)
            : Colors.black.withValues(alpha: AnimationConstants.glassBorderOpacity * 0.5));
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: widget.opacity)
        : Colors.black.withValues(alpha: widget.opacity * 0.5);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowOpacity = widget.animateGlow
            ? widget.glowIntensity * _glowAnimation.value
            : widget.glowIntensity;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.glowIntensity > 0
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: glowOpacity * 0.3),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: glowColor.withValues(alpha: glowOpacity * 0.15),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: borderColor,
                    width: widget.borderWidth,
                  ),
                ),
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A simpler glass container without the animated glow.
class SimpleGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets padding;

  const SimpleGlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: opacity)
        : Colors.black.withValues(alpha: opacity * 0.5);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
