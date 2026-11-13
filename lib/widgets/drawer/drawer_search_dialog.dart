part of 'drawer.dart';

/// Search tasks dialog
class _SearchTasksDialog extends StatefulWidget {
  const _SearchTasksDialog();

  @override
  State<_SearchTasksDialog> createState() => _SearchTasksDialogState();
}

class _SearchTasksDialogState extends State<_SearchTasksDialog> {
  final TextEditingController _searchController = TextEditingController();
  final BaseRepository _repo = BaseRepository();
  Timer? _debounce;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialConversations() async {
    try {
      await Memory.getAllConversations(repo: _repo);
      if (mounted) {
        setState(() {
          _conversations = _repo.items.whereType<Conversation>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadInitialConversations();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final searchRepo = BaseRepository();
      await Memory.searchThreads(repo: searchRepo, query: query);
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _conversations = searchRepo.items.whereType<Conversation>().toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectConversation(Conversation conversation) {
    closeOverlay(context);
    RootShell.updateAndRefresh(
      ValueKey('main'),
      ChatUI(
        key: ValueKey(conversation.id),
        conversationId: conversation.id,
        isBusy: conversation.onGoing,
      ),
      conversation.title ?? 'Chat',
      LucideIcons.messageSquare,
      shouldShowBorder: true,
    );
  }

  void _createNewTask() {
    closeOverlay(context);
    RootShell.updateAndRefresh(
      ValueKey('main'),
      ChatUI(key: ValueKey(DateTime.now().millisecondsSinceEpoch.toString())),
      'New task',
      LucideIcons.sparkles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      padding: EdgeInsets.zero,
      content: Container(
        width: 800,
        height: 450,
        decoration: BoxDecoration(
          color: scheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                placeholder: Text('Search tasks...'),
                leading: Icon(LucideIcons.search, size: 18),
                trailing: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton.ghost(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
              ),
            ),

            const Divider(),

            // Results list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // New task option at top

                        if (_conversations.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text('Last 30 days').muted.small,
                          ),
                        ],

                        // Conversation results
                        ..._conversations.map(
                          (conv) => _SearchResultItem(
                            title: conv.title ?? 'Untitled',
                            description: conv.summary ?? "No summary generated yet",
                            conversationId: conv.id,
                            onTap: () => _selectConversation(conv),
                          ),
                        ),

                        if (_conversations.isEmpty && !_isLoading)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(child: Text('No tasks found').muted),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual search result item
class _SearchResultItem extends StatelessWidget {
  final String title;
  final String description;
  final String? conversationId;
  final IconData? icon;
  final bool isNewTask;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.title,
    required this.description,
    this.conversationId,
    this.icon,
    this.isNewTask = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Generate DiceBear avatar for conversations
    Widget leadingWidget;
    if (isNewTask) {
      leadingWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.muted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon ?? LucideIcons.plus, size: 14),
      );
    } else {
      final avatar = DiceBearBuilder(
        seed: conversationId ?? title,
        sprite: DiceBearSprite.icons,
        backgroundColor: Theme.of(context).colorScheme.background,
        radius: 6,
      ).build();
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: avatar.toImage(width: 28, height: 28),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GhostButton(
        onPressed: onTap,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(description, maxLines: 2,).small.muted
          ],
        ),
      ),
    );
  }
}
