import 'dart:async';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'package:flutter_client/logics/domain/entities/memory/conversation/base.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/logics/services/conversation_stream_service.dart';

import 'library_row.dart';

/// GlobalKey for accessing ChatHistory state to trigger new item animations
final GlobalKey<_ChatHistoryState> chatHistoryKey = GlobalKey<_ChatHistoryState>();

/// Chat history sidebar using SSE for real-time updates.
///
/// Loads initial data via REST, then streams updates via SSE.
/// SSE connection is persistent (never disconnects).
class ChatHistory extends StatefulWidget {
  final Function? postHook;
  final ScrollController? customController;
  final String? activeConversationId;
  final ValueChanged<String?>? onHistorySelect;
  final bool shrinkWrap;

  const ChatHistory({
    super.key,
    this.postHook,
    this.customController,
    this.activeConversationId,
    this.onHistorySelect,
    this.shrinkWrap = true,
  });

  static final Map<Key, _ChatHistoryState> _instances = {};

  @override
  State<ChatHistory> createState() => _ChatHistoryState();

  static void reload(Key key) {
    _instances[key]?._loadInitialData();
  }
}

class _ChatHistoryState extends State<ChatHistory> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;
  bool _hasAnimatedInitialLoad = false;
  Set<String> _newlyAddedIds = {};

  // SSE stream subscription (service is a shared singleton)
  StreamSubscription<ConversationStreamEvent>? _sseSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.key != null) {
      ChatHistory._instances[widget.key!] = this;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.key != null) {
      ChatHistory._instances.remove(widget.key);
    }
    _sseSubscription?.cancel();
    _sseSubscription = null;
    super.dispose();
  }

  /// Load initial data via REST, then connect SSE for updates.
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch initial conversations
      final repo = BaseRepository();
      await Memory.getAllConversations(repo: repo);

      if (mounted) {
        setState(() {
          _conversations = repo.items.whereType<Conversation>().toList();
          _isLoading = false;
        });
      }

      // Connect SSE for real-time updates
      _connectSSE();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _connectSSE() {
    final token = DataConstants.getToken();
    if (token == null) return;

    _sseSubscription?.cancel();

    final service = getConversationStreamService();
    _sseSubscription = service.eventStream.listen(
      _handleSSEEvent,
      onError: (e) {
        debugPrint('[ChatHistory] SSE stream error: $e');
      },
    );

    if (!service.isConnected) {
      service.connect(token);
    }
  }

  void _handleSSEEvent(ConversationStreamEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case ConversationEventType.conversationUpdated:
        final conv = event.conversation;
        if (conv == null) return;

        setState(() {
          final idx = _conversations.indexWhere((c) => c.id == conv.id);
          if (idx != -1) {
            // Update in-place without re-sorting to prevent visual jumping
            _conversations[idx] = conv;
          } else if (event.isNew) {
            // Insert new conversations at the top with animation tracking
            _conversations.insert(0, conv);
            _newlyAddedIds.add(conv.id);
            // Clear animation tracking after a delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() => _newlyAddedIds.remove(conv.id));
              }
            });
          }
        });
        break;

      case ConversationEventType.conversationDeleted:
        final id = event.deletedConversationId;
        if (id == null) return;

        setState(() {
          _conversations.removeWhere((c) => c.id == id);
          _newlyAddedIds.remove(id);
        });
        break;

      case ConversationEventType.syncComplete:
        final synced = event.syncedConversations;
        if (synced.isNotEmpty) {
          setState(() {
            _conversations = synced;
            _sortConversations();
          });
        }
        break;

      default:
        break;
    }
  }

  void _sortConversations() {
    // Sort by dateUpdated (most recent activity first), fallback to dateCreated
    _conversations.sort((a, b) {
      final aDate = a.dateUpdated ?? a.dateCreated;
      final bDate = b.dateUpdated ?? b.dateCreated;
      return bDate.compareTo(aDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _conversations.isEmpty) {
      return _buildLoading();
    }

    if (_error != null && _conversations.isEmpty) {
      return _buildError();
    }

    if (_conversations.isEmpty) {
      return _buildEmpty();
    }

    return _buildList();
  }

  Widget _buildList() {
    // Mark initial load as animated after first build
    if (!_hasAnimatedInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasAnimatedInitialLoad = true);
        }
      });
    }

    return ListView.builder(
      controller: widget.shrinkWrap ? null : widget.customController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        final isNewlyAdded = _newlyAddedIds.contains(conv.id);

        return LibraryRow(
          key: ValueKey('conv_${conv.id}'),
          title: conv.title ?? 'New Conversation',
          conversationId: conv.id,
          postHook: widget.postHook,
          isBusy: conv.onGoing,
          selected: widget.activeConversationId == conv.id,
          onSelect: widget.onHistorySelect,
          animationIndex: index,
          // Animate on initial load or when newly added via SSE
          shouldAnimate: !_hasAnimatedInitialLoad || isNewlyAdded,
        );
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: 5,
      itemBuilder: (context, index) => LibraryRow(
        title: 'Loading...',
        postHook: widget.postHook,
      ).asSkeleton(),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.triangleAlert, size: 32).iconMutedForeground(),
          const SizedBox(height: 8),
          const Text('Error loading sessions').muted.small,
          const SizedBox(height: 8),
          GhostButton(
            density: ButtonDensity.compact,
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Text('No sessions yet').muted.small,
      ),
    );
  }
}
