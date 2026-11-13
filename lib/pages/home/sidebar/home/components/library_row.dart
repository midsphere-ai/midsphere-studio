import 'package:arcane/arcane.dart';
import 'package:dice_bear/dice_bear.dart';
import 'package:flutter_client/pages/home/home.dart';

import '../../../../chat/base.dart';

/// Task item row with DiceBear avatar and animations.
class LibraryRow extends StatefulWidget {
  final String title;
  final bool selected;
  final String? conversationId;
  final Function? postHook;
  final ValueChanged<String?>? onSelect;
  final bool isBusy;
  final int animationIndex;
  final bool shouldAnimate;

  const LibraryRow({
    super.key,
    required this.title,
    this.selected = false,
    this.conversationId,
    this.postHook,
    this.onSelect,
    this.isBusy = false,
    this.animationIndex = 0,
    this.shouldAnimate = true,
  });

  @override
  State<LibraryRow> createState() => _LibraryRowState();
}

class _LibraryRowState extends State<LibraryRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.shouldAnimate) {
      // Staggered entrance based on index (max 10 items animated)
      final delay = (widget.animationIndex.clamp(0, 10)) * 50;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    RootShell.updateAndRefresh(
      ValueKey('main'),
      ChatUI(
        key: ValueKey(widget.conversationId),
        conversationId: widget.conversationId,
        isBusy: widget.isBusy,
      ),
      widget.title,
      LucideIcons.messageSquare,
      shouldShowBorder: true,
    );
    widget.postHook?.call();
    widget.onSelect?.call(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    // Generate DiceBear avatar
    final avatar = DiceBearBuilder(
      seed: widget.title,
      sprite: DiceBearSprite.icons,
      backgroundColor: Theme.of(context).colorScheme.sidebar,
      radius: 4,
    ).build();

    final buttonChild = Row(
      children: [
        // DiceBear avatar or loading spinner
        widget.isBusy
            ? const Center(child: CircularProgressIndicator(size: 16))
            : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: avatar.toImage(
                  width: 24,
                  height: 24,
                  color: Colors.amber,
                  colorBlendMode: BlendMode.dstOut,
                ),
              ).withOpacity(0.6),
        const Gap(8),
        // Task title
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Widget buttonWidget;
    if (widget.selected) {
      buttonWidget = SecondaryButton(
        onPressed: _onTap,
        density: ButtonDensity.compact,
        alignment: Alignment.centerLeft,
        child: buttonChild,
      );
    } else {
      buttonWidget = GhostButton(
        onPressed: _onTap,
        density: ButtonDensity.compact,
        alignment: Alignment.centerLeft,
        child: buttonChild,
      );
    }

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
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
            child: buttonWidget,
          ),
        ),
      ),
    );
  }
}
