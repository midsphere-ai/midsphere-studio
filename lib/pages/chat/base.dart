import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:arcane/arcane.dart' hide ChatTheme;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide Avatar;
import 'package:flutter_client/logics/data/providers/incognito_provider.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'package:flutter_client/logics/domain/entities/memory/conversation/message.dart';
import 'package:flutter_client/logics/services/agent_stream_service.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/pages/chat/empty.dart';
import 'package:flutter_client/pages/chat/manager.dart';
import 'package:flutter_client/pages/chat/input/agent_input.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';
import 'package:flutter_client/widgets/backgrounds/dividers.dart';
import 'package:flutter_client/widgets/state/toast_helper.dart';

import '../../logics/data/global_logics.dart';
import '../../widgets/builders/mobile_builder.dart';
import '../../widgets/backgrounds/constrained_box.dart' show LimitedWindowBox;

import 'common/sidemenu.dart';
import 'messages/components/task.dart';
import 'messages/components/user.dart';

/// Loading states for the chat UI.
enum ChatLoadingState { idle, loading, success, error }

/// Main chat UI widget with SSE-based real-time updates.
class ChatUI extends StatefulWidget {
  final String? conversationId;
  final bool? isBusy;

  const ChatUI({super.key, this.conversationId, this.isBusy});

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  // State
  ChatLoadingState _loadingState = ChatLoadingState.idle;
  bool _isAgentBusy = false;
  bool _showProcessPanel = false;
  bool _isPaginating = false;
  bool _isWaitingForHumanInput = false;
  Map<String, dynamic>? _hitlMetadata;

  // Controllers
  final ChatManager _manager = ChatManager();
  final ScrollController _scrollController = ScrollController();
  final InMemoryChatController _chatController = InMemoryChatController();

  void _log(String message) {
    if (kDebugMode) debugPrint('[ChatUI] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('initState: conversationId=${widget.conversationId}, isBusy=${widget.isBusy}');
    _isAgentBusy = widget.isBusy ?? false;
    _initializeChat();
  }

  @override
  void didUpdateWidget(covariant ChatUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    _log('didUpdateWidget: conversationId=${widget.conversationId}');
    if (widget.conversationId != oldWidget.conversationId) {
      _log('Conversation ID changed. Resetting manager and messages.');
      _manager.reset();
      _chatController.messages.clear();
      _isAgentBusy = widget.isBusy ?? false;
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _log('dispose');
    _manager.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  void _initializeChat() {
    _log('_initializeChat: conversationId=${widget.conversationId}');
    if (widget.conversationId != null) {
      _manager.setConversation(widget.conversationId!);
      _loadMessages();

      // Only connect SSE if conversation is busy and we have a taskId
      // (if reopening an already-busy conversation without taskId, rely on
      // conversation stream for status updates instead)
      if (_isAgentBusy && _manager.taskId != null) {
        _log('Connecting SSE (conversation is ongoing, taskId=${_manager.taskId})');
        _connectSSE();
      }
    } else {
      _log('_initializeChat: conversationId is null');
    }
  }

  Future<void> _loadMessages() async {
    _log('_loadMessages: Starting load');
    setState(() => _loadingState = ChatLoadingState.loading);

    // Insert placeholder messages while loading
    _insertPlaceholderMessages();

    try {
      final repo = await _manager.loadMessages();
      _log('_loadMessages: Messages loaded. Count: ${repo.items.length}');
      if (!mounted) {
        _log('_loadMessages: Widget not mounted after load');
        return;
      }

      _chatController.messages.clear();
      _removeTemporaryMessages();
      _insertMessagesFromRepo(repo);

      setState(() => _loadingState = ChatLoadingState.success);
    } catch (e, stack) {
      _log('_loadMessages: Error loading messages: $e\n$stack');
      _removeTemporaryMessages();
      _showError('Error loading messages: $e');
      setState(() => _loadingState = ChatLoadingState.error);
    }
  }

  void _connectSSE() {
    _manager.connectSSE(
      onMessage: _handleSSEMessage,
      onComplete: _handleSSEComplete,
      onError: _handleSSEError,
      onStatusChanged: _handleSSEStatusChanged,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SSE Event Handlers
  // ─────────────────────────────────────────────────────────────────────────

  void _handleSSEMessage(AgentStreamEvent event) {
    if (!mounted) {
      _log('_handleSSEMessage: Widget not mounted');
      return;
    }
    if (event.message == null) {
      _log('_handleSSEMessage: event.message is null');
      return;
    }

    final msg = event.message!;
    _log('_handleSSEMessage: Received message type=${msg.messageType}, id=${msg.id}');
    _log('________________________');
    _log('handle sse message');
    _log('Raw Message: ${msg.toJson()}');
    _removeTemporaryMessages();

    try {
      // ── HITL detection ──
      final isHitl = msg.metadata?['hitl'] == true ||
          msg.metadata?['tool_name'] == 'human_input' ||
          (msg.kwargs?['tool_name'] == 'human_input');

      if (isHitl) {
        _log('_handleSSEMessage: HITL detected');
        final args = msg.kwargs?['arguments'] ?? msg.metadata?['arguments'];
        setState(() {
          _isWaitingForHumanInput = true;
          _hitlMetadata = {
            if (args is Map) ...Map<String, dynamic>.from(args),
            'prompt': msg.kwargs?['prompt'] ?? msg.metadata?['prompt'] ?? 'Please provide input',
          };
        });
      }

      if (msg.messageType == 'user') {
        _log('_handleSSEMessage: Inserting USER message');
        _chatController.insertMessage(
          TextMessage(
            id: msg.id,
            authorId: ChatUsers.user.id,
            createdAt: DateTime.now().toUtc(),
            text: msg.message,
            metadata: msg.metadata,
          ),
        );
      } else if (msg.messageType == 'output') {
        _log('_handleSSEMessage: Inserting OUTPUT message');
        _chatController.insertMessage(
          TextMessage(
            id: 'error-${msg.id}',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: msg.message,
            metadata: msg.kwargs,
          ),
        );
      } else {
        _log('_handleSSEMessage: Inserting BACKEND message');
        _log('________________________________________________');
        _log('Inserting message from backend');
        _log('${msg.toJson()}');
        _log('|||');
        _insertBackendMessage(
          msg.id,
          {
            ...?msg.kwargs,
            "msg_object": msg.toJson(),
          },
          source: 'SSE',
          controller: _chatController,
        );
      }
    } catch (e,s) {
      _log('_handleSSEMessage: Error processing message: $e');
      _log('$s');
    }
  }

  void _handleSSEComplete() {
    _log('_handleSSEComplete');
    if (!mounted) return;
    _removeTemporaryMessages();
    setState(() => _isAgentBusy = false);
  }

  void _handleSSEError(String error) {
    _log('_handleSSEError: $error');
    if (!mounted) return;
    _showError(error);
    setState(() => _isAgentBusy = false);
  }

  /// Handle conversation status changes from SSE.
  /// This is triggered when the conversation's onGoing status changes
  /// (e.g., agent starts working or finishes).
  void _handleSSEStatusChanged(bool isOnGoing) {
    _log('_handleSSEStatusChanged: isOnGoing=$isOnGoing');
    if (!mounted) return;
    setState(() => _isAgentBusy = isOnGoing);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Message Sending
  // ─────────────────────────────────────────────────────────────────────────

  void _handleMessageSend(Map<String, dynamic> data) async {
    _log('_handleMessageSend: Sending message. Data keys: ${data.keys}');
    // Update app bar for new conversations
    if (_chatController.messages.isEmpty) {
      _log('_handleMessageSend: First message, updating app bar');
      // RootShell manages the home page's appbar state (title, icon).
      // This is a legacy pattern predating GoRouter - the home page uses
      // RootShell for in-page navigation while GoRouter handles top-level routes.
      RootShell.updateAppbar(
        const ValueKey('main'),
        'Chat',
        LucideIcons.messagesSquare,
      );
    }

    // Show loading and set busy state
    setState(() => _isAgentBusy = true);
    _insertLoadingIndicator();

    // Send message via manager
    _log('_handleMessageSend: Invoking _manager.sendMessage');
    try {
      _log('_handleMessageSend: Args types - files: ${data['files']?.runtimeType}, addons: ${data['addons']?.runtimeType}, customise: ${data['customise']?.runtimeType}');

      await _manager.sendMessage(
        message: data['message'] as String,
        files: (data['files'] as List?)?.map((e) => e.toString()).toList() ?? [],
        addons: (data['addons'] as List?)?.map((e) => e.toString()).toList() ?? [],
        mcp: (data['mcp'] as List?)?.map((e) => e.toString()).toList() ?? [],
        model: data['model'] as String?,
        customise: data['customise'] != null ? Map<String, dynamic>.from(data['customise']) : null,
        onMessage: _handleSSEMessage,
        onComplete: _handleSSEComplete,
        onError: _handleSSEError,
      );
    } catch (e, s) {
      _log('_handleMessageSend: CRITICAL ERROR calling sendMessage: $e');
      _log('$s');
      _showError('Failed to send message: $e');
      setState(() => _isAgentBusy = false);
    }
  }

  Future<void> _cancelTask() async {
    _log('_cancelTask: Requesting cancellation');
    final success = await _manager.cancelTask();
    _log('_cancelTask: Cancellation success=$success');
    if (success) {
      _showToast('Task scheduled for cancellation', LucideIcons.check);
      await postHogInstance.capture(
        eventName: 'user_cancel_task',
        properties: {'conversation_id': _manager.conversationId ?? ''},
      );
    } else {
      _showToast('Could not cancel task', LucideIcons.x);
    }
    setState(() => _isAgentBusy = false);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pagination
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadOlderMessages() async {
    _log('_loadOlderMessages: Paginating. isPaginating=$_isPaginating, hasReachedEnd=${_manager.hasReachedEnd}');
    if (_isPaginating || _manager.hasReachedEnd) return;

    _isPaginating = true;
    try {
      final repo = await _manager.loadMoreMessages();
      _log('_loadOlderMessages: Loaded repo. Count=${repo?.items.length}');
      if (repo != null && mounted) {
        final existingIds = _chatController.messages.map((m) => m.id).toSet();
        _insertMessagesFromRepo(repo, existingIds: existingIds, atEnd: true);
      }
    } finally {
      _isPaginating = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Message Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _insertMessagesFromRepo(
    BaseRepository repo, {
    Set<String>? existingIds,
    bool atEnd = false,
  }) {
    _log('_insertMessagesFromRepo: Inserting ${repo.items.length} items. atEnd=$atEnd');
    repo.removeDuplicates();

    // For pagination (atEnd=true), insert at the end of the list (older messages at higher indices)
    // For initial load, insert at beginning (index 0 or null)
    int? insertIndex = atEnd ? _chatController.messages.length : null;

    // Disable animation for pagination to prevent visual glitches
    final bool shouldAnimate = !atEnd;

    // For initial load: reverse items so oldest is inserted first at index 0, pushing newer down
    // For pagination: don't reverse - insert newest-of-old-batch first at end, maintaining order
    // API returns newest first, so:
    //   - Initial: reverse → oldest first → insert at 0 → [newest, ..., oldest] in array
    //   - Pagination: no reverse → newest-of-old first → append → [...existing, newer-old, ..., oldest]
    final items = atEnd ? repo.items : repo.items.reversed;

    for (final item in items) {
      if (item is! SukunaMessage) continue;
      // Skip duplicates - check if message already exists
      if (existingIds != null && existingIds.contains(item.id)) {
        _log('Skipping duplicate message: ${item.id}');
        continue;
      }

      _log('________________________');
      _log('handle base repo message');
      _log('${item.toJson()}');
      if (item.messageType == 'user') {
        _chatController.insertMessage(
          TextMessage(
            id: item.id,
            authorId: ChatUsers.user.id,
            createdAt: DateTime.now().toUtc(),
            text: item.message,
            metadata: item.metadata,
          ),
          index: insertIndex,
          animated: shouldAnimate,
        );
      } else if (item.messageType == "output") {
        _chatController.insertMessage(
          TextMessage(
            id: 'error-${item.id}',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: item.message,
            metadata: item.kwargs,
          ),
          index: insertIndex,
          animated: shouldAnimate,
        );
      } else {
        // Only call insertMessageWithMap for messages that aren't user/output
        _log('_____________');
        _log('Adding message from backend: ${item.id}');
        _insertBackendMessage(
          item.id,
          {
            ...?item.kwargs,
            "msg_object": item.toJson()
          },
          source: 'Pre-fetched',
          controller: _chatController,
          index: insertIndex,
          animated: shouldAnimate,
        );
      }

      // Increment index for pagination to maintain correct order
      if (insertIndex != null) insertIndex++;
    }
  }

  TextMessage? _insertBackendMessage(
    String id,
    Map<String, dynamic> metadata, {
    bool reload = false,
    String? source,
    InMemoryChatController? controller,
    int? index,
    bool? animated,
    bool justReturn = false,
  }) {
    _log('_insertBackendMessage: id=$id, source=$source, justReturn=$justReturn');
    // Add source to metadata if provided

    final enrichedMetadata = source != null
        ? {...metadata, 'source': source}
        : metadata;

    String msgText = "";

    if(enrichedMetadata.containsKey('error_type')){
      id = 'custom-error-$id';
      msgText = enrichedMetadata['msg_object']?['message']?.toString() ?? "";
    }

    // Create message
    final msg = TextMessage(
      id: id,
      authorId: ChatUsers.agent.id,
      createdAt: DateTime.now().toUtc(),
      text: msgText,
      metadata: enrichedMetadata,
    );

    // Return early if requested
    if (justReturn) {
      _log('returning early');
      return msg;
    }

    // Insert message with appropriate animation
    final shouldAnimate = animated ?? (controller == null);
    final targetController = controller ?? _chatController;

    targetController.insertMessage(msg, index: index, animated: shouldAnimate);
    return msg;
  }

  void _insertLoadingIndicator() {
    _chatController.insertMessage(
      TextMessage(
        id: 'loading-${Uuid().v4()}',
        authorId: ChatUsers.agent.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {'status': 'LOADING'},
      ),
      animated: true,
    );
  }

  /// Insert placeholder messages to show loading state
  void _insertPlaceholderMessages() {
    // Insert alternating user and agent placeholder messages
    final placeholders = [
      TextMessage(
        id: 'placeholder-user-1',
        authorId: ChatUsers.user.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {'status': 'PLACEHOLDER'},
      ),
      TextMessage(
        id: 'placeholder-agent-1',
        authorId: ChatUsers.agent.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {'status': 'PLACEHOLDER'},
      ),
      TextMessage(
        id: 'placeholder-user-2',
        authorId: ChatUsers.user.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {'status': 'PLACEHOLDER'},
      ),
      TextMessage(
        id: 'placeholder-agent-2',
        authorId: ChatUsers.agent.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {'status': 'PLACEHOLDER'},
      ),
    ];

    for (final placeholder in placeholders) {
      _chatController.insertMessage(placeholder, animated: false);
    }
  }

  /// Remove all temporary messages (placeholders and loading indicators)
  void _removeTemporaryMessages() {
    final toRemove = _chatController.messages
        .where((m) => m.id.startsWith('placeholder-') || m.id.startsWith('loading-'))
        .toList();
    for (final msg in toRemove) {
      _chatController.removeMessage(msg);
    }
  }

  void _showError(String message) {
    ToastHelper.show(context, message, LucideIcons.badgeAlert);
  }

  void _showToast(String message, IconData icon) {
    ToastHelper.show(context, message, icon);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MobileView(
      mobile: _showProcessPanel && _chatController.messages.isNotEmpty
          ? _buildProcessPanelMobile()
          : _buildMainContent(),
      desktop: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    Widget content = _buildChatContainer();

    if (_loadingState == ChatLoadingState.loading &&
        _chatController.messages.isNotEmpty) {
      return content.asSkeleton();
    }

    // Build both layouts and animate between them with personality
    if (_chatController.messages.isNotEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isWithPanel = child.key == const ValueKey('with_panel');

          if (isWithPanel) {
            // Opening panel: slide in from right with bounce
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );
          } else {
            // Closing panel: smooth expand with subtle bounce
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.01, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.995, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          }
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: _showProcessPanel
            ? KeyedSubtree(
                key: const ValueKey('with_panel'),
                child: ResizablePanel.horizontal(
                  draggerBuilder: (_) => const HorizontalResizableDragger(),
                  dividerBuilder: (_) => DottedVerticalDivider(
                    color: Theme.of(context).colorScheme.border,
                  ),
                  children: [
                    ResizablePane.flex(child: content),
                    _buildProcessPanelDesktop(),
                  ],
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('without_panel'),
                child: content,
              ),
      );
    }

    return content;
  }

  Widget _buildChatContainer() {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: IncognitoModeProvider(),
      builder: (context, isIncognito, child) {
        return Stack(
          children: [
            // Main chat container with animated border
            AnimatedContainer(
              duration: AnimationConstants.incognitoTransition,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: scheme.background,
                borderRadius: BorderRadius.circular(12),
                border: isIncognito
                    ? Border.all(
                        color: scheme.primary.withValues(
                          alpha: AnimationConstants.incognitoBorderAlpha,
                        ),
                        width: 1,
                      )
                    : null,
              ),
              child: LimitedWindowBox(
                customWidth: 840,
                child: Stack(
                  children: [
                    MobileView(
                      mobile: _buildChat(),
                      desktop: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildChat(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Incognito ambient glow overlay
            if (isIncognito) _buildIncognitoAmbientGlow(scheme),
          ],
        );
      },
    );
  }

  /// Builds a subtle ambient glow overlay for incognito mode
  Widget _buildIncognitoAmbientGlow(ColorScheme scheme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      scheme.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChat() {
    final colors = Theme.of(context).colorScheme;
    final chatTheme = ChatColors(
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      surface: colors.background,
      onSurface: colors.foreground,
      surfaceContainer: colors.card,
      surfaceContainerLow: colors.card,
      surfaceContainerHigh: colors.card,
    );

    return LimitedWindowBox(
      customWidth: DataConstants.pageWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: Chat(
              chatController: _chatController,
              currentUserId: ChatUsers.user.id,
              builders: Builders(
                chatAnimatedListBuilder: (context, itemBuilder) {
                  return ChatAnimatedList(
                    reversed: true,
                    scrollController: _scrollController,
                    insertAnimationDuration: const Duration(milliseconds: 150),
                    scrollToBottomAppearanceDelay: const Duration(
                      milliseconds: 100,
                    ),
                    itemBuilder: itemBuilder, bottomPadding: 250,
                    onEndReached: _loadOlderMessages,
                    shouldScrollToEndWhenAtBottom: true,
                    shouldScrollToEndWhenSendingMessage: true,
                    initialScrollToEndMode: InitialScrollToEndMode.none,
                  );
                },
                chatMessageBuilder: (context, message, index, animation, child, {bool? isRemoved, required bool isSentByMe, groupStatus}) {
                  return ChatMessage(
                    message: message,
                    index: index,
                    animation: animation,
                    isRemoved: isRemoved,
                    groupStatus: groupStatus,
                    verticalPadding: 0,
                    verticalGroupedPadding: 0,
                    horizontalPadding: 0,
                    child: child,
                  );
                },
                textMessageBuilder: _buildTextMessage,
                emptyChatListBuilder: (_) =>
                    EmptyChatUI(callback: _handleMessageSend),
                composerBuilder: (_) => const SizedBox.shrink(),
              ),
              theme: ChatTheme(
                colors: chatTheme,
                typography: ChatTypography.standard(),
                shape: BorderRadiusGeometry.circular(8),
              ),
              resolveUser: (id) async =>
                  id == ChatUsers.user.id ? ChatUsers.user : ChatUsers.agent,
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildInputArea()),
        ],
      ),
    );
  }

  Widget _buildTextMessage(
    BuildContext context,
    TextMessage message,
    int index, {
    MessageGroupStatus? groupStatus,
    required bool isSentByMe,
  }) {
    if (isSentByMe) {
      return UserMessageBubble(message: message);
    }
    return BotMessageBubble(
      index: index,
      controller: _chatController,
      message: message,
      source: message.metadata?['source'],
    );
  }

  Widget _buildInputArea() {
    if (_isWaitingForHumanInput) {
      return _buildHitlInputArea();
    }

    if (_isAgentBusy) {
      return _buildBusyIndicator();
    }

    if (_chatController.messages.isNotEmpty) {
      return Stack(
        fit: StackFit.loose,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Theme.of(context).borderRadiusXxl.bottomLeft.x),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.background.withOpacity(0.0),
                      Theme.of(context).colorScheme.background.withOpacity(0.4),
                      Theme.of(context).colorScheme.background,
                    ],
                    stops: const [0.1, 0.3, 0.8],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final isCollapsedMenu = child.key == const ValueKey('collapsed_menu');

                  if (isCollapsedMenu) {
                    // Appearing: smooth rise with subtle bounce
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                      ),
                      child: SizeTransition(
                        sizeFactor: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        axisAlignment: 1.0,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          )),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Disappearing: gentle collapse upward
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
                      ),
                      child: SizeTransition(
                        sizeFactor: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInCubic,
                        ),
                        axisAlignment: 1.0,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInCubic,
                          )),
                          child: child,
                        ),
                      ),
                    );
                  }
                },
                child: _showProcessPanel
                    ? const SizedBox.shrink(key: ValueKey('hidden'))
                    : KeyedSubtree(
                        key: const ValueKey('collapsed_menu'),
                        child: _buildCollapsedSideMenu(),
                      ),
              ),
              AgentInputBar(
                key: const ValueKey('followUp'),
                placeHolder: 'Add modifications...',
                onClicked: _handleMessageSend,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBusyIndicator() {
    return Card(
      borderRadius: Theme.of(context).borderRadiusXxl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircularProgressIndicator(size: 24),
              const SizedBox(width: 8),
              const Text(
                'Sukuna is completing the task',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
            ],
          ),
          Row(
            children: [
              if (!_showProcessPanel) ...[
                IconButton.ghost(
                  shape: ButtonShape.circle,
                  icon: const Icon(LucideIcons.maximize),
                  onPressed: () => setState(() => _showProcessPanel = true),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Theme.of(context).colorScheme.border,
                ),
              ],
              IconButton.ghost(
                shape: ButtonShape.circle,
                icon: const Icon(LucideIcons.circleStop),
                onPressed: _cancelTask,
              ),
            ],
          ),
        ],
      ),
    ).muted;
  }

  Widget _buildHitlInputArea() {
    final prompt = _hitlMetadata?['prompt']?.toString() ?? 'Please provide input';
    final choices = _hitlMetadata?['choices'];

    return Card(
      borderRadius: Theme.of(context).borderRadiusXxl,
      borderColor: Colors.amber.withAlpha(80),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          if (choices is List && choices.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in choices)
                  OutlineButton(
                    onPressed: () => _respondToHitl(choice.toString()),
                    child: Text(choice.toString()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          AgentInputBar(
            key: const ValueKey('hitlInput'),
            placeHolder: 'Type your response...',
            onClicked: (data) {
              final text = data['message'] as String?;
              if (text != null && text.isNotEmpty) {
                _respondToHitl(text);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _respondToHitl(String response) async {
    _log('_respondToHitl: Sending response: $response');
    setState(() {
      _isWaitingForHumanInput = false;
      _hitlMetadata = null;
    });

    final success = await _manager.respondToHitl(response);
    if (success) {
      _showToast('Response sent', LucideIcons.check);
    } else {
      _showError('Failed to send response');
    }
  }

  Widget _buildCollapsedSideMenu() {
    if (_chatController.messages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 2),
      child: CollapsedSideMenu(
        controller: _chatController,
        onExpand: () => setState(() => _showProcessPanel = true),
        contentBuilder: () =>
            SideMenu(controller: _chatController, collapseFunction: () {}),
      ),
    );
  }

  Widget _buildProcessPanelMobile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: SideMenu(
        controller: _chatController,
        collapseFunction: () => setState(() => _showProcessPanel = false),
      ),
    );
  }

  ResizablePane _buildProcessPanelDesktop() {
    return ResizablePane.flex(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          // Bouncy slide-in from right with scale
          final slideOffset = 30 * (1 - value);
          final scale = 0.95 + (0.05 * value);
          final opacity = Curves.easeOut.transform(value.clamp(0.0, 1.0));

          return Opacity(
            opacity: opacity,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(slideOffset, 0.0)
                ..scale(scale),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.sidebar,
          ),
          child: SideMenu(
            controller: _chatController,
            collapseFunction: () => setState(() => _showProcessPanel = false),
          ),
        ),
      ),
    );
  }
}
