part of 'drawer.dart';

/// Collapsed sidebar - just icons with smooth animations
class _CollapsedSidebar extends StatelessWidget {
  final VoidCallback onExpand;
  final Function onItemTapped;
  final VoidCallback onSearch;

  const _CollapsedSidebar({
    required this.onExpand,
    required this.onItemTapped,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          // Logo with playful breathing animation
          _AnimatedLogo(
            size: 38,
            primaryColor: Theme.of(context).colorScheme.primaryForeground,
          ),
          const Gap(20),
          _AnimatedNavIcon(
            icon: LucideIcons.plus,
            onPressed: () => onItemTapped(0, 'New task', LucideIcons.sparkles),
            delay: 0,
          ),
          const Gap(8),
          _AnimatedNavIcon(
            icon: LucideIcons.search,
            onPressed: onSearch,
            delay: 1,
          ),
          const Gap(8),
          _AnimatedNavIcon(
            icon: LucideIcons.library,
            onPressed: () => onItemTapped(1, 'Library', LucideIcons.library),
            delay: 2,
          ),
          const Spacer(),
          // Toggle button with hover animation
          _ToggleButton(
            icon: LucideIcons.panelLeftOpen,
            onPressed: onExpand,
          ),
        ],
      ),
    );
  }
}

/// Animated navigation icon with hover effect
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int delay;

  const _AnimatedNavIcon({
    required this.icon,
    required this.onPressed,
    this.delay = 0,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _isHovered ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.muted.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton.ghost(
            icon: Icon(widget.icon),
            onPressed: widget.onPressed,
          ),
        ),
      ),
    );
  }
}

/// Animated logo - ship's wheel with slow rotation that speeds up on hover
class _AnimatedLogo extends StatefulWidget {
  final double size;
  final Color primaryColor;

  const _AnimatedLogo({
    required this.size,
    required this.primaryColor,
  });

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (!mounted) return;
    setState(() => _isHovered = true);
    // Speed up rotation on hover - stop first to avoid glitches
    final currentValue = _rotationController.value;
    _rotationController.stop();
    _rotationController.duration = const Duration(seconds: 3);
    _rotationController.value = currentValue;
    _rotationController.repeat();
  }

  void _onHoverEnd() {
    if (!mounted) return;
    setState(() => _isHovered = false);
    // Return to slow rotation - stop first to avoid glitches
    final currentValue = _rotationController.value;
    _rotationController.stop();
    _rotationController.duration = const Duration(seconds: 20);
    _rotationController.value = currentValue;
    _rotationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Transform.rotate(
              angle: _rotationController.value * 2 * pi,
              child: CustomLogo(
                size: widget.size,
                primaryColor: widget.primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Toggle button with playful hover animation
class _ToggleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ToggleButton({
    required this.icon,
    required this.onPressed,
    this.size = 20,
  });

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _wiggleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (!mounted) return;
    setState(() => _isHovered = true);
    _wiggleController.forward(from: 0);
  }

  void _onHoverEnd() {
    if (!mounted) return;
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _isHovered
                  ? scheme.muted.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Transform.rotate(
              angle: _wiggleAnimation.value,
              child: AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: IconButton.ghost(
                  icon: Icon(widget.icon, size: widget.size),
                  onPressed: widget.onPressed,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
