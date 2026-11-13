import 'package:arcane/arcane.dart';
import 'package:flutter_client/pages/expanded/mcp/forms/add_mcp_server_form.dart';

import '../../../../logics/data/helpers/general_utils.dart';
import '../../../home/home.dart';
import '../../../home/sidebar/common/header.dart';
import 'package:flutter_client/pages/expanded/mcp/main.dart';

/// A widget that displays the MCP server configuration.
///
/// This widget displays a list of configured MCP servers and allows the user
/// to add a new server.
class McpConfigView extends StatefulWidget {
  /// A callback function that is called when the user taps the "Go back" button.
  final VoidCallback onGoBack;
  final Function(String, String) showToast;

  /// Creates a new [McpConfigView] widget.
  ///
  /// The [onGoBack] parameter is required.
  const McpConfigView({
    super.key,
    required this.onGoBack,
    required this.showToast,
  });

  @override
  State<McpConfigView> createState() => _McpConfigViewState();
}

class _McpConfigViewState extends State<McpConfigView> {

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (!Toolkit.isMobile(context))
          Padding(
            padding: const EdgeInsets.all(7),
            child: SidebarHeader(
              title: 'Add MCP server',
              onBack: widget.onGoBack,
            ),
          ),
        Divider(),
        AddMcpServerForm(
          showToast: widget.showToast,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GhostButton(
            onPressed: () {
              RootShell.updateAndRefresh(
                const ValueKey('main'),
                const ExpandedMcpView(),
                'MCP',
                LucideIcons.wrench,
              );
            },
            child: const Text('View Configured Servers'),
          ),
        ),
      ],
    );
  }
}
