import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/agents/settings.dart';
import 'package:flutter_client/pages/expanded/mcp/components/mcp_server_card.dart';

import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/builders/item_builder_list.dart';

class McpServerList extends StatelessWidget {
  final ScrollController controller;
  final Function showToast;
  const McpServerList({super.key, required this.controller, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return ItemBuilderBloc(
      blocKey: 'mcpServerList',
      paginated: true,
      dataSource: (repo) => Memory.getMcpConfigs(repo: repo),
      onDataEmpty: "No MCP servers found",
      onError: "Error fetching MCP servers",
      placeHolderItems: [
        UserCustomMCPConfig(
          userId: 1,
          dateUpdated: DateTime.now(),
          serverName: 'Primary Server',
          type: 'stdio',
          command: './start.sh',
          description: 'The main production server.',
        ).toJson(),
        UserCustomMCPConfig(
          userId: 1,
          dateUpdated: DateTime.now(),
          serverName: 'Dev Server',
          type: 'stdio',
          command: './dev.sh',
          arguments: '--debug',
          env: 'NODE_ENV=development',
          description: 'Development and testing server.',
        ).toJson(),
      ],
      item: (data) {
        if (data is UserCustomMCPConfig) {
          return McpServerCard(showToast: showToast, server: data);
        }
        return McpServerCard(
          showToast: showToast,
          server: UserCustomMCPConfig(
            userId: 1,
            dateUpdated: DateTime.now(),
            serverName: data['server_name'],
            type: data['server_type'] ?? 'stdio',
            command: data['command'],
            arguments: data['arguments'],
            env: data['env'],
            description: data['description'],
            url: data['url'],
            timeout: data['timeout'],
            sseReadTimeout: data['sse_read_timeout'],
            clientSessionTimeoutSeconds:
                (data['client_session_timeout_seconds'] as num?)?.toDouble(),
          ),
        );
      },
    );
  }
}
