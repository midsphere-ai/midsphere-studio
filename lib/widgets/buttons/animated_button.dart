import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';

/// An enhanced primary button with animated hover, press, and loading states.
///
/// Features:
/// - Hover: scale up (1.02) + subtle brightness change
/// - Press: scale down (0.98) + slight shadow
/// - Loading: content crossfades to spinner, width can animate
/// - Success: brief pulse + checkmark
class AnimatedPrimaryButton extends StatefulWidget {
  /// The button content.
  final Widget child;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  final bool isLoading;

  /// Whether the button is in success state.
  final bool isSuccess;

  /// Whether the button is disabled.
  final bool disabled;

  /// Whether to enable hover scale effect.
  final bool enableHoverScale;

  /// Whether to enable press scale effect.
  final bool enablePressScale;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Custom success widget.
  final Widget? successWidget;

  /// Duration of the loading crossfade.
  final Duration loadingTransitionDuration;

  const AnimatedPrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.disabled = false,
    this.enableHoverScale = true,
    this.enablePressScale = true,
    this.loadingWidget,
    this.successWidget,
    this.loadingTransitionDuration = AnimationConstants.buttonLoading,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _successPulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: AnimationConstants.buttonHover,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConstants.buttonHoverScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AnimationConstants.smoothEntrance,
    ));

    _successPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Symmetric pulse: scale up to 1.05 then back to 1.0, 50% duration each
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _successPulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _successPulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedPrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger success pulse when success state changes to true
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _successPulseController.forward(from: 0.0);
    }
  }

  void _onHoverChanged(bool isHovered) {
    if (widget.disabled || widget.isLoading) return;

    if (widget.enableHoverScale) {
      if (isHovered) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.disabled || widget.isLoading) return;
    if (!mounted) return;
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
  }

  double get _currentScale {
    if (_isPressed && widget.enablePressScale) {
      return AnimationConstants.buttonPressScale;
    }
    return _scaleAnimation.value;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        (widget.disabled || widget.isLoading) ? null : widget.onPressed;

    Widget content;

    if (widget.isSuccess) {
      content = widget.successWidget ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.check, size: 18),
              const SizedBox(width: 8),
              Text('Success'),
            ],
          );
    } else if (widget.isLoading) {
      content = widget.loadingWidget ??
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              size: 18,
            ),
          );
    } else {
      content = widget.child;
    }

    Widget button = PrimaryButton(
      onPressed: effectiveOnPressed,
      child: AnimatedSwitcher(
        duration: widget.loadingTransitionDuration,
        switchInCurve: AnimationConstants.smoothEntrance,
        switchOutCurve: AnimationConstants.smoothExit,
        child: KeyedSubtree(
          key: ValueKey(widget.isLoading ? 'loading' : widget.isSuccess ? 'success' : 'content'),
          child: content,
        ),
      ),
    );

    // Apply scale animations
    button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final baseScale = _currentScale;
          final pulseScale = widget.isSuccess ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: baseScale * pulseScale,
            child: child,
          );
        },
        child: child,
      ),
      child: button,
    );

    // Wrap with gesture detectors and mouse region
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: button,
      ),
    );
  }
}

/// A ghost/link button with animated underline on hover.
class AnimatedLinkButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? underlineColor;
  final bool showUnderline;

  const AnimatedLinkButton({
    super.key,
    required this.child,
    this.onPressed,
    this.underlineColor,
    this.showUnderline = true,
  });

  @override
  State<AnimatedLinkButton> createState() => _AnimatedLinkButtonState();
}

class _AnimatedLinkButtonState extends State<AnimatedLinkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _underlineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.buttonHover,
    );

    _underlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.smoothEntrance,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final underlineColor = widget.underlineColor ?? colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _underlineAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.child,
                if (widget.showUnderline)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _underlineAnimation.value,
                      child: Container(
                        height: 1,
                        color: underlineColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// An icon button with hover glow effect.
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? hoverColor;
  final bool showGlow;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.hoverColor,
    this.showGlow = true,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.buttonHover,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.smoothEntrance,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = widget.color ?? colorScheme.foreground;
    final hoverColor = widget.hoverColor ?? colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: widget.showGlow && _glowAnimation.value > 0
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: hoverColor
                              .withValues(alpha: 0.3 * _glowAnimation.value),
                          blurRadius: 12 * _glowAnimation.value,
                          spreadRadius: 0,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: Color.lerp(iconColor, hoverColor, _glowAnimation.value),
              ),
            );
          },
        ),
      ),
    );
  }
}
