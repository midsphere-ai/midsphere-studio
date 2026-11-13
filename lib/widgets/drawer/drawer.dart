import 'dart:async';
import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart'
    show showDialog;
import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/domain/entities/memory/conversation/base.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'dart:math' show pi;
import 'package:dice_bear/dice_bear.dart';
import 'package:flutter_client/widgets/headers/logo.dart';
import '../../pages/home/home.dart';
import '../../pages/settings/settings.dart';
import '../../pages/home/sidebar/home/components/chat_history.dart';
import '../../pages/chat/base.dart';
import '../backgrounds/constrained_box.dart';

part 'drawer_collapsed.dart';
part 'drawer_expanded.dart';
part 'drawer_search_dialog.dart';

/// Sidebar drawer for desktop applications.
class SideBarDrawerDesktop extends StatefulWidget {
  final Function onItemTapped;

  const SideBarDrawerDesktop({super.key, required this.onItemTapped});

  @override
  State<SideBarDrawerDesktop> createState() => _SideBarDrawerDesktopState();
}

class _SideBarDrawerDesktopState extends State<SideBarDrawerDesktop>
    with TickerProviderStateMixin {
  bool _isExpanded = true;

  // Main expansion controller
  late final AnimationController _expansionController;
  late final Animation<double> _widthAnimation;

  // Content crossfade animations
  late final Animation<double> _expandedContentFade;
  late final Animation<double> _collapsedContentFade;
  late final Animation<double> _expandedContentSlide;
  late final Animation<double> _collapsedContentSlide;
  late final Animation<double> _expandedContentScale;

  @override
  void initState() {
    super.initState();

    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Width animation with custom easing for smooth feel
    _widthAnimation = Tween<double>(begin: 56, end: 260).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    // Expanded content fade - appears after width starts expanding
    _expandedContentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );

    // Collapsed content fade - fades quickly at start
    _collapsedContentFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Expanded content slide from left
    _expandedContentSlide = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Collapsed content slide to left
    _collapsedContentSlide = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Expanded content scale
    _expandedContentScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _expansionController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Start expanded
    _expansionController.value = 1.0;
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (Toolkit.isMobile(context)) {
      closeOverlay(context);
    } else {
      setState(() => _isExpanded = !_isExpanded);
      if (_isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    }
  }

  void _openSettings() {
    if (Toolkit.isMobile(context)) {
      RootShell.updateAndRefresh(
        ValueKey('main'),
        LimitedWindowBox(child: Settings(notAsSidebar: true)),
        'Settings',
        LucideIcons.cog,
      );
      closeOverlay(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          padding: EdgeInsets.zero,
          content: SizedBox(
            height: 500,
            width: 600,
            child: Settings(notAsSidebar: false),
          ),
        ),
      );
    }
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const _SearchTasksDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidebarColor = Theme.of(context).colorScheme.sidebar;

    return AnimatedBuilder(
      animation: _expansionController,
      builder: (context, _) {
        final progress = _expansionController.value;

        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: sidebarColor,
            // Subtle shadow when expanded
            boxShadow: progress > 0.5
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05 * progress),
                      blurRadius: 8 * progress,
                      offset: Offset(2 * progress, 0),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Stack(
              children: [
                // Collapsed content (icons only)
                if (progress < 1.0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(_collapsedContentSlide.value, 0),
                      child: Opacity(
                        opacity: _collapsedContentFade.value.clamp(0.0, 1.0),
                        child: _CollapsedSidebar(
                          onExpand: _toggleExpanded,
                          onItemTapped: widget.onItemTapped,
                          onSearch: _openSearchDialog,
                        ),
                      ),
                    ),
                  ),

                // Expanded content
                if (progress > 0.0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(_expandedContentSlide.value, 0),
                      child: Transform.scale(
                        scale: _expandedContentScale.value,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: _expandedContentFade.value.clamp(0.0, 1.0),
                          child: _ExpandedSidebar(
                            onCollapse: _toggleExpanded,
                            onItemTapped: widget.onItemTapped,
                            onSettings: _openSettings,
                            onSearch: _openSearchDialog,
                            animationProgress: progress,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
