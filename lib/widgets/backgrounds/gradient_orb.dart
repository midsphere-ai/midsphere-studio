import 'dart:math';
import 'dart:ui';

import 'package:arcane/arcane.dart';

/// A widget that displays floating gradient orbs with slow drifting movement.
///
/// Creates 2-3 semi-transparent gradient circles that drift slowly,
/// creating a dreamy atmosphere for the login page.
class FloatingGradientOrbs extends StatefulWidget {
  /// Number of orbs to display (2-4 recommended)
  final int orbCount;

  /// Base opacity for the orbs
  final double opacity;

  /// Blur amount for the glow effect
  final double blurAmount;

  /// Custom colors (uses theme colors if null)
  final List<Color>? colors;

  const FloatingGradientOrbs({
    super.key,
    this.orbCount = 3,
    this.opacity = 0.4,
    this.blurAmount = 60.0,
    this.colors,
  });

  @override
  State<FloatingGradientOrbs> createState() => _FloatingGradientOrbsState();
}

class _FloatingGradientOrbsState extends State<FloatingGradientOrbs>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<_OrbData> _orbData;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeOrbs();
  }

  void _initializeOrbs() {
    _controllers = [];
    _orbData = [];

    for (int i = 0; i < widget.orbCount; i++) {
      // Each orb has a different cycle duration for varied movement
      final duration = Duration(
        seconds: 25 + _random.nextInt(15), // 25-40 seconds
      );

      final controller = AnimationController(
        vsync: this,
        duration: duration,
      );

      // Start at random points in the animation cycle
      controller.value = _random.nextDouble();
      controller.repeat();

      _controllers.add(controller);

      // Generate random orb properties
      _orbData.add(_OrbData(
        startX: 0.1 + _random.nextDouble() * 0.8,
        startY: 0.1 + _random.nextDouble() * 0.8,
        radiusX: 0.1 + _random.nextDouble() * 0.2,
        radiusY: 0.1 + _random.nextDouble() * 0.2,
        size: 150 + _random.nextDouble() * 200,
        phaseOffset: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Color> _getColors(BuildContext context) {
    if (widget.colors != null) return widget.colors!;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.3),
      colorScheme.secondary.withValues(alpha: isDark ? 0.4 : 0.25),
      colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
      colorScheme.secondary.withValues(alpha: isDark ? 0.35 : 0.2),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(widget.orbCount, (index) {
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                final data = _orbData[index];
                final progress = _controllers[index].value;
                final angle = progress * 2 * pi + data.phaseOffset;

                // Calculate position using Lissajous-like curves for organic movement
                final x = constraints.maxWidth * data.startX +
                    cos(angle) * constraints.maxWidth * data.radiusX;
                final y = constraints.maxHeight * data.startY +
                    sin(angle * 1.3) * constraints.maxHeight * data.radiusY;

                return Positioned(
                  left: x - data.size / 2,
                  top: y - data.size / 2,
                  child: _GradientOrb(
                    size: data.size,
                    color: colors[index % colors.length],
                    opacity: widget.opacity,
                    blurAmount: widget.blurAmount,
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}

/// Data class for orb properties
class _OrbData {
  final double startX;
  final double startY;
  final double radiusX;
  final double radiusY;
  final double size;
  final double phaseOffset;

  _OrbData({
    required this.startX,
    required this.startY,
    required this.radiusX,
    required this.radiusY,
    required this.size,
    required this.phaseOffset,
  });
}

/// A single gradient orb with blur effect
class _GradientOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double blurAmount;

  const _GradientOrb({
    required this.size,
    required this.color,
    required this.opacity,
    required this.blurAmount,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
        tileMode: TileMode.decal,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// A single static orb for simpler use cases
class GradientOrb extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;
  final double blurAmount;
  final Alignment alignment;

  const GradientOrb({
    super.key,
    this.size = 200,
    this.color,
    this.opacity = 0.4,
    this.blurAmount = 60,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final orbColor = color ?? Theme.of(context).colorScheme.primary;

    return Align(
      alignment: alignment,
      child: _GradientOrb(
        size: size,
        color: orbColor,
        opacity: opacity,
        blurAmount: blurAmount,
      ),
    );
  }
}
