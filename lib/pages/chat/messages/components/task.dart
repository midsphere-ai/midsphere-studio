import 'dart:convert';

import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_client/widgets/state/toast_helper.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../logics/data/global_logics.dart';
import '../../../../logics/data/helpers/general_utils.dart';
import '../../../../logics/domain/entities/memory/misc/schemas.dart';
import '../../../../packages/widget/markdown.dart';
import '../../../home/home.dart';
import '../../common/sidemenu.dart';
import '../../input/agent_input.dart';

part 'task_file_system_tools.dart';
part 'task_attachment_card.dart';

class BotMessageBubble extends StatefulWidget {
  final int index;
  final InMemoryChatController controller;
  final TextMessage message;
  final String? source;
  const BotMessageBubble({
    super.key,
    required this.index,
    required this.controller,
    required this.message,
    this.source,
  });

  @override
  State<BotMessageBubble> createState() => _BotMessageBubbleState();
}

class _BotMessageBubbleState extends State<BotMessageBubble> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 8),
      child: _buildMain(),
    );
  }

  Widget _buildMain(){
    try {
      // Show placeholder loading state
      if (widget.message.metadata?['status'] == 'PLACEHOLDER') {
        return _buildPlaceholder();
      }

      if (_isThinkingStatus()) {
        return _buildThinkingIndicator();
      }

      return _buildMessageContent();
    } catch (e, s) {
      return _handleMalformedMessage();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(LucideIcons.triangle, size: 14),
              Text('Sukuna').small,
            ],
          ),
          SizedBox(height: 12),
          Text('Loading response from agent...'),
          SizedBox(height: 8),
          Text('Please wait while the content is being fetched.').small,
        ],
      ),
    ).asSkeleton();
  }

  Widget _buildToolHeader(toolCall, Map<String, dynamic> arguments) {
    if (toolCall == null) return const SizedBox.shrink();

    final function = toolCall!['function'];
    if (function == null) return const SizedBox.shrink();

    final functionCategory = widget.message.metadata?['tool_name'];
    final functionName = function['name'] as String? ?? 'Unknown Tool';

    final brief = arguments['brief'] as String? ?? 'Calling tool $functionName';

    // Get message from toolMap and interpolate variables
    final toolConfig = toolMap[functionName];
    String message = '';
    if (toolConfig != null && toolConfig['message'] != null) {
      message = _interpolateMessage(
        toolConfig['message'] as String,
        arguments as Map<String, dynamic>,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: Theme.of(context).typography.small.copyWith(
            color: Theme.of(context).colorScheme.mutedForeground,
          ), // Inherit base style
          children: [
            TextSpan(
              text: StringCapitalization(toolName).capitalize(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.accentForeground,
              ),
            ),
            TextSpan(text: '  $message'),
          ],
        ),
      ).small,
    );

    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.border),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(categoryResult.icon, size: 13),
        ),
        textWidget,
      ],
    ).muted.iconMutedForeground();
  }

  bool _isThinkingStatus() {
    final status = widget.message.metadata?['status'];
    return widget.message.metadata != null && status == 'START';
  }

  Widget _buildThinkingIndicator() {
    // Guard against empty messages list - return empty for safety
    if (widget.controller.messages.isEmpty) {
      return const SizedBox.shrink();
    }
    // Only show thinking indicator for the last message
    if (widget.message.id != widget.controller.messages.last.id) {
      return const SizedBox.shrink();
    }
    return Text("Sukuna is thinking...").muted.small
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms)
        .small;
  }

  Widget _buildMessageContent() {
    try {
      final metadata = widget.message.metadata;

      // ── Orbiter event types (check msg_object.messageType first) ──
      final msgObject = metadata?['msg_object'];
      if (msgObject != null && msgObject is Map) {
        final messageType = msgObject['messageType']?.toString();

        if (messageType == 'tool_call') {
          return _buildOrbiterToolCall(msgObject);
        }
        if (messageType == 'reasoning') {
          return _buildOrbiterReasoning(msgObject);
        }
        if (messageType == 'status') {
          return _buildOrbiterStatus(msgObject);
        }
        if (messageType == 'error') {
          return _buildOrbiterError(msgObject);
        }
        if (messageType == 'usage') {
          return _buildOrbiterUsage(msgObject);
        }

        // Orbiter tool_result_output — no origin_tool_call
        if (messageType == 'tool_result_output') {
          final kwargs = msgObject['kwargs'];
          final toolName = kwargs?['tool_name'] ?? metadata?['tool_name'];

          // HITL message detection
          if (toolName == 'human_input' || metadata?['hitl'] == true) {
            return _buildHitlMessage(msgObject, metadata!);
          }

          if (toolName == 'mcp_message') {
            return _buildOrbiterMcpMessage(msgObject, metadata!);
          }
          if (toolName != null &&
              !toolName.toString().contains('computer_use') &&
              !toolName.toString().contains('browser_use')) {
            return _buildOrbiterToolResultItem(msgObject, metadata!);
          }
          // computer_use / browser_use — fall through to shrink
        }
      }

      // ── Legacy paths (origin_tool_call) ──
      final originToolCall = metadata?['origin_tool_call'];

      // Handle MCP message tool call
      if (originToolCall != null && _isMcpMessage(originToolCall)) {
        return _buildMcpMessage(originToolCall);
      }

      // Handle other tool calls with origin_tool_call
      if (originToolCall != null) {
        if (originToolCall.toString().contains('mcp_computer_use')) {
          // Ignored mcp_computer_use
        } else if (originToolCall.toString().contains('mcp_browser_use')) {
          // Ignored mcp_browser_use
        } else {
          return SizedBox.shrink();
        }
      }

      if (metadata != null && metadata.containsKey('tool_calls')) {
        final toolCalls = metadata['tool_calls'];
        if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
          final firstToolCall = toolCalls[0];
          if (firstToolCall != null && firstToolCall['data'] != null) {
            final function = firstToolCall['data']['function'];
            if (function != null && function['name'] != null) {

              if(function['name'] == 'mcp_message'){
                return _buildToolCallsList(toolCalls);
              }

              if (function['name'].toString().contains('computer_use') ||
                  function['name'].toString().contains('browser_use')) {
                return _buildPreToolCall(toolCalls);
              }
            }
          }
        }
      }

      // Default message with markdown and tool calls
      if (widget.message.id.contains('error-')) {
        return _buildErrorMessage(null);
      }

      // Null safety check for metadata
      if (metadata == null || !metadata.containsKey('msg_object')) {
        return const SizedBox.shrink();
      }

      // Safe access with null checks — error_type check
      if (msgObject != null &&
          msgObject['metadata'] != null &&
          msgObject['metadata'] is Map &&
          (msgObject['metadata'] as Map).containsKey('error_type')) {
        return _buildErrorMessage(msgObject['message']?.toString());
      }

      return const SizedBox.shrink();
    } catch (e, s) {
      return _handleMalformedMessage();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Orbiter Event Type Renderers
  // ─────────────────────────────────────────────────────────────────────────

  /// Orbiter `tool_call` event — shows tool invocation indicator.
  Widget _buildOrbiterToolCall(Map msgObject) {
    final kwargs = msgObject['kwargs'] ?? {};
    final toolName = kwargs['tool_name']?.toString() ?? 'unknown';
    final agentName = kwargs['agent_name']?.toString();

    final categoryResult = getCategoryWiseString(
      widget.message.metadata?['tool_name'] ?? toolName,
    );

    return Container(
      padding: const EdgeInsets.only(top: 6),
      child: Card(
        filled: true,
        fillColor: Theme.of(context).colorScheme.card,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          spacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(categoryResult.icon, size: 13),
            ),
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: Theme.of(context).typography.small.copyWith(
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
                  children: [
                    TextSpan(
                      text: toolName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.accentForeground,
                      ),
                    ),
                    if (agentName != null)
                      TextSpan(text: '  ($agentName)'),
                  ],
                ),
              ).small,
            ),
          ],
        ).muted.iconMutedForeground(),
      ),
    );
  }

  /// Orbiter `reasoning` event — shows collapsible reasoning text.
  Widget _buildOrbiterReasoning(Map msgObject) {
    final kwargs = msgObject['kwargs'] ?? {};
    final text = kwargs['text']?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text("Sukuna thought for a while").small.withOpacity(0.6),
        Container(
          padding: const EdgeInsets.only(left: 8.0),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).colorScheme.border),
            ),
          ),
          child: Text(text).small.withOpacity(0.6),
        ),
      ],
    );
  }

  /// Orbiter `status` event — shows task status badge.
  Widget _buildOrbiterStatus(Map msgObject) {
    final kwargs = msgObject['kwargs'] ?? {};
    final status = kwargs['status']?.toString() ?? 'unknown';
    final statusMessage = kwargs['message']?.toString();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'running':
        statusColor = Colors.blue;
        statusIcon = LucideIcons.play;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = LucideIcons.check;
        break;
      case 'error':
        statusColor = Theme.of(context).colorScheme.destructive;
        statusIcon = LucideIcons.circleAlert;
        break;
      case 'cancelled':
        statusColor = Colors.amber;
        statusIcon = LucideIcons.circleStop;
        break;
      default:
        statusColor = Theme.of(context).colorScheme.mutedForeground;
        statusIcon = LucideIcons.circle;
    }

    return Card(
      filled: true,
      fillColor: Theme.of(context).colorScheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              Text(
                'Task $status',
                style: TextStyle(color: statusColor),
              ).small,
            ],
          ),
          if (statusMessage != null && statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(statusMessage).xSmall.muted,
            ),
        ],
      ),
    );
  }

  /// Orbiter `error` event — shows inline error with optional recoverable badge.
  Widget _buildOrbiterError(Map msgObject) {
    final kwargs = msgObject['kwargs'] ?? {};
    final errorText = kwargs['error']?.toString() ?? msgObject['message']?.toString() ?? 'Unknown error';
    final recoverable = kwargs['recoverable'] == true;
    final errorType = kwargs['error_type']?.toString();
    final stepNumber = kwargs['step_number'];
    final agentName = kwargs['agent_name']?.toString();

    final destructive = Theme.of(context).colorScheme.destructive;

    return Card(
      borderColor: destructive.withAlpha(80),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(LucideIcons.circleAlert, size: 18, color: destructive),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      "Error",
                      style: TextStyle(
                        color: destructive,
                        fontWeight: FontWeight.w500,
                      ),
                    ).small,
                    if (recoverable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'recoverable',
                          style: TextStyle(color: Colors.amber, fontSize: 10),
                        ),
                      ),
                    if (errorType != null)
                      Text(errorType, style: TextStyle(color: destructive, fontSize: 10)).muted,
                  ],
                ),
                if (errorText.isNotEmpty) Text(errorText).small.muted,
                if (agentName != null || stepNumber != null)
                  Text(
                    [
                      if (agentName != null) agentName,
                      if (stepNumber != null) 'Step $stepNumber',
                    ].join(' · '),
                  ).xSmall.muted,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orbiter `usage` event — shows token usage summary.
  Widget _buildOrbiterUsage(Map msgObject) {
    final kwargs = msgObject['kwargs'] ?? {};
    final usage = kwargs['usage'];
    final model = kwargs['model']?.toString();
    final stepNumber = kwargs['step_number'];

    if (usage == null && model == null) return const SizedBox.shrink();

    final parts = <String>[];
    if (stepNumber != null) parts.add('Step $stepNumber');
    if (model != null) parts.add(model);
    if (usage is Map) {
      final prompt = usage['prompt_tokens'];
      final completion = usage['completion_tokens'];
      final total = usage['total_tokens'];
      if (total != null) {
        parts.add('${total}t');
      } else {
        if (prompt != null) parts.add('${prompt}p');
        if (completion != null) parts.add('${completion}c');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(parts.join(' · ')).xSmall.muted,
    );
  }

  /// Orbiter `tool_result_output` rendered as a tool call item (non-MCP).
  Widget _buildOrbiterToolResultItem(Map msgObject, Map<String, dynamic> metadata) {
    final kwargs = msgObject['kwargs'] ?? {};
    final functionName = kwargs['tool_name']?.toString() ?? metadata['tool_name']?.toString() ?? 'Unknown Tool';

    // Arguments may already be a Map (Orbiter) — no jsonDecode needed
    Map<String, dynamic> toolCallArgs = {};
    final rawArgs = kwargs['arguments'] ?? metadata['arguments'];
    if (rawArgs is Map<String, dynamic>) {
      toolCallArgs = rawArgs;
    } else if (rawArgs is Map) {
      toolCallArgs = Map<String, dynamic>.from(rawArgs);
    } else if (rawArgs is String) {
      try {
        final decoded = jsonDecode(rawArgs);
        if (decoded is Map<String, dynamic>) toolCallArgs = decoded;
      } catch (_) {}
    }

    String actionMessage = toolCallArgs['brief'] as String? ?? "Performing action";

    final tools = fileSystemTools['tools'];
    if (tools != null) {
      for (final tool in tools) {
        if (tool['name'] == functionName) {
          actionMessage = tool['description']?.toString() ?? actionMessage;
        }
      }
    }

    // Check toolMap for message
    final toolConfig = toolMap[functionName];
    if (toolConfig != null && toolConfig['message'] != null) {
      actionMessage = _interpolateMessage(
        toolConfig['message'] as String,
        toolCallArgs,
      );
    }

    final currentCategory = metadata['tool_name'] ?? kwargs['tool_name'];
    final categoryObject = getCategoryWiseString(currentCategory?.toString());

    // Extract optional result metadata
    final success = kwargs['success'];
    final error = kwargs['error']?.toString();
    final durationMs = kwargs['duration_ms'];

    return Container(
      padding: const EdgeInsets.only(left: 0, bottom: 0, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(actionMessage).small.withOpacity(0.8),
          Card(
            filled: true,
            fillColor: Theme.of(context).colorScheme.card,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(categoryObject.icon, size: 13),
                ),
                Flexible(
                  child: Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          functionName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.accentForeground,
                          ),
                        ).small,
                      ),
                      if (success == true)
                        Icon(LucideIcons.check, size: 12, color: Colors.green),
                      if (success == false)
                        Icon(LucideIcons.x, size: 12, color: Theme.of(context).colorScheme.destructive),
                      if (durationMs != null)
                        Text('${durationMs}ms').xSmall.muted,
                    ],
                  ),
                ),
              ],
            ).muted.iconMutedForeground(),
          ),
          if (error != null && error.isNotEmpty)
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.destructive)).xSmall,
        ],
      ),
    );
  }

  /// Orbiter `tool_result_output` for mcp_message — read args as dict.
  Widget _buildOrbiterMcpMessage(Map msgObject, Map<String, dynamic> metadata) {
    final kwargs = msgObject['kwargs'] ?? {};

    // Arguments come as a dict in Orbiter (not JSON string)
    Map<String, dynamic> messageArgs = {};
    final rawArgs = kwargs['arguments'] ?? metadata['arguments'];
    if (rawArgs is Map<String, dynamic>) {
      messageArgs = rawArgs;
    } else if (rawArgs is Map) {
      messageArgs = Map<String, dynamic>.from(rawArgs);
    } else if (rawArgs is String) {
      try {
        final decoded = jsonDecode(rawArgs);
        if (decoded is Map<String, dynamic>) messageArgs = decoded;
      } catch (_) {
        return _handleMalformedMessage();
      }
    }

    // Delegate to common MCP message rendering
    return _buildMcpMessageFromArgs(messageArgs);
  }

  /// Shared MCP message rendering from parsed args.
  Widget _buildMcpMessageFromArgs(Map<String, dynamic> messageArgs) {
    var attachments = [];
    if (messageArgs.containsKey('attachments')) {
      var rawAttachments = messageArgs['attachments'];
      if (rawAttachments is String) {
        try {
          attachments = jsonDecode(rawAttachments);
        } catch (e) {
          attachments = rawAttachments.toString().split(',');
        }
      }
      if (rawAttachments is List) {
        attachments = rawAttachments;
      }
    }

    var suggestedAction;
    var followUpQuestions;
    if (messageArgs.containsKey('suggested_action')) {
      suggestedAction = messageArgs['suggested_action'];
    }
    if (messageArgs.containsKey('follow_up_questions')) {
      var q = messageArgs['follow_up_questions'];
      if (q is List) {
        followUpQuestions = q;
      } else if (q is String) {
        try {
          followUpQuestions = jsonDecode(q);
        } catch (e) {
          followUpQuestions = q.split("\n");
        }
      }
    }

    try {
      final messageText = messageArgs['text']?.toString() ?? '';
      if (messageText.isEmpty) return _handleMalformedMessage();

      return Column(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SizedBox.shrink(),
          _buildSukunaHeader(),
          MarkdownWidget(
            shrinkWrap: true,
            data: messageText,
            config: Toolkit.getMarkdownConfig(context),
          ).withOpacity(1),
          if (attachments.isNotEmpty) ..._buildAttachments(attachments),
          if (suggestedAction != null) ...[
            if (suggestedAction == 'review_file') _buildSuggestionReviewFile(),
            if (suggestedAction == 'provide_input') _buildSuggestionProvideInput(),
            if (suggestedAction == 'confirm') _buildSuggestionConfirmation(),
          ],
          if (followUpQuestions != null)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: followUpQuestions.length,
              itemBuilder: (context, index) {
                return Column(
                  spacing: 6,
                  children: [
                    const SizedBox.shrink(),
                    LinkButton(
                      onPressed: () {
                        AgentInputBar.updateText(
                          const ValueKey('followUp'),
                          followUpQuestions[index],
                        );
                      },
                      density: ButtonDensity.iconDense,
                      child: Row(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.cornerDownRight, size: 14).iconMutedForeground(),
                          Flexible(
                            child: Text(followUpQuestions[index]).xSmall.muted,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      );
    } catch (e) {
      return _handleMalformedMessage();
    }
  }

  Widget _buildPreToolCall(toolCalls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        _buildToolCallsList(toolCalls),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(LucideIcons.circleDotDashed, color: Colors.amber),
            Flexible(
              child:
                  Text(
                        "Agent is working...",
                        style: TextStyle(color: Colors.amber),
                      ).muted
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1800.ms),
            ),
          ],
        ),
      ],
    );
  }

  bool _isMcpMessage(dynamic toolCall) {
    return toolCall.toString().contains("mcp_message");
  }

  Widget _buildMcpMessage(dynamic toolCall) {
    // Safe JSON parsing with null checks
    Map<String, dynamic> messageArgs = {};
    try {
      final rawArgs = toolCall?['function']?['arguments'] as String? ?? '{}';
      final decoded = jsonDecode(rawArgs);
      if (decoded is Map<String, dynamic>) {
        messageArgs = decoded;
      }
    } catch (e) {
      return _handleMalformedMessage();
    }

    var attachments = [];
    if (messageArgs.containsKey('attachments')) {
      var rawAttachments = messageArgs['attachments'];
      if (rawAttachments is String) {
        try {
          attachments = jsonDecode(rawAttachments);
        } catch (e) {
          debugPrint('[TaskWidget] Failed to parse attachments as JSON: $e');
          attachments = rawAttachments.toString().split(',');
        }
      }

      if (rawAttachments is List) {
        attachments = rawAttachments;
      }
    }

    var suggestedAction;
    var followUpQuestions;
    if (messageArgs.containsKey('suggested_action')) {
      suggestedAction = messageArgs['suggested_action'];
    }
    if (messageArgs.containsKey('follow_up_questions')) {
      var q = messageArgs['follow_up_questions'];
      if (q is List) {
        followUpQuestions = q;
      } else if (q is String) {
        try{
          followUpQuestions = jsonDecode(q);
        } catch(e){
          followUpQuestions = q.split("\n");
        }

      } else {
        followUpQuestions = null;
      }
    }

    try {
      // Validate that text exists and is not empty
      final messageText = messageArgs['text']?.toString() ?? '';
      if (messageText.isEmpty) {
        return _handleMalformedMessage();
      }

      return Column(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          SizedBox.shrink(),
          _buildSukunaHeader(),
          MarkdownWidget(
            shrinkWrap: true,
            data: messageText,
            config: Toolkit.getMarkdownConfig(context),
          ).withOpacity(1),
          if (attachments.isNotEmpty) ..._buildAttachments(attachments),
          if (suggestedAction != null) ...[
            if (suggestedAction == 'review_file') _buildSuggestionReviewFile(),
            if (suggestedAction == 'provide_input')
              _buildSuggestionProvideInput(),
            if (suggestedAction == 'confirm') _buildSuggestionConfirmation(),
          ],
          if (followUpQuestions != null)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: followUpQuestions.length,
              itemBuilder: (context, index) {
                return Column(
                  spacing: 6,
                  children: [
                    SizedBox.shrink(),
                    LinkButton(
                      onPressed: () {
                        AgentInputBar.updateText(
                          ValueKey('followUp'),
                          followUpQuestions[index],
                        );
                      },
                      density: ButtonDensity.iconDense,
                      child: Row(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.cornerDownRight,
                            size: 14,
                          ).iconMutedForeground(),
                          Flexible(
                            child: Text(followUpQuestions[index]).xSmall.muted,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          SizedBox(height: 8),
        ],
      );
    } catch (e) {
      return _handleMalformedMessage();
    }
  }

  /// HITL message — shows prompt with amber status indicator.
  Widget _buildHitlMessage(Map msgObject, Map<String, dynamic> metadata) {
    final kwargs = msgObject['kwargs'] ?? {};
    final args = kwargs['arguments'] ?? metadata['arguments'];
    final prompt = (args is Map ? args['prompt'] : null)?.toString() ??
        kwargs['prompt']?.toString() ??
        'Waiting for your input';

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(LucideIcons.circleDotDashed, color: Colors.amber),
            Flexible(
              child: Text(
                prompt,
                style: TextStyle(color: Colors.amber),
              ).muted
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 3000.ms),
            ),
          ],
        ),
      ],
    );
  }

  Widget _handleMalformedMessage() {
    // Guard against empty messages list
    if (widget.controller.messages.isEmpty) {
      return const SizedBox.shrink();
    }
    // Only show malformed message warning for the last message in the chat
    if (widget.message.id != widget.controller.messages.last.id) {
      return const SizedBox.shrink();
    }
    return Card(
      borderColor: Colors.amber.withAlpha(80),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(LucideIcons.triangleAlert, size: 18, color: Colors.amber),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  "Warning",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ).small,
                Text(
                  "Unexpected response format. This will resolve automatically if the task is still running.",
                ).small.muted,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallMessage(dynamic originToolCall) {
    return _buildToolCallsList([
      {"data": originToolCall},
    ]);
  }

  Widget _buildErrorMessage(String? text) {
    final errorText = text ?? widget.message.text;
    final destructive = Theme.of(context).colorScheme.destructive;

    return Card(
      borderColor: destructive.withAlpha(80),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(LucideIcons.circleAlert, size: 18, color: destructive),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  "Error",
                  style: TextStyle(
                    color: destructive,
                    fontWeight: FontWeight.w500,
                  ),
                ).small,
                if (errorText.isNotEmpty) Text(errorText).small.muted,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSukunaHeader() {
    // Use agent_name from metadata if available
    final agentName = widget.message.metadata?['agent_name']?.toString() ??
        widget.message.metadata?['msg_object']?['metadata']?['agent_name']?.toString() ??
        'Sukuna';
    return Row(
      spacing: 4,
      children: [
        Icon(
          LucideIcons.triangle,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        Text(
          agentName,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ).small,
      ],
    ).muted.iconMutedForeground();
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

  Widget _buildToolCallsList(List<dynamic>? toolCalls) {
    if (toolCalls == null || toolCalls.isEmpty) {
      return Container();
    }

    // Extract tool names from all tool calls
    final toolNames = toolCalls.map((toolCall) {
      final toolData = toolCall['data'];
      if (toolData != null && toolData['function'] != null) {
        return toolData['function']['name'] as String? ?? 'Unknown Tool';
      }
      return 'Unknown Tool';
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: toolCalls.length,
      itemBuilder: (context, index) => _buildToolCallItem(toolCalls[index]),
    );
  }

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

  Widget _buildToolCallItem(dynamic toolCall) {
    final toolData = toolCall?['data'];
    if (toolData == null) {
      return const SizedBox.shrink();
    }

    final functionName =
        toolData['function']?['name'] as String? ?? 'Unknown Tool';

    // Safe JSON parsing with try-catch
    Map<String, dynamic> toolCallArgs = {};
    try {
      final rawArgs = toolData['function']?['arguments'] as String? ?? '{}';
      final decoded = jsonDecode(rawArgs);
      if (decoded is Map<String, dynamic>) {
        toolCallArgs = decoded;
      }
    } catch (e) {
      // Failed to parse arguments JSON
    }

    String displayMessage =
        toolCallArgs['brief'] as String? ?? "Calling tool $functionName";
    String actionMessage =
        toolCallArgs['message'] as String? ?? "Performing action";

    final tools = fileSystemTools['tools'];
    if (tools != null) {
      for (final tool in tools) {
        if (tool['name'] == functionName) {
          actionMessage = tool['description']?.toString() ?? actionMessage;
          displayMessage = tool['title']?.toString() ?? displayMessage;
        }
      }
    }

    // Get current message's category
    final currentCategory = widget.message.metadata?['tool_name'];

    // Check if we should show the category header (actionMessage)
    // Only show it if the previous bot message has a different category
    bool showCategoryHeader = true;

    if (widget.index > 0 && widget.controller.messages.isNotEmpty) {
      // Look for the previous bot message to compare categories
      for (int i = widget.index - 1; i >= 0; i--) {
        // Bounds check in case messages list was modified
        if (i >= widget.controller.messages.length) continue;
        final prevMessage = widget.controller.messages[i];
        // Skip if it's a user message (authorId == 'user1') or loading message
        if (prevMessage.authorId == 'user1' ||
            prevMessage.id.startsWith('loading-')) {
          continue;
        }
        // Found a previous bot message - check if it has the same category
        final prevCategory = prevMessage.metadata?['tool_name'];
        if (prevCategory != null && prevCategory == currentCategory) {
          showCategoryHeader = false;
        }
        break; // Only check the immediate previous bot message
      }
    }

    final categoryObject = getCategoryWiseString(currentCategory);

    // Check if this is a plan tool that should only show actionMessage
    final isPlanTool =
        functionName == 'mcp_update_plan' || functionName == 'mcp_advance_plan';

    bool shouldDisplayMessage = true;

    if (isPlanTool) {
      try {
        final toolData = widget.message.metadata?['data'];

        if (toolData.containsKey('success') && !toolData['success']) {
          shouldDisplayMessage = false;
        }
      } catch (e, s) {
        // Plan tool metadata access failed
      }
    }

    if (!shouldDisplayMessage) {
      return SizedBox.shrink();
    }

    final reasoning = (widget.message.metadata?.containsKey('reasoning') ?? false)
        ? widget.message.metadata!['reasoning'] : "";
    return Container(
      padding: EdgeInsets.only(left: 0, bottom: 0, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
            Text(actionMessage).small.withOpacity(0.8),
            Card(
              filled: true,
              fillColor: Theme.of(context).colorScheme.card,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildToolHeader(toolData, toolCallArgs),
            ).withOpacity(0.8),
        ],
      ),
    );
  }

  List<Widget> _buildAttachments(List rawAttachments) {
    // Parse attachments using the EnrichedAttachment helper
    final attachments = EnrichedAttachment.parseList(rawAttachments);

    if (attachments.isEmpty) return [];

    return [
      Text("Attachments").muted.small,
      SizedBox(height: 8),
      Text(widget.message.metadata.toString()),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var attachment in attachments)
            _AttachmentCard(attachment: attachment),
        ],
      ),
      SizedBox(height: 8),
    ];
  }

  Widget _buildSuggestionReviewFile() {
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(LucideIcons.circleDotDashed, color: Colors.amber),
            Flexible(
              child:
                  Text(
                        'Sukuna wants you to review this file before it can take any further action.',
                        style: TextStyle(color: Colors.amber),
                      ).muted
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 3000.ms),
            ),
          ],
        ),
        OutlineButton(
          onPressed: () {
            AgentInputBar.updateText(
              ValueKey('followUp'),
              'Yes, I have reviewed the file.',
            );
            ToastHelper.show(
              context,
              'Added simple prompt to your follow up from your choice',
              LucideIcons.check,
            );
          },
          child: Row(
            spacing: 8,
            children: [
              Icon(LucideIcons.triangle, size: 14),
              Text('Looks good'),
            ],
          ),
        ),
        SizedBox.shrink(),
        OutlineButton(
          onPressed: () {
            AgentInputBar.updateText(
              ValueKey('followUp'),
              'No, I would like you to ',
            );
            ToastHelper.show(
              context,
              'Added simple prompt to your follow up from your choice',
              LucideIcons.check,
            );
          },
          child: Row(
            spacing: 8,
            children: [
              Icon(LucideIcons.circle, size: 14),
              Text('Add suggestions'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionProvideInput() {
    return Row(
      spacing: 8,
      children: [
        Icon(LucideIcons.circleDotDashed, color: Colors.amber),
        Flexible(
          child:
              Text(
                    'Sukuna wants your suggestion in order to proceed ahead.',
                    style: TextStyle(color: Colors.amber),
                  ).muted
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 3000.ms),
        ),
      ],
    );
  }

  Widget _buildSuggestionConfirmation() {
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(LucideIcons.circleDotDashed, color: Colors.amber),
            Flexible(
              child:
                  Text(
                        'Sukuna wants you to confirm the following action to proceed ahead',
                        style: TextStyle(color: Colors.amber),
                      ).muted
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 3000.ms),
            ),
          ],
        ),
        OutlineButton(
          onPressed: () {
            AgentInputBar.updateText(
              ValueKey('followUp'),
              'Yes, please proceed ahead with your action.',
            );
            ToastHelper.show(
              context,
              'Added simple prompt to your follow up from your choice',
              LucideIcons.check,
            );
          },
          child: Row(
            spacing: 8,
            children: [Icon(LucideIcons.triangle, size: 14), Text('Yes')],
          ),
        ),
        SizedBox.shrink(),
        OutlineButton(
          onPressed: () {
            AgentInputBar.updateText(
              ValueKey('followUp'),
              'No, please avoid the following action.',
            );
            ToastHelper.show(
              context,
              'Added simple prompt to your follow up from your choice',
              LucideIcons.check,
            );
          },
          child: Row(
            spacing: 8,
            children: [Icon(LucideIcons.circle, size: 14), Text('No')],
          ),
        ),
      ],
    );
  }
}
