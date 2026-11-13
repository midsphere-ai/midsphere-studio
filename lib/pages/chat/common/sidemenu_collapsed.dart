part of 'sidemenu.dart';

/// Collapsed SideMenu widget that shows a compact preview
/// with terminal thumbnail, objective, and phase counter
class CollapsedSideMenu extends StatefulWidget {
  final InMemoryChatController controller;
  final VoidCallback onExpand;
  final Widget Function()? contentBuilder;

  const CollapsedSideMenu({
    super.key,
    required this.controller,
    required this.onExpand,
    this.contentBuilder,
  });

  @override
  State<CollapsedSideMenu> createState() => _CollapsedSideMenuState();
}

class _CollapsedSideMenuState extends State<CollapsedSideMenu> {
  List messagesWithToolCalls = [];
  String? currentPlan;
  String? planObjective;
  List? completePlan;
  int currentPhaseIndex = 0;
  int totalPhases = 0;
  bool isExpanded = false;
  int _lastMessageCount = 0;
  bool _isThumbnailHovered = false;

  StreamSubscription? _operationsSubscription;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.controller.messages.length;
    _filterMessagesWithToolCalls();
    // Listen to controller operations for SSE updates
    _subscribeToController();
  }

  @override
  void didUpdateWidget(covariant CollapsedSideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller instance change
    if (widget.controller != oldWidget.controller) {
      _operationsSubscription?.cancel();
      _subscribeToController();
      _lastMessageCount = widget.controller.messages.length;
      _filterMessagesWithToolCalls();
    }
  }

  @override
  void dispose() {
    _operationsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToController() {
    _operationsSubscription = widget.controller.operationsStream.listen((_) {
      _onControllerChanged();
    });
  }

  /// Called when controller emits operations (e.g., message inserted via SSE)
  void _onControllerChanged() {
    if (!mounted) return;
    final currentCount = widget.controller.messages.length;
    if (currentCount != _lastMessageCount) {
      _lastMessageCount = currentCount;
      _filterMessagesWithToolCalls();
    }
  }

  void _filterMessagesWithToolCalls() {
    messagesWithToolCalls = widget.controller.messages.where((message) {
      final metadata = message.metadata;
      if (metadata == null) return false;

      // Legacy format
      final toolCallLegacy = metadata['origin_tool_call'];
      if (toolCallLegacy != null) {
        return !toolCallLegacy.toString().contains('mcp_message');
      }

      // Orbiter format: tool_result_output or tool_call with tool_name in msg_object
      final msgObject = metadata['msg_object'];
      if (msgObject != null && msgObject is Map &&
          (msgObject['messageType'] == 'tool_result_output' || msgObject['messageType'] == 'tool_call')) {
        final toolName = msgObject['kwargs']?['tool_name'] ?? metadata['tool_name'];
        return toolName != null && toolName != 'mcp_message';
      }

      return false;
    }).toList();

    // Extract plan information
    for (var message in messagesWithToolCalls) {
      String? functionName;
      Map<String, dynamic> arguments = {};

      final originToolCall = message.metadata?['origin_tool_call'];
      if (originToolCall != null) {
        // Legacy format
        final function = originToolCall['function'];
        if (function == null) continue;
        functionName = function['name'];
        try {
          final rawArgs = function['arguments'];
          if (rawArgs is String && rawArgs.isNotEmpty) {
            final decoded = jsonDecode(rawArgs);
            if (decoded is Map<String, dynamic>) {
              arguments = decoded;
            }
          }
        } catch (e) {
          debugPrint('[CollapsedSideMenu] _filterMessagesWithToolCalls: Failed to parse plan arguments: $e');
        }
      } else {
        // Orbiter format
        final msgObj = message.metadata?['msg_object'];
        functionName = msgObj?['kwargs']?['tool_name'] ?? message.metadata?['tool_name'];
        final rawArgs = msgObj?['kwargs']?['arguments'] ?? message.metadata?['arguments'];
        if (rawArgs is Map<String, dynamic>) {
          arguments = rawArgs;
        } else if (rawArgs is Map) {
          arguments = Map<String, dynamic>.from(rawArgs);
        }
      }

      if (functionName == 'mcp_update_plan') {
        currentPlan = arguments['current_phase_id']?.toString();
        final phases = arguments['phases'];
        completePlan = phases is List ? phases : null;

        if (completePlan != null) {
          totalPhases = completePlan!.length;
          // Find current phase index - only match if currentPlan is non-empty
          if (currentPlan != null && currentPlan!.isNotEmpty) {
            for (int i = 0; i < completePlan!.length; i++) {
              if (completePlan![i].toString().contains(currentPlan!)) {
                currentPhaseIndex = i + 1;
                final parts = completePlan![i].toString().split(":");
                planObjective = parts.isNotEmpty
                    ? (parts.length > 1 ? parts.last.trim() : parts.first.trim())
                    : completePlan![i].toString();
                break;
              }
            }
          }
        }
      }
    }

    if (mounted) setState(() {});
  }

  String _getCurrentObjective() {
    if (planObjective != null && planObjective!.isNotEmpty) {
      return planObjective!;
    }
    if (currentPlan != null) {
      return currentPlan!;
    }
    return "No objectives defined yet.";
  }

  Widget _buildTaskProgress() {
    final colors = Theme.of(context).colorScheme;

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Task progress").bold.small,
        Text(
          '$currentPhaseIndex / $totalPhases',
          style: TextStyle(color: colors.mutedForeground, fontSize: 12),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: 12),
          // Phase list with staggered animations
          if (completePlan != null && completePlan!.isNotEmpty)
            ...completePlan!.asMap().entries.map((entry) {
              final index = entry.key;
              final phase = entry.value.toString();
              final parts = phase.split(":");
              final phaseName = parts.isNotEmpty ? parts.last.trim() : phase;
              final isCompleted = index < currentPhaseIndex;
              final isCurrent = index == currentPhaseIndex - 1;

              return _AnimatedPhaseItem(
                key: ValueKey('collapsed_phase_$index'),
                index: index,
                phaseName: phaseName,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                colors: colors,
              );
            }),
          if (completePlan == null || completePlan!.isEmpty)
            Text("No phases available").muted.small,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Use AnimatedSize with custom switcher for playful transitions
    return AnimatedSize(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isExpandedChild = child.key == const ValueKey('expanded');

          // Different animations for expand vs collapse
          if (isExpandedChild) {
            // Expanding: scale up from bottom with bounce
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
            );
          } else {
            // Collapsing: smooth settle with slight bounce
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  )),
                  child: child,
                ),
              ),
            );
          }
        },
        child: isExpanded
            ? KeyedSubtree(
                key: const ValueKey('expanded'),
                child: _buildExpandedView(colors),
              )
            : KeyedSubtree(
                key: const ValueKey('collapsed'),
                child: _buildCollapsedView(colors),
              ),
      ),
    );
  }

  Widget _buildCollapsedView(ColorScheme colors) {
    final card = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(LucideIcons.check, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getCurrentObjective(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).small,
            ),
          ],
        ),
      ),
    );

    final chevron = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalPhases > 0) ...[
            Text(
              '$currentPhaseIndex / $totalPhases',
              style: TextStyle(color: colors.mutedForeground, fontSize: 12),
            ),
            const SizedBox(width: 6),
          ],
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = true;
              });
            },
            child: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(
                LucideIcons.chevronUp,
                size: 16,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );

    final thumbnail = Positioned(
      left: 20,
      top: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isThumbnailHovered = true),
        onExit: (_) => setState(() => _isThumbnailHovered = false),
        child: GestureDetector(
          onTap: widget.onExpand,
          child: AnimatedScale(
            scale: _isThumbnailHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: Theme.of(context).borderRadiusMd,
                border: Border.all(
                  color: _isThumbnailHovered ? colors.primary : colors.border,
                  width: _isThumbnailHovered ? 2.5 : 2,
                ),
                boxShadow: _isThumbnailHovered
                    ? [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Scaled content preview using FittedBox
                  if (widget.contentBuilder != null)
                    SizedBox(
                      width: 140,
                      height: 70,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: 400,
                          height: 300,
                          child: IgnorePointer(child: widget.contentBuilder!()),
                        ),
                      ),
                    ),
                  // "main" label at top left
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(40),
                        borderRadius: Theme.of(context).borderRadiusMd,
                      ),
                      child: Text(
                        'main',
                        style: TextStyle(fontSize: 6, color: colors.primary),
                      ),
                    ),
                  ),
                  // Maximize icon at top right on hover
                  Positioned(
                    top: 4,
                    right: 4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isThumbnailHovered ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        offset: _isThumbnailHovered ? Offset.zero : const Offset(0.3, -0.3),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: Theme.of(context).borderRadiusSm,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.maximize2,
                            size: 12,
                            color: colors.primaryForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Card(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Spacer for thumbnail overlap area
                    const SizedBox(width: 160),
                    card,
                    chevron,
                  ],
                ),
              ),
            ),
          ),
          thumbnail,
        ],
      ),
    );
  }

  Widget _buildExpandedView(ColorScheme colors) {
    return Card(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with thumbnail, title, and action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Content thumbnail preview
              GestureDetector(
                onTap: widget.onExpand,
                child: Container(
                  width: 120,
                  height: 90,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: Theme.of(context).borderRadiusMd,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Scaled content preview using FittedBox
                      if (widget.contentBuilder != null)
                        SizedBox(
                          width: 120,
                          height: 90,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.topLeft,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: 400,
                              height: 300,
                              child: IgnorePointer(
                                child: widget.contentBuilder!(),
                              ),
                            ),
                          ),
                        ),
                      // "main" label at top right
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(40),
                            borderRadius: Theme.of(context).borderRadiusMd,
                          ),
                          child: Text(
                            'main',
                            style: TextStyle(
                              fontSize: 6,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center: Title and tool info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sukuna's computer").bold,
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.terminal, size: 14),
                          const SizedBox(width: 6),
                          Text("Sukuna is using ").muted.xSmall,
                          Text("Terminal").bold.xSmall,
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Action buttons
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.ghost(
                      icon: Icon(LucideIcons.maximize2, size: 16),
                      onPressed: widget.onExpand,
                    ),
                    IconButton.ghost(
                      icon: Icon(LucideIcons.chevronDown, size: 16),
                      onPressed: () {
                        setState(() {
                          isExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(),
          _buildTaskProgress(),
        ],
      ),
    );
  }
}
