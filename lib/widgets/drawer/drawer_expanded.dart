part of 'drawer.dart';

/// Expanded Sidebar with staggered animations
class _ExpandedSidebar extends StatefulWidget {
  final VoidCallback onCollapse;
  final Function onItemTapped;
  final VoidCallback onSettings;
  final VoidCallback onSearch;
  final double animationProgress;

  const _ExpandedSidebar({
    required this.onCollapse,
    required this.onItemTapped,
    required this.onSettings,
    required this.onSearch,
    this.animationProgress = 1.0,
  });

  @override
  State<_ExpandedSidebar> createState() => _ExpandedSidebarState();
}

class _ExpandedSidebarState extends State<_ExpandedSidebar>
    with TickerProviderStateMixin {
  String? _activeConversationId;
  int _selectedNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Stagger animation controller
  late final AnimationController _staggerController;
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Create staggered animations for each nav item
    for (int i = 0; i < 5; i++) {
      final start = (i * 0.1).clamp(0.0, 0.6);
      final end = (start + 0.4).clamp(0.0, 1.0);
      _itemAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    // Start stagger animation
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and app name
            _buildAnimatedItem(
              _buildHeader(context, scheme),
              _itemAnimations[0].value,
            ),
            const Gap(12),
            // New task button
            _buildAnimatedItem(
              _buildNavItem(context, LucideIcons.plus, 'New task', 0, () {
                widget.onItemTapped(0, 'New task', LucideIcons.sparkles);
                closeOverlay(context);
                setState(() {
                  _activeConversationId = null;
                  _selectedNavIndex = 0;
                });
              }),
              _itemAnimations[1].value,
            ),
            // Search nav item
            _buildAnimatedItem(
              _buildNavItem(
                  context, LucideIcons.search, 'Search', 1, widget.onSearch),
              _itemAnimations[2].value,
            ),
            // Library nav item
            _buildAnimatedItem(
              _buildNavItem(context, LucideIcons.library, 'Library', 2, () {
                widget.onItemTapped(1, 'Library', LucideIcons.library);
                closeOverlay(context);
                setState(() {
                  _activeConversationId = null;
                  _selectedNavIndex = 2;
                });
              }),
              _itemAnimations[3].value,
            ),

            const Gap(12),
            _buildAnimatedItem(
              _buildSectionHeader(
                context,
                scheme,
                'All tasks',
                LucideIcons.listFilter,
                () {},
              ),
              _itemAnimations[4].value,
            ),
            const Gap(8),

            // Task list (scrollable)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChatHistory(
                  key: const ValueKey('task_history'),
                  customController: _scrollController,
                  activeConversationId: _activeConversationId,
                  onHistorySelect: (id) {
                    setState(() {
                      _activeConversationId = id;
                      _selectedNavIndex = -1;
                    });
                  },
                ),
              ),
            ),

            // Bottom icons bar with slide up animation
            _buildAnimatedBottomBar(context, scheme),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedItem(Widget child, double progress) {
    return Transform.translate(
      offset: Offset(-15 * (1 - progress), 0),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          // Logo with playful animation
          _AnimatedLogo(
            size: 36,
            primaryColor: Theme.of(context).colorScheme.primaryForeground,
          ),
          const Gap(8),
          const Spacer(),
          // Toggle button with hover animation
          _ToggleButton(
            icon: LucideIcons.panelLeftClose,
            onPressed: widget.onCollapse,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    VoidCallback onTap,
  ) {
    final isSelected = _selectedNavIndex == index;

    return _AnimatedNavItem(
      icon: icon,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ColorScheme scheme,
    String title,
    IconData actionIcon,
    VoidCallback onAction,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title).muted.small,
        ],
      ),
    );
  }

  Widget _buildAnimatedBottomBar(BuildContext context, ColorScheme scheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.sidebarBorder, width: 1)),
        ),
        child: Row(
          children: [
            _AnimatedBottomIcon(
              icon: LucideIcons.layoutGrid,
              onPressed: () =>
                  widget.onItemTapped(3, 'Addons', LucideIcons.grid2x2Plus),
              delay: 0,
            ),
            _AnimatedBottomIcon(
              icon: LucideIcons.messageCircleQuestion,
              onPressed: () => widget.onItemTapped(
                6,
                'Support',
                LucideIcons.messageCircleQuestion,
              ),
              delay: 1,
            ),
            _AnimatedBottomIcon(
              icon: LucideIcons.palette,
              onPressed: () => widget.onItemTapped(
                7,
                'UI Gallery',
                LucideIcons.palette,
              ),
              delay: 2,
            ),
            const Spacer(),
            _AnimatedBottomIcon(
              icon: LucideIcons.settings2,
              onPressed: widget.onSettings,
              delay: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated navigation item with hover effects
class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: _isHovered
              ? scheme.muted.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: GhostButton(
            onPressed: widget.onTap,
            alignment: Alignment.centerLeft,
            child: Row(
              spacing: 8,
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(
                    _isHovered ? 2 : 0,
                    0,
                    0,
                  ),
                  child: Icon(widget.icon, size: 16),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontWeight:
                        _isHovered ? FontWeight.w500 : FontWeight.normal,
                    color: scheme.foreground,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated bottom icon with scale and hover effects
class _AnimatedBottomIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int delay;

  const _AnimatedBottomIcon({
    required this.icon,
    required this.onPressed,
    this.delay = 0,
  });

  @override
  State<_AnimatedBottomIcon> createState() => _AnimatedBottomIconState();
}

class _AnimatedBottomIconState extends State<_AnimatedBottomIcon> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + widget.delay * 80),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedScale(
          scale: _isHovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _isHovered ? 0.05 : 0,
            duration: const Duration(milliseconds: 150),
            child: IconButton.ghost(
              icon: Icon(widget.icon, size: 18),
              onPressed: widget.onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
