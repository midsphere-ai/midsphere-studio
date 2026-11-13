import 'package:arcane/arcane.dart' hide SubmitButton;
import 'package:arcane/generated/arcane_shadcn/src/components/menu/dropdown_menu.dart';
import 'package:file_picker/file_picker.dart';

import '../../../logics/domain/entities/agents/settings.dart';

class AddButtonDialog extends StatefulWidget {
  final ValueNotifier<UserModelProvider?> selectedModelNotifier;
  final ValueNotifier<Set<String>> selectedAddonsNotifier;
  final ValueNotifier<Set<String>> selectedMcpsNotifier;
  final ValueNotifier<List<PlatformFile>> attachedFilesNotifier;
  final ValueNotifier<String?> selectedModeNotifier;
  final List models;
  final List addons;
  final List mcps;

  const AddButtonDialog({
    super.key,
    required this.selectedModelNotifier,
    required this.selectedAddonsNotifier,
    required this.selectedMcpsNotifier,
    required this.attachedFilesNotifier,
    required this.selectedModeNotifier,
    required this.models,
    required this.addons,
    required this.mcps,
  });

  @override
  State<AddButtonDialog> createState() => _AddButtonDialogState();
}

class _AddButtonDialogState extends State<AddButtonDialog> {
  List get _models => widget.models;
  List get _addons => widget.addons;
  List get _mcps => widget.mcps;

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      widget.attachedFilesNotifier.value = [
        ...widget.attachedFilesNotifier.value,
        ...result.files,
      ];
    }
  }

  List<MenuButton> _buildModelMenuItems() {
    if (_models.isEmpty) {
      return [const MenuButton(enabled: false, child: Text('No models found'))];
    }
    return _models.map((model) {
      return MenuButton(
        onPressed: () {
          widget.selectedModelNotifier.value = model;
          closeOverlay(context);
        },
        child: Text(model.llmModelName ?? 'Unnamed Model'),
      );
    }).toList();
  }

  List<MenuButton> _buildAddonMenuItems() {
    if (_addons.isEmpty) {
      return [const MenuButton(enabled: false, child: Text('No addons found'))];
    }
    return _addons.map((addon) {
      final isSelected = widget.selectedAddonsNotifier.value.contains(
        addon.id!,
      );
      return MenuButton(
        onPressed: () {
          final currentSelection = Set<String>.from(
            widget.selectedAddonsNotifier.value,
          );
          if (isSelected) {
            currentSelection.remove(addon.id!);
          } else {
            currentSelection.add(addon.id!);
          }
          widget.selectedAddonsNotifier.value = currentSelection;
        },
        leading: isSelected ? const Icon(LucideIcons.check) : null,
        child: Text(addon.enabledAddon.name),
      );
    }).toList();
  }

  List<MenuButton> _buildMcpMenuItems() {
    if (_mcps.isEmpty) {
      return [
        const MenuButton(enabled: false, child: Text('No MCP configs found')),
      ];
    }
    return _mcps.map((mcp) {
      final isSelected = widget.selectedMcpsNotifier.value.contains(mcp.id!);
      return MenuButton(
        onPressed: () {
          final currentSelection = Set<String>.from(
            widget.selectedMcpsNotifier.value,
          );
          if (isSelected) {
            currentSelection.remove(mcp.id!);
          } else {
            currentSelection.add(mcp.id!);
          }
          widget.selectedMcpsNotifier.value = currentSelection;
        },
        leading: isSelected ? const Icon(LucideIcons.check) : null,
        child: Text(mcp.serverName),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        IconButton.ghost(
          shape: ButtonShape.circle,
          density: ButtonDensity.iconDense,
          onPressed: () {
            showDropdown(
              anchorAlignment: Alignment.bottomLeft,
              context: context,
              builder: (context) {
                return DropdownMenu(
                  children: [
                    MenuButton(
                      onPressed: _pickFiles,
                      leading: const Icon(LucideIcons.paperclip),
                      child: const Text('Attach Files'),
                    ),
                    const MenuDivider(),
                    MenuLabel(
                      leading: const Icon(LucideIcons.hammer),
                      child: const Text('Build or create').muted,
                    ),
                    MenuButton(
                      onPressed: () {
                        widget.selectedModeNotifier.value = 'Presentation';
                        closeOverlay(context);
                      },
                      leading: const Icon(LucideIcons.presentation),
                      child: const Text('Presentation'),
                    ),
                    MenuButton(
                      onPressed: () {
                        widget.selectedModeNotifier.value =
                            'Web and mobile apps';
                        closeOverlay(context);
                      },
                      leading: const Icon(LucideIcons.code),
                      child: const Text('Web and mobile apps'),
                    ),
                    MenuButton(
                      onPressed: () {
                        widget.selectedModeNotifier.value = 'Images and videos';
                        closeOverlay(context);
                      },
                      leading: const Icon(LucideIcons.video),
                      child: const Text('Images and videos'),
                    ),
                    const MenuDivider(),
                    MenuLabel(
                      leading: const Icon(LucideIcons.settings2),
                      child: const Text('Fine-tune').muted,
                    ),
                    MenuButton(
                      subMenu: _buildModelMenuItems(),
                      leading: const Icon(LucideIcons.brain),
                      child: const Text('Models'),
                    ),
                    MenuButton(
                      leading: const Icon(LucideIcons.blocks),
                      subMenu: _buildAddonMenuItems(),
                      child: const Text('Addons'),
                    ),
                    MenuButton(
                      leading: const Icon(LucideIcons.code),
                      subMenu: _buildMcpMenuItems(),
                      child: const Text('Custom MCP'),
                    ),
                  ],
                );
              },
            );
          },
          icon: Icon(LucideIcons.settings2, size: 21),
        ),
      ],
    );
  }
}
