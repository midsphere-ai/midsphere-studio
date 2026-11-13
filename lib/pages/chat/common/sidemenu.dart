import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/popover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show InkWell;
import 'package:flutter_chat_core/flutter_chat_core.dart';

import 'package:flutter_client/pages/chat/common/terminal.dart';
import 'package:flutter_client/widgets/texts/json_pretty.dart';
import 'package:image_network/image_network.dart';

import 'file_directory.dart';
import 'body_widgets/body_widgets.dart';

part 'sidemenu_tool_map.dart';
part 'sidemenu_animations.dart';
part 'sidemenu_collapsed.dart';

class CategoryResult {
  final String text;
  final IconData icon;

  CategoryResult(this.text, this.icon);
}

class SideMenu extends StatefulWidget {
  final VoidCallback collapseFunction;
  final InMemoryChatController controller;
  final String? workspacePath;
  const SideMenu({
    super.key,
    required this.controller,
    required this.collapseFunction,
    this.workspacePath,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int activeIndex = 0;
  List messagesWithToolCalls = [];
  Map<String, dynamic>? toolCall;
  String? currentPlan;
  String? planObjective;
  List? completePlan;
  bool isWorkspaceSelected = false;
  int _lastMessageCount = 0;
  bool isExpanded = false;

  int currentPhaseIndex = 0;
  int totalPhases = 0;

  StreamSubscription? _operationsSubscription;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.controller.messages.length;
    _filterMessagesWithToolCalls();
    _setActiveMessage(null);
    // Listen to controller operations for SSE updates
    _subscribeToController();
  }

  @override
  void didUpdateWidget(covariant SideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller instance change
    if (widget.controller != oldWidget.controller) {
      _operationsSubscription?.cancel();
      _subscribeToController();
      _lastMessageCount = widget.controller.messages.length;
      _filterMessagesWithToolCalls();
      _setActiveMessage(null);
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
      _setActiveMessage(null);
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

    // Extract plan information and update phase tracking
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
          debugPrint('[SideMenu] _filterMessagesWithToolCalls: Failed to parse plan arguments: $e');
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
  }

  void _setActiveMessage(int? index) {
    if (messagesWithToolCalls.isEmpty) {
      if (mounted) {
        setState(() {
          toolCall = null;
          activeIndex = 0;
        });
      }
      return;
    }

    final newIndex = index ?? messagesWithToolCalls.length - 1;

    if (newIndex >= 0 && newIndex < messagesWithToolCalls.length) {
      final message = messagesWithToolCalls[newIndex];
      // Legacy or Orbiter: try origin_tool_call first, then synthesize from msg_object
      final newToolCall = message.metadata?['origin_tool_call'] ?? _synthesizeToolCall(message.metadata);
      if (mounted) {
        setState(() {
          activeIndex = newIndex;
          toolCall = newToolCall is Map<String, dynamic> ? newToolCall : null;
        });
      }
    }
  }

  /// Synthesize a legacy-compatible toolCall map from Orbiter msg_object metadata.
  Map<String, dynamic>? _synthesizeToolCall(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final msgObj = metadata['msg_object'];
    if (msgObj == null || msgObj is! Map) return null;
    final kwargs = msgObj['kwargs'];
    if (kwargs == null) return null;

    final toolName = kwargs['tool_name'] ?? metadata['tool_name'];
    if (toolName == null) return null;

    // Arguments may already be a Map
    final rawArgs = kwargs['arguments'] ?? metadata['arguments'];
    String argsString = '{}';
    if (rawArgs is Map) {
      argsString = jsonEncode(rawArgs);
    } else if (rawArgs is String) {
      argsString = rawArgs;
    }

    return {
      'function': {
        'name': toolName.toString(),
        'arguments': argsString,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 8),
        ..._buildProcessHeader(),
        SizedBox(height: 4),
        if (isWorkspaceSelected) ...[
          Expanded(
            child: FileExplorerWithViewer(
              path: widget.workspacePath ?? Platform.environment['HOME'] ?? '/',
            ),
          ),
        ],

        if (!isWorkspaceSelected) ...[
          _body(),
          navigationAndSlider(),
          _objectiveAndPlan(),
        ],
      ],
    );
  }

  Widget _objectiveAndPlan() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        borderRadius: Theme.of(context).borderRadiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: !isExpanded
              ? _buildCollapsedView(Theme.of(context).colorScheme)
              : _buildTaskProgress(),
        ),
      ),
    );
  }

  Widget _body() {
    final hasContent = widget.controller.messages.length > 1 &&
        toolCall != null &&
        messagesWithToolCalls.isNotEmpty;

    return Expanded(
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: hasContent
              ? Padding(
                  key: const ValueKey('tool_details'),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _buildToolCallDetails(),
                )
              : _buildEmptyState(),
        ),
      ),
    );
  }

  Widget navigationAndSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _AnimatedNavigationButton(
            icon: LucideIcons.stepBack,
            onPressed: activeIndex > 0
                ? () => _setActiveMessage(activeIndex - 1)
                : null,
            isEnabled: activeIndex > 0,
          ),
          const SizedBox(width: 4),
          _AnimatedNavigationButton(
            icon: LucideIcons.stepForward,
            onPressed: activeIndex < messagesWithToolCalls.length - 1
                ? () => _setActiveMessage(activeIndex + 1)
                : null,
            isEnabled: activeIndex < messagesWithToolCalls.length - 1,
          ),
          slider(),
        ],
      ),
    );
  }

  Widget slider() {
    final itemCount = messagesWithToolCalls.length;
    final maxValue = itemCount > 1 ? (itemCount - 1).toDouble() : 0.0;
    final divisions = itemCount > 1 ? itemCount - 1 : 1;
    SliderValue value = SliderValue.single(activeIndex.toDouble().clamp(0, maxValue));

    return Flexible(
      child: Slider(
        max: maxValue > 0 ? maxValue : 1.0,
        divisions: divisions,
        value: value,
        onChanged: itemCount > 1
            ? (value) {
                final newIndex = value.value.toInt();
                if (newIndex != activeIndex) {
                  _setActiveMessage(newIndex);
                }
              }
            : null,
      ),
    );
  }

  String getCurrentPlan() {
    if (currentPlan == null || currentPlan!.isEmpty) {
      return "No plan has been made yet.";
    }
    if (completePlan != null) {
      for (var i in completePlan!) {
        if (i.toString().contains(currentPlan!)) {
          final parts = i.toString().split(":");
          if (parts.isNotEmpty) {
            return parts.last.trim();
          }
          return i.toString();
        }
      }
    }

    return currentPlan!.toString();
  }

  Widget _buildToolCallDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header - simple fade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey('header_$activeIndex'),
            child: _buildToolHeader(),
          ),
        ),
        const SizedBox(height: 12),
        // Content - wrapped in Expanded to fill remaining space
        Expanded(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              layoutBuilder: (currentChild, previousChildren) {
                // Use StackFit.expand so content fills the available space
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: KeyedSubtree(
                key: ValueKey('content_$activeIndex'),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty_state'),
      child: _AnimatedEmptyState(),
    );
  }

  List<Widget> _buildProcessHeader() {
    Widget processTitle = Row(
      spacing: 8,
      children: [Text("Agent computer")],
    );

    Widget processCollapse = Row(
      children: [
        _AnimatedHeaderButton(
          icon: LucideIcons.monitor,
          onPressed: widget.collapseFunction,
        ),
        _AnimatedHeaderButton(
          icon: LucideIcons.minimize2,
          onPressed: widget.collapseFunction,
        ),
      ],
    );
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Row(
          spacing: 6,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [processTitle, processCollapse],
        ),
      ),
    ];
  }

  Widget _buildCollapsedView(ColorScheme colors) {
    Widget currentObjective = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(LucideIcons.check, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                getCurrentPlan(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).small,
            ),
          ],
        ),
      ),
    );

    Widget chevron = Container(
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

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [currentObjective, chevron],
    );
  }

  Widget _buildTaskProgress() {
    final colors = Theme.of(context).colorScheme;

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Task progress").bold,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$currentPhaseIndex / $totalPhases',
              style: TextStyle(color: colors.mutedForeground, fontSize: 12),
            ),
            IconButton.ghost(
              icon: AnimatedRotation(
                turns: isExpanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Icon(LucideIcons.chevronDown),
              ),
              onPressed: () {
                setState(() {
                  isExpanded = false;
                });
              },
            ),
          ],
        ),
      ],
    );

    return Padding(
      key: const ValueKey('expanded'),
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
                key: ValueKey('phase_$index'),
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

  CategoryResult getCategoryWiseString(String? category) {
    if (category == null || category.isEmpty) {
      return CategoryResult(
        "Sukuna is working with connectors",
        LucideIcons.messageCircleQuestion,
      );
    }
    if (category == 'plan') {
      return CategoryResult(
        "Sukuna is using Planner",
        LucideIcons.clipboardList,
      );
    } else if (category == 'read') {
      return CategoryResult("Sukuna is using Editor", LucideIcons.bookOpen);
    } else if (category == 'file') {
      return CategoryResult("Sukuna is using Editor", LucideIcons.filePen);
    } else if (category == "reasoning") {
      return CategoryResult("Sukuna is reasoning", LucideIcons.brain);
    } else if (category == 'vision') {
      return CategoryResult("Sukuna is using Media viewer", LucideIcons.eye);
    } else if (category == 'download') {
      return CategoryResult("Sukuna is using Browser", LucideIcons.download);
    } else if (category == 'search') {
      return CategoryResult("Sukuna is using Browser", LucideIcons.search);
    } else if (category == 'web') {
      return CategoryResult("Sukuna is using Code editor", LucideIcons.code);
    } else if (category == 'slides') {
      return CategoryResult(
        "Sukuna is using Designer",
        LucideIcons.presentation,
      );
    } else if (category == 'audio') {
      return CategoryResult(
        "Sukuna is using Media viewer",
        LucideIcons.headphones,
      );
    } else if (category == 'code') {
      return CategoryResult("Sukuna is using Terminal", LucideIcons.terminal);
    }
    return CategoryResult(
      "Sukuna is working with connectors",
      LucideIcons.messageCircleQuestion,
    );
  }

  /// Interpolates message template with arguments
  /// e.g. "Reading {file_path}" with {file_path: "test.dart"} -> "Reading test.dart"
  String _interpolateMessage(String template, Map<String, dynamic> arguments) {
    String result = template;
    // Match {variable} or {variable.property} patterns
    final regex = RegExp(r'\{([^}]+)\}');

    for (final match in regex.allMatches(template)) {
      final key = match.group(1)!;

      // Handle dot notation like {image_paths.length}
      if (key.contains('.')) {
        final parts = key.split('.');
        final varName = parts[0];
        final property = parts[1];

        if (arguments.containsKey(varName)) {
          final value = arguments[varName];
          if (property == 'length' && value is List) {
            result = result.replaceAll('{$key}', value.length.toString());
          }
        }
      } else if (arguments.containsKey(key)) {
        final value = arguments[key];
        result = result.replaceAll('{$key}', value?.toString() ?? '');
      }
    }

    return result;
  }

  Widget _buildToolHeader() {
    if (toolCall == null) return const SizedBox.shrink();

    final function = toolCall!['function'];
    if (function == null) return const SizedBox.shrink();

    // Bounds check for activeIndex
    if (activeIndex < 0 || activeIndex >= messagesWithToolCalls.length) {
      return const SizedBox.shrink();
    }

    final functionCategory =
        messagesWithToolCalls[activeIndex].metadata?['tool_name'] as String? ?? 'unknown';
    final functionName = function['name'] as String? ?? 'Unknown Tool';

    // Safe JSON parsing with type checking
    Map<String, dynamic> arguments = {};
    try {
      final rawArgs = function['arguments'] as String? ?? '{}';
      final decoded = jsonDecode(rawArgs);
      if (decoded is Map<String, dynamic>) {
        arguments = decoded;
      }
    } catch (e) {
      debugPrint('[SideMenu] _buildToolHeader: Failed to parse arguments JSON: $e');
    }

    final brief = arguments['brief'] as String? ?? 'Calling tool $functionName';

    // Get message from toolMap and interpolate variables
    final toolConfig = toolMap[functionName];
    String message = '';
    if (toolConfig != null && toolConfig['message'] != null) {
      message = _interpolateMessage(
        toolConfig['message'] as String,
        arguments,
      );
    }

    final categoryResult = getCategoryWiseString(functionCategory);
    final text = categoryResult.text;

    // Extract the tool name after "Sukuna is using " or "Sukuna is "
    String prefix = '';
    String toolName = '';

    if (text.contains('using ')) {
      final splitIndex = text.indexOf('using ') + 6;
      prefix = text.substring(0, splitIndex);
      toolName = text.substring(splitIndex);
    } else if (text.contains('reasoning')) {
      prefix = 'Sukuna is ';
      toolName = 'reasoning';
    } else {
      toolName = text;
    }

    final textWidget = Flexible(
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).typography.xSmall.copyWith(
            color: Theme.of(context).colorScheme.mutedForeground,
          ), // Inherit base style
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: toolName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' | $message'),
          ],
        ),
      ).small,
    );

    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Icon(categoryResult.icon, size: 16),
        ),
        textWidget,
      ],
    ).muted.iconMutedForeground();
  }

  /// Gets the body type configuration from toolMap
  String _getBodyType(String functionName) {
    final toolConfig = toolMap[functionName];
    if (toolConfig != null && toolConfig['body'] != null) {
      return toolConfig['body'] as String;
    }
    return 'editor'; // default
  }

  /// Checks if the response data contains an error
  bool _hasError(String? data) {
    if (data == null) return false;
    return data.contains('[Error]') ||
        data.contains('Error:') ||
        data.contains('"error"');
  }

  /// Extracts error message from response data
  String _extractErrorMessage(String data) {
    // Try to extract error message after [Error] or Error:
    final errorMatch = RegExp(r'\[Error\]\s*(.+?)(?:\n|$)').firstMatch(data);
    if (errorMatch != null) return errorMatch.group(1)?.trim() ?? data;

    final colonMatch = RegExp(r'Error:\s*(.+?)(?:\n|$)').firstMatch(data);
    if (colonMatch != null) return colonMatch.group(1)?.trim() ?? data;

    // Return first 200 chars as fallback
    return data.length > 200 ? '${data.substring(0, 200)}...' : data;
  }

  Widget _buildContent() {
    // Bounds check for activeIndex
    if (activeIndex < 0 || activeIndex >= messagesWithToolCalls.length) {
      return _buildEmptyState();
    }

    final function = toolCall!['function'];
    if (function == null) return const SizedBox.shrink();

    final functionName = function['name'] as String? ?? 'Unknown Tool';

    // Safe JSON parsing with type checking
    Map<String, dynamic> arguments = {};
    try {
      final rawArgs = function['arguments'] as String? ?? '{}';
      final decoded = jsonDecode(rawArgs);
      if (decoded is Map<String, dynamic>) {
        arguments = decoded;
      }
    } catch (e) {
      debugPrint('[SideMenu] _buildContent: Failed to parse arguments JSON: $e');
    }

    final bodyType = _getBodyType(functionName);
    final rawData =
        messagesWithToolCalls[activeIndex].metadata?['data']?.toString() ?? '';

    // Fallback builder for widgets that need it
    Widget fallbackBuilder() => EditorContent(rawData: rawData);

    // Check for errors in response data first
    if (_hasError(rawData)) {
      return ErrorContent(errorMessage: _extractErrorMessage(rawData));
    }

    // Handle terminal body type
    if (bodyType == 'terminal') {
      return TerminalContent(rawData: rawData, arguments: arguments);
    }

    // Handle list body types (list, list[fields])
    if (bodyType.startsWith('list')) {
      return ListContent(
        rawData: rawData,
        bodyType: bodyType,
        functionName: functionName,
        fallbackBuilder: fallbackBuilder,
      );
    }

    // Handle map body types (map[keys])
    if (bodyType.startsWith('map')) {
      return MapContent(rawData: rawData, bodyType: bodyType);
    }

    // Handle arg[field] body type - displays code block from arguments
    if (bodyType.startsWith('arg[')) {
      final fieldMatch = RegExp(r'arg\[(\w+)\]').firstMatch(bodyType);
      if (fieldMatch != null) {
        final field = fieldMatch.group(1)!;
        return CodeBlockContent(code: arguments[field]?.toString() ?? '');
      }
    }

    // Handle editor[field] body type - displays specific field content
    if (bodyType.startsWith('editor[')) {
      final fieldMatch = RegExp(r'editor\[(\w+)\]').firstMatch(bodyType);
      if (fieldMatch != null) {
        final field = fieldMatch.group(1)!;
        return EditorContent(
          specificContent: arguments[field]?.toString() ?? '',
        );
      }
    }

    // Handle confirmation body type
    if (bodyType == 'confirmation') {
      final toolConfig = toolMap[functionName];
      String message = functionName;
      if (toolConfig != null && toolConfig['message'] != null) {
        message = _interpolateMessage(
          toolConfig['message'] as String,
          arguments,
        );
      }
      return ConfirmationContent(message: message);
    }

    // Handle diff_viewer body type
    if (bodyType == 'diff_viewer') {
      return DiffViewerContent(
        arguments: arguments,
        rawData: rawData,
        fallbackBuilder: fallbackBuilder,
      );
    }

    // Handle image_preview body type
    if (bodyType == 'image_preview') {
      return ImagePreviewContent(
        rawData: rawData,
        fallbackBuilder: fallbackBuilder,
      );
    }

    // Handle video_preview body type
    if (bodyType == 'video_preview') {
      return VideoPreviewContent(
        rawData: rawData,
        fallbackBuilder: fallbackBuilder,
      );
    }

    // Handle table body type
    if (bodyType == 'table') {
      return TableContent(rawData: rawData, fallbackBuilder: fallbackBuilder);
    }

    // Handle plan_viewer body type
    if (bodyType == 'plan_viewer') {
      return PlanViewerContent(
        rawData: rawData,
        fallbackBuilder: fallbackBuilder,
      );
    }

    // Default editor body type
    return EditorContent(rawData: rawData);
  }
}
