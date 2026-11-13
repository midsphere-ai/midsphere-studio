import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/domain/entities/memory/conversation/base.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';

import '../../../../widgets/builders/item_builder_list.dart';
import 'thread.dart';

/// Expanded chat history view with search support and pagination.
class ExpandedChatHistory extends StatefulWidget {
  final String? searchQuery;

  const ExpandedChatHistory({
    super.key,
    this.searchQuery,
  });

  @override
  State<ExpandedChatHistory> createState() => _ExpandedChatHistoryState();
}

class _ExpandedChatHistoryState extends State<ExpandedChatHistory> {
  /// Mock conversations for skeleton loading state.
  final _placeholderConversations = [
    Conversation(
      id: "1",
      title: "Sample conversation title here",
      summary: "This is a sample summary for the conversation placeholder",
      dateCreated: DateTime.now(),
      user: 1,
      space: null,
      onGoing: false,
      hasCompleted: true,
      hasError: false,
      requiresUserInput: false,
      cancellationRequested: false,
    ),
    Conversation(
      id: "2",
      title: "Another conversation title",
      summary: "Another sample summary text for loading",
      dateCreated: DateTime.now(),
      user: 1,
      space: null,
      onGoing: false,
      hasCompleted: true,
      hasError: false,
      requiresUserInput: false,
      cancellationRequested: false,
    ),
    Conversation(
      id: "3",
      title: "Third conversation placeholder",
      summary: "Summary text for the third placeholder item",
      dateCreated: DateTime.now(),
      user: 1,
      space: null,
      onGoing: false,
      hasCompleted: true,
      hasError: false,
      requiresUserInput: false,
      cancellationRequested: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isSearching =
        widget.searchQuery != null && widget.searchQuery!.isNotEmpty;

    return SingleChildScrollView(
      child: ItemBuilderBloc(
        blocKey: isSearching
            ? 'chatHistorySearch_${widget.searchQuery}'
            : 'chatHistory',
        paginated: true,
        dataSource: isSearching
            ? (repo) => Memory.searchThreads(repo: repo, query: widget.searchQuery!)
            : (repo) => Memory.getAllConversations(repo: repo),
        onDataEmpty: isSearching
            ? 'No conversations match "${widget.searchQuery}"'
            : 'No conversations yet',
        onError: 'Error fetching conversations',
        placeHolderItems: _placeholderConversations,
        item: (data) {
          return ThreadCard(
            key: ValueKey(data.id),
            conversationId: data.id,
            title: data.title ?? 'Untitled Conversation',
            description: data.summary ?? '',
            timeAgoString: Toolkit.formatTimeAgoFull(
              data.dateCreated.millisecondsSinceEpoch,
            ),
            conversation: data,
          );
        },
      ),
    );
  }
}
