import 'dart:convert';

import 'package:arcane/arcane.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../../logics/data/global_logics.dart';
import '../../widgets/backgrounds/constrained_box.dart';
import '../../widgets/backgrounds/dividers.dart';
import 'common/body_widgets/code_block_content.dart';
import 'common/body_widgets/diff_viewer_content.dart';
import 'common/body_widgets/error_content.dart';
import 'common/body_widgets/plan_viewer_content.dart';
import 'common/body_widgets/table_content.dart';
import 'common/body_widgets/terminal_content.dart';
import 'manager.dart';
import 'messages/components/step.dart';
import 'messages/components/task.dart';
import 'messages/components/user.dart';

/// A demo page showcasing all chat UI components with sample data.
/// Navigate via the palette icon in the sidebar bottom bar.
class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  // Track collapsed sections
  final Map<String, bool> _collapsedSections = {};

  // Mock chat controller for BotMessageBubble
  late final InMemoryChatController _mockController;

  @override
  void initState() {
    super.initState();
    _mockController = InMemoryChatController();
    // Add some mock messages so BotMessageBubble doesn't return early
    _mockController.insertMessage(
      TextMessage(
        id: 'mock-1',
        authorId: ChatUsers.agent.id,
        createdAt: DateTime.now().toUtc(),
        text: '',
        metadata: {},
      ),
      animated: false,
    );
  }

  @override
  void dispose() {
    _mockController.dispose();
    super.dispose();
  }

  // Track which content card is shown in the process panel
  int _activeContentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Layout similar to ChatUI in base.dart with sidemenu
    return Row(
      children: [
        // Main content area (Chat messages)
        Expanded(
          flex: 3,
          child: LimitedWindowBox(
            customWidth: DataConstants.pageWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(LucideIcons.palette, size: 24, color: colors.primary),
                      const SizedBox(width: 12),
                      Text('Chat UI Component Gallery').bold.large,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Message bubbles (main area) and process panel content cards (sidemenu)').muted.small,
                  const SizedBox(height: 24),

                  // User Messages Section
                  _buildSection(
                    'user_messages',
                    'User Messages',
                    LucideIcons.messageCircle,
                    _buildUserMessagesSection(),
                  ),
                  const SizedBox(height: 32),

                  // Bot Message Variations Section
                  _buildSection(
                    'bot_messages',
                    'Bot Message Variations',
                    LucideIcons.bot,
                    _buildBotMessagesSection(),
                  ),
                  const SizedBox(height: 32),

                  // Step Timeline Section
                  _buildSection(
                    'step_timeline',
                    'Step Timeline',
                    LucideIcons.gitBranch,
                    _buildStepTimelineSection(),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
        // Process Panel / Sidemenu (like in base.dart)
        DottedVerticalDivider(color: colors.border),
        Container(
          width: 380,
          color: colors.sidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Process panel header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(LucideIcons.monitor, size: 16),
                    const SizedBox(width: 8),
                    Text('Agent computer').small,
                    const Spacer(),
                    Icon(LucideIcons.minimize2, size: 16).iconMutedForeground(),
                  ],
                ),
              ),
              // Content card selector
              _buildContentCardSelector(),
              const SizedBox(height: 8),
              // Active content card display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActiveContentCard(),
                ),
              ),
              // Navigation and objective
              _buildProcessPanelFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCardSelector() {
    final colors = Theme.of(context).colorScheme;
    final contentTypes = [
      'Terminal',
      'Code Editor',
      'Diff Viewer',
      'Table',
      'Plan Viewer',
      'Error',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: contentTypes.asMap().entries.map((entry) {
          final isActive = entry.key == _activeContentIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeContentIndex = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? colors.primary : colors.muted.withValues(alpha: 0.3),
                  borderRadius: Theme.of(context).borderRadiusSm,
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? colors.primaryForeground : colors.foreground,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveContentCard() {
    switch (_activeContentIndex) {
      case 0:
        return TerminalContent(
          rawData: jsonEncode([_sampleTerminalOutput]),
          arguments: {'command': 'git log --oneline -5'},
          animate: false,
        );
      case 1:
        return CodeBlockContent(code: _samplePythonCode, animate: false);
      case 2:
        return DiffViewerContent(
          arguments: _sampleDiffData,
          fallbackBuilder: () => const Text('Failed to load diff'),
          animate: false,
        );
      case 3:
        return TableContent(
          rawData: jsonEncode(_sampleTableData),
          fallbackBuilder: () => const Text('Failed to load table'),
          animate: false,
        );
      case 4:
        return PlanViewerContent(
          rawData: jsonEncode(_samplePlanData),
          fallbackBuilder: () => const Text('Failed to load plan'),
          animate: false,
        );
      case 5:
        return ErrorContent(
          errorMessage: 'Connection refused: Unable to reach the API server at api.example.com:443',
          animate: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProcessPanelFooter() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: Theme.of(context).borderRadiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Objective row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(LucideIcons.check, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Implementing API retry logic', maxLines: 1, overflow: TextOverflow.ellipsis).small,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2 / 4', style: TextStyle(color: colors.mutedForeground, fontSize: 12)),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronUp, size: 16, color: colors.mutedForeground),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String key,
    String title,
    IconData icon,
    Widget content,
  ) {
    final isCollapsed = _collapsedSections[key] ?? false;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        GestureDetector(
          onTap: () {
            setState(() {
              _collapsedSections[key] = !isCollapsed;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: Theme.of(context).borderRadiusMd,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title).bold),
                Icon(
                  isCollapsed ? LucideIcons.chevronRight : LucideIcons.chevronDown,
                  size: 20,
                  color: colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        // Section Content
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: content,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ===== User Messages Section =====

  Widget _buildUserMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubsectionHeader('Plain Text Message'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: UserMessageBubble(
            message: TextMessage(
              id: 'demo-1',
              authorId: ChatUsers.user.id,
              createdAt: DateTime.now().toUtc(),
              text: 'Can you help me implement a retry mechanism for API calls with exponential backoff?',
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSubsectionHeader('Message with File Attachments'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: UserMessageBubble(
            message: TextMessage(
              id: 'demo-2',
              authorId: ChatUsers.user.id,
              createdAt: DateTime.now().toUtc(),
              text: 'Here are the files I mentioned for the refactoring task.',
              metadata: {
                'files': [
                  {
                    'id': 'file-1',
                    'name': 'api_client.dart',
                    'mime_type': 'text/x-dart',
                    'size': 4250,
                    'url': '/files/api_client.dart',
                  },
                  {
                    'id': 'file-2',
                    'name': 'screenshot.png',
                    'mime_type': 'image/png',
                    'size': 125000,
                    'url': '/files/screenshot.png',
                  },
                ],
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSubsectionHeader('Loading/Placeholder State'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: UserMessageBubble(
            message: TextMessage(
              id: 'demo-3',
              authorId: ChatUsers.user.id,
              createdAt: DateTime.now().toUtc(),
              text: 'Loading...',
              metadata: {'status': 'PLACEHOLDER'},
            ),
          ),
        ),
      ],
    );
  }

  // ===== Bot Message Variations Section =====

  Widget _buildBotMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Placeholder/Loading State
        _buildSubsectionHeader('1. Placeholder Loading State'),
        Text('metadata: {\'status\': \'PLACEHOLDER\'}').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-placeholder',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {'status': 'PLACEHOLDER'},
          ),
        ),
        const SizedBox(height: 24),

        // 2. Thinking/Start State
        _buildSubsectionHeader('2. Thinking State'),
        Text('metadata: {\'status\': \'START\'}').mono.xSmall.muted,
        const SizedBox(height: 8),
        _buildThinkingDemo(),
        const SizedBox(height: 24),

        // 3. MCP Message with markdown
        _buildSubsectionHeader('3. MCP Message (Markdown Response)'),
        Text('origin_tool_call contains "mcp_message"').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-mcp-1',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'origin_tool_call': {
                'function': {
                  'name': 'mcp_message',
                  'arguments': jsonEncode({
                    'text': '''## Analysis Complete

I've analyzed your codebase and found the following:

1. **API Client** - The current implementation lacks retry logic
2. **Error Handling** - Errors are not propagated correctly
3. **Timeout** - No timeout configuration exists

### Recommended Changes

```dart
class ApiClient {
  Future<Response> get(String path) async {
    return await retry(() => http.get(path));
  }
}
```

Let me know if you'd like me to implement these changes.''',
                    'follow_up_questions': [
                      'Should I add retry logic to all HTTP methods?',
                      'What timeout duration would you prefer?',
                      'Should errors be logged to a service?',
                    ],
                  }),
                },
              },
            },
          ),
        ),
        const SizedBox(height: 24),

        // 4. MCP Message with suggested action (review_file)
        _buildSubsectionHeader('4. MCP Message with Review File Action'),
        Text('suggested_action: "review_file"').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-mcp-review',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'origin_tool_call': {
                'function': {
                  'name': 'mcp_message',
                  'arguments': jsonEncode({
                    'text': 'I\'ve made changes to the file `api_client.dart`. Please review the modifications before I proceed.',
                    'suggested_action': 'review_file',
                  }),
                },
              },
            },
          ),
        ),
        const SizedBox(height: 24),

        // 5. MCP Message with confirm action
        _buildSubsectionHeader('5. MCP Message with Confirmation'),
        Text('suggested_action: "confirm"').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-mcp-confirm',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'origin_tool_call': {
                'function': {
                  'name': 'mcp_message',
                  'arguments': jsonEncode({
                    'text': 'I\'m about to delete the old backup files. This action cannot be undone.',
                    'suggested_action': 'confirm',
                  }),
                },
              },
            },
          ),
        ),
        const SizedBox(height: 24),

        // 6. Tool Call Message
        _buildSubsectionHeader('6. Tool Call Message'),
        Text('origin_tool_call with function name').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-tool-1',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'tool_name': 'file',
              'origin_tool_call': {
                'function': {
                  'name': 'read_file',
                  'arguments': jsonEncode({
                    'brief': 'Reading api_client.dart',
                    'file_path': 'lib/services/api_client.dart',
                  }),
                },
              },
            },
          ),
        ),
        const SizedBox(height: 24),

        // 7. Pre-Tool Call (Computer Use)
        _buildSubsectionHeader('7. Pre-Tool Call (Computer/Browser Use)'),
        Text('tool_calls with computer_use or browser_use').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-pretool',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'tool_calls': [
                {
                  'data': {
                    'function': {
                      'name': 'mcp_computer_use',
                      'arguments': jsonEncode({
                        'brief': 'Taking screenshot of current screen',
                        'action': 'screenshot',
                      }),
                    },
                  },
                },
              ],
            },
          ),
        ),
        const SizedBox(height: 24),

        // 8. Error Message
        _buildSubsectionHeader('8. Error Message'),
        Text('id contains "error-"').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'error-bot-1',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: 'Connection refused: Unable to reach the API server at api.example.com:443',
            metadata: {},
          ),
        ),
        const SizedBox(height: 24),

        // 9. Plan Tool Message
        _buildSubsectionHeader('9. Plan Tool Message'),
        Text('mcp_update_plan or mcp_advance_plan').mono.xSmall.muted,
        const SizedBox(height: 8),
        BotMessageBubble(
          index: 0,
          controller: _mockController,
          message: TextMessage(
            id: 'bot-plan',
            authorId: ChatUsers.agent.id,
            createdAt: DateTime.now().toUtc(),
            text: '',
            metadata: {
              'tool_name': 'plan',
              'data': {'success': true},
              'origin_tool_call': {
                'function': {
                  'name': 'mcp_advance_plan',
                  'arguments': jsonEncode({
                    'brief': 'Advancing to phase 2: Implementation',
                  }),
                },
              },
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingDemo() {
    // Create a special controller for thinking state
    final thinkingController = InMemoryChatController();
    final thinkingMessage = TextMessage(
      id: 'bot-thinking',
      authorId: ChatUsers.agent.id,
      createdAt: DateTime.now().toUtc(),
      text: '',
      metadata: {'status': 'START'},
    );
    thinkingController.insertMessage(thinkingMessage, animated: false);

    return BotMessageBubble(
      index: 0,
      controller: thinkingController,
      message: thinkingMessage,
    );
  }

  // ===== Step Timeline Section =====

  Widget _buildStepTimelineSection() {
    final steps = [
      {
        'response': 'Analyzing the codebase structure and identifying key files...',
      },
      {
        'response': 'Found 3 files that need modification: `api_client.dart`, `network_service.dart`, and `retry_policy.dart`.',
      },
      {
        'origin_tool_call': {
          'function': {
            'name': 'read_file',
            'arguments': jsonEncode({
              'brief': 'Reading api_client.dart to understand current implementation',
            }),
          },
        },
      },
      {
        'response': 'Implementing exponential backoff with jitter for optimal retry behavior.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        borderRadius: Theme.of(context).borderRadiusMd,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < steps.length; i++)
            StepMessage(
              message: steps[i],
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              isActive: i == 2, // Third step is active
              animationIndex: i,
            ),
        ],
      ),
    );
  }

  Widget _buildSubsectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title).small.muted,
    );
  }
}

// ===== Sample Data =====

const String _samplePythonCode = '''import asyncio
from typing import Optional
from dataclasses import dataclass

@dataclass
class Task:
    id: str
    name: str
    priority: int = 0
    completed: bool = False

class TaskManager:
    def __init__(self):
        self._tasks: dict[str, Task] = {}

    async def add_task(self, name: str, priority: int = 0) -> Task:
        task = Task(id=str(len(self._tasks)), name=name, priority=priority)
        self._tasks[task.id] = task
        return task

    def get_pending(self) -> list[Task]:
        return [t for t in self._tasks.values() if not t.completed]''';

const String _sampleTerminalOutput = '''a89b22d feat: Improve sidemenu animations and fix UI issues
88e810f feat: Added logging to chat
186c6d4 [feat] migrated from websockets to SSE
80a9da1 feat: Migration from sockets to SSE
e93cb51 [feat] Fixed issues with pagination''';

const Map<String, dynamic> _sampleTableData = {
  'columns': ['Agent', 'Model', 'Status', 'Tokens', 'Duration'],
  'rows': [
    ['Research Agent', 'Claude 3.5', 'Completed', '12,450', '2.3s'],
    ['Code Agent', 'GPT-4', 'Running', '8,721', '1.8s'],
    ['Analysis Agent', 'Claude 3.5', 'Queued', '-', '-'],
    ['Summary Agent', 'Gemini Pro', 'Failed', '3,201', '0.9s'],
  ],
};

const Map<String, dynamic> _sampleDiffData = {
  'file_path': 'lib/services/api_client.dart',
  'edits': [
    {
      'old_text': '''class ApiClient {
  final String baseUrl;

  Future<Response> get(String path) async {
    return http.get(Uri.parse('\$baseUrl\$path'));
  }
}''',
      'new_text': '''class ApiClient {
  final String baseUrl;
  final Duration timeout;

  ApiClient({required this.baseUrl, this.timeout = const Duration(seconds: 30)});

  Future<Response> get(String path, {Map<String, String>? headers}) async {
    return http.get(
      Uri.parse('\$baseUrl\$path'),
      headers: {'Authorization': 'Bearer \${_getToken()}', ...?headers},
    ).timeout(timeout);
  }

  String _getToken() => SecureStorage.instance.get('auth_token') ?? '';
}''',
    },
  ],
};

const Map<String, dynamic> _samplePlanData = {
  'message': '''# Implementation Plan

## Phase 1: Research
✅ Analyze existing codebase
✅ Identify integration points
- Status: completed

## Phase 2: Development
🔄 Implement core features ← CURRENT
- Status: in_progress
- Started: 2 minutes ago

## Phase 3: Testing
⭕ Write unit tests
⭕ Integration testing
- Status: pending

## Phase 4: Deployment
⭕ Stage deployment
⭕ Production release
- Status: pending''',
  'metadata': {
    'current_phase': 'Development',
    'total_phases': '4',
    'completed_phases': '1',
  },
  'success': false,
};
