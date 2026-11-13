part of 'sidemenu.dart';

/// Animated empty state with gentle pulse effect
class _AnimatedEmptyState extends StatefulWidget {
  const _AnimatedEmptyState();

  @override
  State<_AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<_AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Text("Activity will be displayed here").muted.small,
    );
  }
}

/// Animated phase item with staggered entrance animation
class _AnimatedPhaseItem extends StatefulWidget {
  final int index;
  final String phaseName;
  final bool isCompleted;
  final bool isCurrent;
  final ColorScheme colors;

  const _AnimatedPhaseItem({
    super.key,
    required this.index,
    required this.phaseName,
    required this.isCompleted,
    required this.isCurrent,
    required this.colors,
  });

  @override
  State<_AnimatedPhaseItem> createState() => _AnimatedPhaseItemState();
}

class _AnimatedPhaseItemState extends State<_AnimatedPhaseItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<double>(begin: -15.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Staggered entrance based on index
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isCompleted || widget.isCurrent
                    ? LucideIcons.check
                    : LucideIcons.circle,
                size: 16,
                color: widget.isCompleted || widget.isCurrent
                    ? widget.colors.primary
                    : widget.colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isCurrent
                      ? widget.colors.foreground
                      : widget.colors.mutedForeground,
                  fontWeight: widget.isCurrent
                      ? FontWeight.w500
                      : FontWeight.normal,
                  fontSize: 12,
                ),
                child: Text(widget.phaseName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated navigation button with hover and press effects
class _AnimatedNavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _AnimatedNavigationButton({
    required this.icon,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<_AnimatedNavigationButton> createState() =>
      _AnimatedNavigationButtonState();
}

class _AnimatedNavigationButtonState extends State<_AnimatedNavigationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.isEnabled) {
            _controller.forward();
          }
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered && widget.isEnabled
                  ? colors.muted.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedScale(
              scale: _isHovered && widget.isEnabled ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.isEnabled
                    ? colors.foreground
                    : colors.mutedForeground.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated header button with hover effects
class _AnimatedHeaderButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedHeaderButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedHeaderButton> createState() => _AnimatedHeaderButtonState();
}

class _AnimatedHeaderButtonState extends State<_AnimatedHeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? colors.muted.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _isHovered ? 0.02 : 0,
            duration: const Duration(milliseconds: 150),
            child: IconButton.ghost(
              shape: ButtonShape.circle,
              icon: Icon(widget.icon, size: 16),
              onPressed: widget.onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
