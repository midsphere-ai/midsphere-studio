import 'dart:convert';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/mcp_server.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/widgets/texts/settings_text_field.dart';

import '../main.dart';
import '../../../home/home.dart';

enum McpServerType {
  stdio("Stdio", "stdio"),
  sse("SSE", "sse"),
  streamableHttp("Streamable HTTP", "streamable-http");

  final String label;
  final String id;
  const McpServerType(this.label, this.id);
}

class EnvVarEntry {
  final TextEditingController keyController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// A form for adding a new MCP server.
///
/// This widget displays a form with fields for the server name, command,
/// arguments, environment variables, and description. When the user saves
/// the form, the [onSave] callback is called with the new [McpServer] object.
class AddMcpServerForm extends StatefulWidget {
  /// A callback function that is called when the server is successfully added.
  final VoidCallback? onSuccess;
  final Function(String, String) showToast;

  /// Creates a new [AddMcpServerForm] widget.
  const AddMcpServerForm({super.key, this.onSuccess, required this.showToast});

  @override
  State<AddMcpServerForm> createState() => _AddMcpServerFormState();
}

class _AddMcpServerFormState extends State<AddMcpServerForm> {
  McpServerType _selectedType = McpServerType.stdio;

  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _argsController;
  final List<EnvVarEntry> _envVars = [];
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late final TextEditingController _timeoutController;
  late final TextEditingController _sseReadTimeoutController;
  late final TextEditingController _clientSessionTimeoutController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _commandController = TextEditingController();
    _argsController = TextEditingController();
    _descriptionController = TextEditingController();
    _urlController = TextEditingController();
    _timeoutController = TextEditingController();
    _sseReadTimeoutController = TextEditingController();
    _clientSessionTimeoutController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    for (var element in _envVars) {
      element.dispose();
    }
    _descriptionController.dispose();
    _urlController.dispose();
    _timeoutController.dispose();
    _sseReadTimeoutController.dispose();
    _clientSessionTimeoutController.dispose();
    super.dispose();
  }

  void _addEnvVar() {
    setState(() {
      _envVars.add(EnvVarEntry());
    });
  }

  void _removeEnvVar(EnvVarEntry entry) {
    setState(() {
      _envVars.remove(entry);
      entry.dispose();
    });
  }

  /// Handles the save button press.
  ///
  /// This method creates a new [McpServer] object from the form fields
  /// and calls the [onSave] callback.
  void _handleSave() async {
    if (_nameController.text.isEmpty) {
      widget.showToast('Error', 'Server name is required.');
      return;
    }

    if (_selectedType == McpServerType.stdio &&
        _commandController.text.isEmpty) {
      widget.showToast('Error', 'Command is required for Stdio servers.');
      return;
    }

    if ((_selectedType == McpServerType.sse ||
            _selectedType == McpServerType.streamableHttp) &&
        _urlController.text.isEmpty) {
      widget.showToast('Error', 'URL is required for SSE/HTTP servers.');
      return;
    }

    String? envJson;
    if (_selectedType == McpServerType.stdio) {
      final Map<String, String> envMap = {};
      for (var entry in _envVars) {
        if (entry.keyController.text.isNotEmpty) {
          envMap[entry.keyController.text] = entry.valueController.text;
        }
      }
      if (envMap.isNotEmpty) {
        envJson = jsonEncode(envMap);
      }
    }

    try {
      await Memory.registerMcpConfig(
        serverName: _nameController.text,
        serverType: _selectedType.id,
        command: _selectedType == McpServerType.stdio
            ? _commandController.text
            : null,
        arguments: _selectedType == McpServerType.stdio
            ? _argsController.text
            : null,
        env: envJson,
        description: _descriptionController.text,
        url:
            (_selectedType == McpServerType.sse ||
                _selectedType == McpServerType.streamableHttp)
            ? _urlController.text
            : null,
        timeout: int.tryParse(_timeoutController.text),
        sseReadTimeout: int.tryParse(_sseReadTimeoutController.text),
        clientSessionTimeoutSeconds:
            _selectedType == McpServerType.streamableHttp
                ? double.tryParse(_clientSessionTimeoutController.text)
                : null,
      );
      widget.showToast('Success', 'MCP server registered successfully.');
      _clearControllers();
      widget.onSuccess?.call();
      RootShell.updateAndRefresh(
        const ValueKey('main'),
        ExpandedMcpView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
        'Configured MCP servers',
        LucideIcons.wrench,
      );
    } catch (e) {
      widget.showToast('Error', 'Failed to register MCP server. $e');
    }
    closeOverlay(context);
  }

  void _clearControllers() {
    _nameController.clear();
    _commandController.clear();
    _argsController.clear();
    for (var element in _envVars) {
      element.dispose();
    }
    _envVars.clear();
    setState(() {});
    _descriptionController.clear();
    _urlController.clear();
    _timeoutController.clear();
    _sseReadTimeoutController.clear();
    _clientSessionTimeoutController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Select<McpServerType>(
            value: _selectedType,
            constraints: BoxConstraints(minWidth: 600),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
            itemBuilder: (context, item) => Text(item.label),
            popup: SelectPopup(
              items: SelectItemList(
                children: McpServerType.values
                    .map(
                      (e) => SelectItemButton(value: e, child: Text(e.label)),
                    )
                    .toList(),
              ),
            ).call,
            placeholder: const Text("Select Server Type"),
          ),
        ),
        SettingsTextField(
          controller: _nameController,
          icon: LucideIcons.server,
          label: 'Server Name',
        ),
        if (_selectedType == McpServerType.stdio) ...[
          SettingsTextField(
            controller: _commandController,
            icon: LucideIcons.terminal,
            label: 'Command',
          ),
          SettingsTextField(
            controller: _argsController,
            icon: LucideIcons.listOrdered,
            label: 'Arguments',
            isTextArea: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Environment Variables',
            ),
          ),
          ..._envVars.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.keyController,
                      placeholder: const Text("Key"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: entry.valueController,
                      placeholder: const Text("Value"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    onPressed: () => _removeEnvVar(entry),
                    density: ButtonDensity.compact,
                    child: const Icon(LucideIcons.trash).iconMutedForeground(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlineButton(
              onPressed: _addEnvVar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.plus, size: 16),
                  const SizedBox(width: 8),
                  const Text("Add Environment Variable"),
                ],
              ),
            ),
          ),
        ],
        if (_selectedType == McpServerType.sse ||
            _selectedType == McpServerType.streamableHttp) ...[
          SettingsTextField(
            controller: _urlController,
            icon: LucideIcons.link,
            label: 'URL',
          ),
          SettingsTextField(
            controller: _timeoutController,
            icon: LucideIcons.timer,
            label: 'Timeout (seconds)',
          ),
          SettingsTextField(
            controller: _sseReadTimeoutController,
            icon: LucideIcons.timer,
            label: 'SSE Read Timeout (seconds)',
          ),
        ],
        if (_selectedType == McpServerType.streamableHttp) ...[
          SettingsTextField(
            controller: _clientSessionTimeoutController,
            icon: LucideIcons.timer,
            label: 'Client Session Timeout (seconds)',
          ),
        ],
        SettingsTextField(
          controller: _descriptionController,
          icon: LucideIcons.text,
          label: 'Description',
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            onPressed: _handleSave,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Text('Add Server').bold],
            ),
          ),
        ),
      ],
    );
  }
}
