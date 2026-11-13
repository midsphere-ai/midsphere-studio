import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import '../../../../logics/domain/entities/agents/settings.dart';
import 'mcp_server_menu.dart';

/// A widget that displays the details of a [McpServer] in ChatGPT style.
class McpServerCard extends StatelessWidget {
  /// The [McpServer] to display.
  final UserCustomMCPConfig server;
  final Function showToast;

  /// Creates a new [McpServerCard] widget.
  ///
  /// The [server] parameter is required.
  const McpServerCard({super.key, required this.server, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard.subtle(
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                children: [
                  // Icon container with gradient background
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.serverName,
                        ),
                        if (server.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            server.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).small.muted,
                        ],
                      ],
                    ),
                  ),
                  McpServerMenu(showToast: showToast, server: server),
                ],
              ),

              const SizedBox(height: 20),

              // Details section with subtle background
              _buildDetailsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the details section with staggered animations.
  Widget _buildDetailsSection(BuildContext context) {
    final details = <Widget>[];
    int index = 0;

    void addDetail(IconData icon, String label, String value) {
      details.add(
        FadeSlideTransition(
          delay: Duration(milliseconds: 50 * index),
          slideOffset: AnimationConstants.slideFromBottom,
          child: _buildDetailItem(context, icon, label, value),
        ),
      );
      index++;
    }

    addDetail(LucideIcons.server, 'Type', server.type.toUpperCase());

    if (server.type == 'stdio') {
      if (server.command != null) {
        addDetail(LucideIcons.terminal, 'Command', server.command!);
      }
      if (server.arguments != null) {
        addDetail(LucideIcons.listOrdered, 'Arguments', server.arguments!);
      }
      if (server.env != null) {
        addDetail(LucideIcons.braces, 'Environment', server.env!);
      }
    } else {
      if (server.url != null) {
        addDetail(LucideIcons.link, 'URL', server.url!);
      }
    }

    if (server.timeout != null) {
      addDetail(LucideIcons.timer, 'Timeout', '${server.timeout}s');
    }
    if (server.sseReadTimeout != null) {
      addDetail(LucideIcons.timer, 'SSE Read Timeout', '${server.sseReadTimeout}s');
    }
    if (server.clientSessionTimeoutSeconds != null) {
      addDetail(LucideIcons.timer, 'Client Session Timeout', '${server.clientSessionTimeoutSeconds}s');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.map((detail) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: detail,
      )).toList(),
    );
  }

  /// Builds a detail item row with icon and text
  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton.secondary(
          icon: Icon(icon, size: 16),
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
              ).small,
              const SizedBox(height: 4),
              Text(
                value,
              ).mono.small.muted,
            ],
          ),
        ),
      ],
    );
  }
}
