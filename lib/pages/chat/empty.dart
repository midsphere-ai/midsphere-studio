import 'dart:math';
import 'dart:ui';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/pages/expanded/onboarding/main.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/widgets/headers/logo.dart';
import 'package:hive_ce/hive.dart';

import '../../logics/data/global_logics.dart';
import '../../logics/data/providers/incognito_provider.dart';
import '../../widgets/backgrounds/geometric.dart';
import '../../widgets/builders/mobile_builder.dart';
import '../../widgets/backgrounds/constrained_box.dart';
import 'input/quick_action.dart';
import 'input/agent_input.dart';

/// A widget that is displayed when there are no chats to display.
///
/// This widget displays a welcome message and a list of quick actions.
class EmptyChatUI extends StatefulWidget {
  /// Creates a new [EmptyChatUI] widget.
  final Function callback;
  const EmptyChatUI({super.key, required this.callback});

  @override
  State<EmptyChatUI> createState() => _EmptyChatUIState();
}

class _EmptyChatUIState extends State<EmptyChatUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String plan;
    if (AuthenticationProvider().activeSubscription != null) {
      plan = AuthenticationProvider().activeSubscription!.plan.name;
    } else {
      plan = "Midsphere Free";
    }

    return LimitedWindowBox(
      customWidth: 840,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            LimitedWindowBox(
              customWidth: DataConstants.pageWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showOnboarding)
                        Card(
                          leading: Icon(LucideIcons.triangleAlert),
                          child: Column(
                            spacing: 8,
                            children: [
                              Text(
                                "Your onboarding is not complete. Please complete it from settings.",
                              ).muted.small,
                            ],
                          ),
                        ),
                      MobileView(mobile: Spacer(), desktop: Spacer(flex: 1)),
                      _buildTitle(context),
                      MobileView(
                        mobile: Spacer(flex: 2),
                        desktop: SizedBox(height: 32),
                      ),
                      MobileView(
                        mobile: Column(
                          children: [
                            _buildQuickActions(),
                            SizedBox(height: 32),
                          ],
                        ),
                        desktop: Container(),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: AgentInputBar(
                          key: ValueKey('empty'),
                          placeHolder: 'Research, build or create anything with just a prompt...',
                          onClicked: widget.callback,
                        ),
                      ),
                      MobileView(
                        mobile: SizedBox.shrink(),
                        desktop: _buildQuickActions(),
                      ),
                      MobileView(desktop: Spacer(flex: 2), mobile: Container()),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the title widget.
  ///
  /// This widget displays a welcome message to the user.
  Widget _buildTitle(BuildContext context) {
    final userName =
        (AuthenticationProvider().loggedInUser?.name?.trim().isNotEmpty ??
            false)
        ? AuthenticationProvider().loggedInUser!.name!
        : "Default Account";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect behind
            MobileView(mobile: _buildAnimation(), desktop: SizedBox.shrink()),
            // Image on top
            MobileView(
              mobile: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.asset(
                  "assets/images/logo.png",
                  height: 128,
                  width: 128,
                  color: Theme.of(context).colorScheme.muted,
                ),
              ),
              desktop: ValueListenableBuilder<bool>(
                valueListenable: IncognitoModeProvider(),
                builder: (context, isIncognito, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ghost icon with animated appearance
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topLeft,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: isIncognito ? 1.0 : 0.0,
                            child: isIncognito
                                ? Align(
                                    alignment: Alignment.bottomLeft,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.elasticOut,
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        LucideIcons.ghost,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 64,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        // Title text with animated crossfade
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          alignment: isIncognito ? Alignment.centerLeft : Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              isIncognito ? "You are incognito" : "What can I do for you?",
                              key: ValueKey(isIncognito),
                            ).x5Large,
                          ),
                        ),
                        // Subtitle with animated appearance
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topLeft,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: isIncognito ? 1.0 : 0.0,
                            child: isIncognito
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      "Messages and sandbox in this conversation will not be saved and is lost forever after the session is closed.",
                                    ).muted,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 128,
          width: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withAlpha(
                  (_animation.value * 102).toInt(), // 0.4 * 255 = 102
                ),
                blurRadius: 20 + (_animation.value * 20),
                spreadRadius: 5 + (_animation.value * 5),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(
                  (_animation.value * 18).toInt(), // 0.2 * 255 = 51
                ),
                blurRadius: 40 + (_animation.value * 30),
                spreadRadius: 10 + (_animation.value * 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              QuickAction(
                label: "Automation",
                icon: LucideIcons.workflow,
                callBack: () {
                  AgentInputBar.updateText(
                    ValueKey('empty'),
                    'Sort my emails by priority and draft responses to urgent ones.',
                  );
                },
              ),
              QuickAction(
                label: "Research",
                icon: LucideIcons.search,
                callBack: () {
                  AgentInputBar.updateText(
                    ValueKey('empty'),
                    'Research the latest developments in AI and summarize key findings.',
                  );
                },
              ),
              QuickAction(
                label: "Computer use",
                icon: LucideIcons.computer,
                callBack: () {
                  AgentInputBar.updateText(
                    ValueKey('empty'),
                    'Open VS Code and create a new React project for me.',
                  );
                },
              ),
              QuickAction(
                label: "Chat",
                icon: LucideIcons.messageCircle,
                callBack: () {
                  AgentInputBar.updateText(
                    ValueKey('empty'),
                    'Help me brainstorm ideas for my next project.',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
