import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/data/providers/incognito_provider.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/pages/expanded/spaces/home.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';
import 'package:flutter_client/widgets/backgrounds/dividers.dart';
import 'package:flutter_client/widgets/errors/route_guard.dart';

import '../../widgets/drawer/drawer.dart';
import '../chat/base.dart';
import '../chat/demo.dart';
import '../expanded/addons/home.dart';
import '../expanded/search/main.dart';
import '../support/support.dart';
import 'components/home_header.dart';

/// The home page of the application.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RootShell(key: ValueKey('main'));
  }
}

/// The root shell of the application.
///
/// This widget manages the main content and navigation of the home page.
class RootShell extends StatefulWidget {
  static final Map<Key, _RootShellState> _instances = {};

  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();

  /// Updates the current content and refreshes the UI.
  static void updateAndRefresh(
    Key key,
    Widget widget,
    String appBarTitle,
    IconData icon, {
    bool shouldShowBorder = false,
  }) {
    _validateInstance(key);
    _instances[key]!._setCurrentHome(widget, appBarTitle, icon, shouldShowBorder);
  }

  /// Updates only the app bar title and icon.
  static void updateAppbar(Key key, String appBarTitle, IconData icon) {
    _validateInstance(key);
    _instances[key]!._updateAppbar(appBarTitle, icon);
  }

  /// Sets a custom leading widget for the app bar.
  static void setCustomLeading(Key key, Widget? leading) {
    _validateInstance(key);
    _instances[key]!._setCustomLeading(leading);
  }

  /// Returns the BuildContext for a specific instance.
  static BuildContext context(Key key) {
    _validateInstance(key);
    return _instances[key]!.context;
  }

  static void _validateInstance(Key key) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RootShell found with key: $key');
    }
  }
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  Widget? _customLeading;
  String _appBarTitle = "New chat";
  IconData _icon = LucideIcons.messagesSquare;

  // Single orchestrating controller for silky coordinated animations
  late final AnimationController _transitionController;

  // Staggered animations - header leads, content follows
  late final Animation<double> _headerFadeAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<double> _contentSlideAnimation;
  late final Animation<double> _contentScaleAnimation;
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.008), end: Offset.zero,
  ).animate(_contentSlideAnimation);

  Widget _currentHome = ChatUI(
    key: UniqueKey(),
  );

  Widget _getPage(int index) {
    return switch (index) {
      0 => ChatUI(key: UniqueKey()),
      1 => ExpandedSearchView(mode: "Threads"),
      2 => ExpandedSearchView(mode: "Artifacts"),
      3 => AddonsHome(mode: "Marketplace"),
      4 => AddonsHome(mode: "Installed Addons"),
      5 => SpacesHome(),
      6 => SupportPage(),
      7 => ChatDemoPage(),
      _ => ChatUI(key: UniqueKey()),
    };
  }

  // PageController for sliding between menu and home
  static const int _homePageIndex = 1;
  late final PageController _pageController;
  double _slideProgress = 1.0; // 0.0 = menu visible, 1.0 = home visible

  @override
  void initState() {
    super.initState();
    if (widget.key != null) {
      RootShell._instances[widget.key!] = this;
    }
    // Start on home page
    _pageController = PageController(initialPage: _homePageIndex);

    // Single controller orchestrates all animations for silky coordination
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );

    // Header fades in first (0.0 - 0.6 of timeline)
    _headerFadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Content fades in with slight delay (0.1 - 1.0 of timeline)
    _contentFadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutQuart),
    );

    // Content slides up with silky deceleration
    _contentSlideAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    );

    // Content scales with satisfying settle (slight overshoot)
    _contentScaleAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.05, 0.9, curve: Curves.easeOutBack),
    );

    _transitionController.value = 1.0;
  }

  @override
  void dispose() {
    if (widget.key != null) {
      RootShell._instances.remove(widget.key);
    }
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _onPageChanged(double page) {
    setState(() {
      _slideProgress = page;
    });
  }

  void _slideToMenu() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _slideToHome() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _setCurrentHome(
    Widget newHome,
    String appBarTitle,
    IconData icon,
    bool showDivider,
  ) async {
    await postHogInstance.capture(eventName: 'user_navigated_to_$appBarTitle');
    if (!mounted) return;

    // Silky fade out with quicker reverse
    await _transitionController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;

    setState(() {
      _currentHome = newHome;
      _appBarTitle = appBarTitle;
      _icon = icon;
      _customLeading = null;
    });

    // Silky fade in - staggered animations handle the rest
    _transitionController.forward();
  }

  void _updateAppbar(String appBarTitle, IconData icon) async {
    await _transitionController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    setState(() {
      _appBarTitle = appBarTitle;
      _icon = icon;
    });
    _transitionController.forward();
  }

  void _setCustomLeading(Widget? leading) {
    setState(() {
      _customLeading = leading;
    });
  }

  void _onItemTapped(int index, String appBarTitle, IconData icon) async {
    // Quick, clean exit
    await _transitionController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInCubic,
    );

    if (!mounted) return;

    setState(() {
      _currentHome = _getPage(index);
      _appBarTitle = appBarTitle;
      _icon = icon;
      _customLeading = null;
    });

    // Silky entrance with staggered animations
    _transitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Toolkit.isMobile(context);

    return Scaffold(
      child: RouteGuard(
        child: isMobile
            ? _buildMobileSlidingLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  // ============== DESKTOP LAYOUT ==============

  Widget _buildDesktopLayout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: IncognitoModeProvider(),
      builder: (context, isIncognito, child) {
        return Stack(
          children: [
            // Main content
            Row(
              children: [
                // Sidebar with incognito glow
                AnimatedContainer(
                  duration: AnimationConstants.incognitoTransition,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    boxShadow: isIncognito
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(
                                alpha: AnimationConstants.incognitoGlowAlpha,
                              ),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(4, 0),
                            ),
                          ]
                        : [],
                  ),
                  child: SideBarDrawerDesktop(onItemTapped: _onItemTapped),
                ),
                DottedVerticalDivider(color: scheme.border),
                Expanded(
                  child: Column(
                    children: [
                      _buildAnimatedHeader(),
                      _appBarTitle != "New chat" && _appBarTitle != "New task" ? DottedDivider(color: scheme.border): SizedBox.shrink(),
                      Expanded(child: _buildAnimatedContent()),
                    ],
                  ),
                ),
              ],
            ),
            // Incognito vignette overlay
            if (isIncognito)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.5,
                              colors: [
                                Colors.transparent,
                                scheme.primary.withValues(
                                  alpha: AnimationConstants.incognitoTintAlpha,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Builds the header with smooth fade animation
  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: HomeHeader(title: _appBarTitle, icon: _icon),
    );
  }

  /// Builds the main content with silky smooth staggered animations
  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        // Very subtle scale with satisfying settle from easeOutBack
        final scaleValue = 0.992 + (0.008 * _contentScaleAnimation.value);

        return FadeTransition(
          opacity: _contentFadeAnimation,
          child: Transform.scale(
            scale: scaleValue,
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: _currentHome,
            ),
          ),
        );
      },
    );
  }

  // ============== MOBILE SLIDING LAYOUT ==============

  Widget _buildMobileSlidingLayout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final page = _pageController.page ?? 1.0;
          _onPageChanged(page);
        }
        return false;
      },
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.normal,
            ),
            onPageChanged: (index) {
              setState(() {
                _slideProgress = index.toDouble();
              });
            },
            children: [
              _buildMobileMenuPage(context),
              _buildMobileHomePage(context),
            ],
          ),
          // Silky smooth shadow overlay
          IgnorePointer(
            child: Opacity(
              opacity: (1 - _slideProgress).clamp(0.0, 0.15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      scheme.background.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuPage(BuildContext context) {
    // Silky scale - very subtle for natural feel
    final menuScale = 0.985 + (0.015 * (1 - _slideProgress)).clamp(0.0, 0.015);

    return Transform.scale(
      scale: menuScale,
      alignment: Alignment.centerRight,
      child: Container(
        color: Theme.of(context).colorScheme.sidebar,
        child: SafeArea(
          child: SideBarDrawerDesktop(
            onItemTapped: (index, title, icon) {
              _onItemTapped(index, title, icon);
              _slideToHome();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHomePage(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: IncognitoModeProvider(),
      builder: (context, isIncognito, child) {
        return AnimatedContainer(
          duration: AnimationConstants.incognitoTransition,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: scheme.background,
            boxShadow: isIncognito
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 40,
                      spreadRadius: -10,
                      offset: Offset.zero,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              _buildMobileHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildAnimatedContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: scheme.background,
        border: _appBarTitle == "New task" || _appBarTitle == "New chat" ? Border(
          bottom: BorderSide(color: scheme.border, width: 1),
        ) : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton.ghost(
              icon: AnimatedRotation(
                turns: _slideProgress == 0 ? 0.5 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    _slideProgress == 0
                        ? LucideIcons.panelLeftClose
                        : LucideIcons.panelLeftOpen,
                    key: ValueKey(_slideProgress == 0),
                    size: 20,
                  ),
                ),
              ),
              onPressed: () {
                if (_slideProgress > 0.5) {
                  _slideToMenu();
                } else {
                  _slideToHome();
                }
              },
            ),
            const Gap(8),
            FadeTransition(
              opacity: _headerFadeAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 18),
                  const Gap(8),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _headerFadeAnimation,
                child: Text(
                  _appBarTitle,
                  overflow: TextOverflow.ellipsis,
                ).base,
              ),
            ),
            if (_customLeading != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _customLeading,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideIndicator(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: _slideProgress < 0.5 ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _slideProgress < 0.5
                ? scheme.primary
                : scheme.muted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const Gap(6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: _slideProgress >= 0.5 ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _slideProgress >= 0.5
                ? scheme.primary
                : scheme.muted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
