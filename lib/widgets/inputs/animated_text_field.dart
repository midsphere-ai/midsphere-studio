import 'dart:math' as math;

import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';

/// An enhanced text field wrapper with animated focus states.
///
/// Features:
/// - Focus: border glow pulse, icon color change, subtle scale
/// - Error: shake animation with elastic curve
/// - Valid: subtle green checkmark fade-in
/// - Unfocus: graceful return animation
class AnimatedTextField extends StatefulWidget {
  /// The text controller.
  final TextEditingController? controller;

  /// Placeholder text widget.
  final Widget? placeholder;

  /// Input features (icons, password toggle, etc.).
  final List<InputFeature>? features;

  /// Whether the field has an error.
  final bool hasError;

  /// Whether the field is valid (shows checkmark).
  final bool isValid;

  /// Called when the field value changes.
  final ValueChanged<String>? onChanged;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Called when the field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field is obscured (password).
  final bool obscureText;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Whether to enable shake on error.
  final bool shakeOnError;

  /// Whether to show glow on focus.
  final bool showFocusGlow;

  /// Whether to scale on focus.
  final bool scaleOnFocus;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.features,
    this.hasError = false,
    this.isValid = false,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.obscureText = false,
    this.focusNode,
    this.shakeOnError = true,
    this.showFocusGlow = true,
    this.scaleOnFocus = true,
  });

  @override
  State<AnimatedTextField> createState() => AnimatedTextFieldState();
}

class AnimatedTextFieldState extends State<AnimatedTextField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _shakeController;
  late AnimationController _validController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _validAnimation;

  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _previousHasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Focus animation controller
    _focusController = AnimationController(
      vsync: this,
      duration: AnimationConstants.fieldFocusTransition,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConstants.fieldFocusScale,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AnimationConstants.smoothEntrance,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AnimationConstants.smoothEntrance,
    ));

    // Shake animation controller
    _shakeController = AnimationController(
      vsync: this,
      duration: AnimationConstants.fieldShakeDuration,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: AnimationConstants.bounceEntrance,
    ));

    // Valid checkmark animation controller
    _validController = AnimationController(
      vsync: this,
      duration: AnimationConstants.entranceFade,
    );

    _validAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _validController,
      curve: AnimationConstants.smoothEntrance,
    ));
  }

  @override
  void dispose() {
    _focusController.dispose();
    _shakeController.dispose();
    _validController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger shake animation when error state changes to true
    if (widget.hasError && !_previousHasError && widget.shakeOnError) {
      _triggerShake();
    }
    _previousHasError = widget.hasError;

    // Handle valid state changes
    if (widget.isValid && !oldWidget.isValid) {
      _validController.forward();
    } else if (!widget.isValid && oldWidget.isValid) {
      _validController.reverse();
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  /// Trigger the shake animation programmatically.
  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  /// Shake the field (can be called externally).
  void shake() {
    _triggerShake();
  }

  double _getShakeOffset() {
    if (!_shakeController.isAnimating) return 0.0;

    // Create a decaying sine wave for the shake effect
    final progress = _shakeAnimation.value;
    final decay = 1.0 - progress;
    final oscillation = math.sin(progress * math.pi * 6);
    return oscillation * AnimationConstants.fieldShakeOffset * decay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build features list with optional valid checkmark
    List<InputFeature> features = [...?widget.features];
    if (widget.isValid) {
      features.add(InputFeature.trailing(
        FadeTransition(
          opacity: _validAnimation,
          child: Icon(
            LucideIcons.check,
            color: Colors.green,
            size: 18,
          ),
        ),
      ));
    }

    Widget field = TextField(
      controller: widget.controller,
      placeholder: widget.placeholder,
      features: features.isEmpty ? [] : features,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
    );

    // Wrap with scale animation
    if (widget.scaleOnFocus) {
      field = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: field,
      );
    }

    // Wrap with glow effect
    if (widget.showFocusGlow) {
      field = AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: theme.borderRadiusMd,
              boxShadow: _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: colorScheme.primary
                            .withValues(alpha: 0.2 * _glowAnimation.value),
                        blurRadius: 8 * _glowAnimation.value,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: field,
      );
    }

    // Wrap with shake animation
    if (widget.shakeOnError) {
      field = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_getShakeOffset(), 0),
            child: child,
          );
        },
        child: field,
      );
    }

    return field;
  }
}

/// A simple shake wrapper for any widget.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = AnimationConstants.fieldShakeDuration,
    this.shakeOffset = AnimationConstants.fieldShakeOffset,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.bounceEntrance,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger the shake animation.
  void shake() {
    _controller.forward(from: 0.0);
  }

  double _getShakeOffset() {
    if (!_controller.isAnimating) return 0.0;
    final progress = _animation.value;
    final decay = 1.0 - progress;
    final oscillation = math.sin(progress * math.pi * 6);
    return oscillation * widget.shakeOffset * decay;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_getShakeOffset(), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
