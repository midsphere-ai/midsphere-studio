part of 'home_header.dart';

class _HeaderActions extends StatefulWidget {
  const _HeaderActions();

  @override
  State<_HeaderActions> createState() => _HeaderActionsState();
}

class _HeaderActionsState extends State<_HeaderActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _openNotifications(BuildContext context) {
    RootShell.updateAndRefresh(
      const ValueKey('main'),
      const NotificationsPage(),
      "What's New",
      LucideIcons.bell,
    );
  }

  Widget _buildStaggeredItem({
    required Widget child,
    required int index,
  }) {
    final start = index * 0.15;
    final end = start + 0.4;

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final curvedValue = Curves.easeOutBack.transform(
          (((_staggerController.value - start) / (end - start))
              .clamp(0.0, 1.0)),
        );
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: curvedValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStaggeredItem(
          index: 0,
          child: _RingingBellButton(
            onPressed: () => _openNotifications(context),
          ),
        ),
        const SizedBox(width: 4),
        _buildStaggeredItem(
          index: 1,
          child: const _IncognitoButton(),
        ),
        const SizedBox(width: 4),
        _buildStaggeredItem(
          index: 2,
          child: const _AnimatedTasksBadge(),
        ),
        const SizedBox(width: 8),
        _buildStaggeredItem(
          index: 3,
          child: _BouncyAvatar(
            initials: Avatar.getInitials(
              AuthenticationProvider().loggedInUser?.name ?? 'U',
            ),
          ),
        ),
      ],
    );
  }
}

/// Bell icon that rings/swings when hovered
class _RingingBellButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RingingBellButton({required this.onPressed});

  @override
  State<_RingingBellButton> createState() => _RingingBellButtonState();
}

class _RingingBellButtonState extends State<_RingingBellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _startRinging() {
    _ringController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
          _startRinging();
        }
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: () {
          _startRinging();
          widget.onPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.muted.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              // Bell swings back and forth with decreasing amplitude
              final swingValue = math.sin(_ringController.value * math.pi * 4) *
                  (1 - _ringController.value) *
                  0.3;
              return Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()..rotateZ(swingValue),
                child: child,
              );
            },
            child: const Icon(LucideIcons.bell, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Avatar that does a playful dance with waving hand on hover
class _BouncyAvatar extends StatefulWidget {
  final String initials;

  const _BouncyAvatar({required this.initials});

  @override
  State<_BouncyAvatar> createState() => _BouncyAvatarState();
}

class _BouncyAvatarState extends State<_BouncyAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _danceController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _danceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Start wave when dance reaches 20%
    _danceController.addListener(_onDanceProgress);
  }

  void _onDanceProgress() {
    if (_danceController.value >= 0.2 &&
        _danceController.value < 0.25 &&
        !_waveController.isAnimating &&
        _waveController.status != AnimationStatus.completed) {
      _waveController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _danceController.removeListener(_onDanceProgress);
    _danceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    _danceController.forward(from: 0);
    _waveController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) {},
      child: AnimatedBuilder(
        animation: Listenable.merge([_danceController, _waveController]),
        builder: (context, child) {
          final progress = _danceController.value;

          // Dance animation phases
          double offsetY = 0;
          double offsetX = 0;
          double rotation = 0;

          if (progress < 0.2) {
            // Anticipation - slight crouch
            final t = progress / 0.2;
            offsetY = 2 * Curves.easeOut.transform(t);
          } else if (progress < 0.4) {
            // Jump up and tilt right
            final t = (progress - 0.2) / 0.2;
            offsetY = 2 - (8 * Curves.easeOut.transform(t));
            rotation = 0.12 * Curves.easeOut.transform(t);
            offsetX = 3 * Curves.easeOut.transform(t);
          } else if (progress < 0.55) {
            // Land from right
            final t = (progress - 0.4) / 0.15;
            offsetY = -6 + (6 * Curves.easeIn.transform(t));
            rotation = 0.12 * (1 - t);
            offsetX = 3 * (1 - t);
          } else if (progress < 0.7) {
            // Jump and tilt left
            final t = (progress - 0.55) / 0.15;
            offsetY = -5 * Curves.easeOut.transform(t);
            rotation = -0.1 * Curves.easeOut.transform(t);
            offsetX = -2 * Curves.easeOut.transform(t);
          } else if (progress < 0.85) {
            // Land from left
            final t = (progress - 0.7) / 0.15;
            offsetY = -5 * (1 - Curves.easeIn.transform(t));
            rotation = -0.1 * (1 - t);
            offsetX = -2 * (1 - t);
          } else {
            // Settle wiggle
            final t = (progress - 0.85) / 0.15;
            rotation = math.sin(t * math.pi * 2) * 0.05 * (1 - t);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.rotate(
                  angle: rotation,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
              // Waving hand
              Positioned(
                right: -6,
                top: -2,
                child: _buildWavingHand(),
              ),
            ],
          );
        },
        child: Avatar(
          initials: widget.initials,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildWavingHand() {
    final progress = _waveController.value;
    if (progress == 0) return const SizedBox.shrink();

    double scale = 0;
    double rotation = 0;
    double opacity = 0;

    if (progress < 0.15) {
      // Pop in
      final t = progress / 0.15;
      scale = Curves.easeOutBack.transform(t);
      opacity = t;
    } else if (progress < 0.8) {
      // Wave
      final t = (progress - 0.15) / 0.65;
      scale = 1.0;
      opacity = 1.0;
      rotation = math.sin(t * math.pi * 3) * 0.35 * (1 - t * 0.4);
    } else {
      // Pop out
      final t = (progress - 0.8) / 0.2;
      scale = 1.0 - t;
      opacity = 1.0 - t;
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale.clamp(0.0, 1.5),
        child: Transform.rotate(
          angle: rotation,
          alignment: Alignment.bottomCenter,
          child: const Text('👋', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

/// Plan badge with subtle hover effect
class _AnimatedPlanBadge extends StatefulWidget {
  const _AnimatedPlanBadge({super.key});

  @override
  State<_AnimatedPlanBadge> createState() => _AnimatedPlanBadgeState();
}

class _AnimatedPlanBadgeState extends State<_AnimatedPlanBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { if (!_isHovered) setState(() => _isHovered = true); },
      onExit: (_) { if (_isHovered) setState(() => _isHovered = false); },
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: const PlanBadge(),
      ),
    );
  }
}

/// Tasks badge with electric zap pulse animation
class _AnimatedTasksBadge extends StatefulWidget {
  const _AnimatedTasksBadge();

  @override
  State<_AnimatedTasksBadge> createState() => _AnimatedTasksBadgeState();
}

class _AnimatedTasksBadgeState extends State<_AnimatedTasksBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _zapController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Subtle continuous pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Electric zap effect on hover
    _zapController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    _zapController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _zapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) { if (!_isHovered) _onHoverStart(); },
      onExit: (_) { if (_isHovered) setState(() => _isHovered = false); },
      child: GestureDetector(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _zapController]),
          builder: (context, child) {
            // Subtle breathing glow
            final pulseValue = _pulseController.value;
            final glowIntensity = 0.3 + (0.2 * math.sin(pulseValue * math.pi));

            // Electric zap animation
            final zapProgress = _zapController.value;
            double offsetX = 0;
            double scale = 1.0;

            if (zapProgress > 0 && zapProgress < 1) {
              // Quick jittery zap movement
              if (zapProgress < 0.15) {
                offsetX = 2 * math.sin(zapProgress * math.pi * 20);
              } else if (zapProgress < 0.3) {
                offsetX = 1.5 * math.sin(zapProgress * math.pi * 16);
              } else if (zapProgress < 0.5) {
                offsetX = 1 * math.sin(zapProgress * math.pi * 12);
                scale = 1.0 + (0.1 * Curves.easeOut.transform((zapProgress - 0.3) / 0.2));
              } else {
                // Settle with bounce
                final t = (zapProgress - 0.5) / 0.5;
                scale = 1.1 - (0.1 * Curves.easeOutBack.transform(t));
                offsetX = 0.5 * math.sin(t * math.pi * 4) * (1 - t);
              }
            }

            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: glowIntensity),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: const TasksBadge(),
        ),
      ),
    );
  }
}

/// Ghost icon that floats when active and does a playful wiggle/wink on toggle
class _IncognitoButton extends StatefulWidget {
  const _IncognitoButton();

  @override
  State<_IncognitoButton> createState() => _IncognitoButtonState();
}

class _IncognitoButtonState extends State<_IncognitoButton>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _winkController;
  bool _isHovered = false;
  bool _wasIncognito = false;

  @override
  void initState() {
    super.initState();
    // Continuous floating animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Wink/wiggle animation on toggle
    _winkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _wasIncognito = IncognitoModeProvider().value;
    IncognitoModeProvider().addListener(_onIncognitoChanged);
  }

  void _onIncognitoChanged() {
    if (!mounted) return;
    final isIncognito = IncognitoModeProvider().value;
    if (isIncognito != _wasIncognito) {
      _wasIncognito = isIncognito;
      // Only trigger if not already animating (prevents double-trigger from tap)
      if (!_winkController.isAnimating) {
        _winkController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    IncognitoModeProvider().removeListener(_onIncognitoChanged);
    _floatController.stop();
    _floatController.dispose();
    _winkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _winkController.forward(from: 0);
    IncognitoModeProvider().toggle();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: IncognitoModeProvider(),
      builder: (context, isIncognito, _) {
        return MouseRegion(
          onEnter: (_) { if (!_isHovered) setState(() => _isHovered = true); },
          onExit: (_) { if (_isHovered) setState(() => _isHovered = false); },
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIncognito
                    ? scheme.primary.withValues(alpha: 0.15)
                    : _isHovered
                        ? scheme.muted.withValues(alpha: 0.5)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([_floatController, _winkController]),
                builder: (context, child) {
                  // Floating bob when incognito is active
                  final floatOffset = isIncognito
                      ? math.sin(_floatController.value * math.pi) * 2
                      : 0.0;

                  // Wink animation: squash horizontally then bounce back
                  final winkProgress = _winkController.value;
                  double scaleX = 1.0;
                  double scaleY = 1.0;
                  double rotation = 0.0;

                  if (winkProgress < 0.3) {
                    // Squash phase - "wink"
                    final t = winkProgress / 0.3;
                    scaleX = 1.0 - (0.4 * Curves.easeOut.transform(t));
                    scaleY = 1.0 + (0.1 * Curves.easeOut.transform(t));
                  } else if (winkProgress < 0.6) {
                    // Bounce back with overshoot
                    final t = (winkProgress - 0.3) / 0.3;
                    scaleX = 0.6 + (0.5 * Curves.easeOutBack.transform(t));
                    scaleY = 1.1 - (0.15 * Curves.easeOutBack.transform(t));
                    rotation = math.sin(t * math.pi) * 0.1;
                  } else {
                    // Settle with a little wiggle
                    final t = (winkProgress - 0.6) / 0.4;
                    scaleX = 1.1 - (0.1 * Curves.easeInOut.transform(t));
                    scaleY = 0.95 + (0.05 * Curves.easeInOut.transform(t));
                    rotation = math.sin(t * math.pi * 2) * 0.05 * (1 - t);
                  }

                  final hoverScale = _isHovered ? 1.1 : 1.0;
                  return Transform.translate(
                    offset: Offset(0, -floatOffset),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(
                          scaleX * hoverScale,
                          scaleY * hoverScale,
                          1.0,
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Icon(
                  LucideIcons.ghost,
                  size: 18,
                  color: isIncognito ? scheme.primary : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
