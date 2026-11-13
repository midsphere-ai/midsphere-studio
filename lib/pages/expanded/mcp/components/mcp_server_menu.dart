import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/menu/dropdown_menu.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/domain/entities/agents/settings.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter/foundation.dart';

import '../../../home/home.dart';
import '../main.dart'; // For kDebugMode

enum _ToastType { success, danger }

class McpServerMenu extends StatelessWidget {
  final Function showToast;
  final UserCustomMCPConfig server;

  const McpServerMenu({super.key, required this.server, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return IconButton.ghost(
      icon: Icon(LucideIcons.ellipsis),
      density: ButtonDensity.dense,
      onPressed: () => _showOptionsMenu(context),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showDropdown(
      context: context,
      builder: (context) {
        return McpServerMenuDropdown(showToast: showToast, server: server);
      },
    ).future.then((_) {
      if (kDebugMode) {
      }
    });
  }
}

class McpServerMenuDropdown extends StatefulWidget {
  final Function showToast;
  final UserCustomMCPConfig server;

  const McpServerMenuDropdown({super.key, required this.server, required this.showToast});

  @override
  State<McpServerMenuDropdown> createState() => _McpServerMenuDropdownState();
}

class _McpServerMenuDropdownState extends State<McpServerMenuDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      children: [
        MenuButton(
          leading: Icon(LucideIcons.trash2),
          onPressed: () async {
            try{
              final response = await _removeServer(context);
              widget.showToast("Success", "MCP has been removed");
            } catch(e){
              widget.showToast("Error", "MCP has not deleted");
            }
            RootShell.updateAndRefresh(
              const ValueKey('main'),
              ExpandedMcpView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
              'Configured MCP servers',
              LucideIcons.wrench,
            );
            closeOverlay(context);
          },
          child: const Text('Remove Server'),
        ),
      ],
    );
  }

  Future<void> _removeServer(BuildContext context) async {
    final res = await Memory.unregisterMcpConfig(configId: widget.server.id);

    if (context.mounted) {
      if (res.success) {
        _showToast(
          context:   RootShell.context(ValueKey('main')),
          type: _ToastType.success,
          title: 'Server Removed',
          message: '${widget.server.serverName} has been removed.',
        );
        RootShell.updateAndRefresh(
          const ValueKey('main'),
          ExpandedMcpView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
          'Configured MCP servers',
          LucideIcons.wrench,
        );
      } else {
        _showToast(
          context: RootShell.context(ValueKey('main')),
          type: _ToastType.danger,
          title: 'Error',
          message: res.message ?? 'An unknown error occurred.',
        );
      }
    }
  }

  void _showToast({
    required BuildContext context,
    required _ToastType type,
    required String title,
    required String message,
  }) {
    Color indicatorColor = switch (type) {
      _ToastType.success => Colors.green,
      _ToastType.danger => Colors.red,
    };

    showToast(
      context: context,
      location: ToastLocation.topCenter,
      builder: (context, overlay) {
        return SurfaceCard(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: indicatorColor),
                const Gap(12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Basic(
                      title: Text(title),
                      subtitle: Text(message),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },    );
  }
}
