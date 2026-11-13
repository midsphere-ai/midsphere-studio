import 'package:arcane/arcane.dart' hide SubmitButton;
import 'package:dio/dio.dart';
import 'package:flutter_client/widgets/platform/image_file.dart'
    if (dart.library.io) 'package:flutter_client/widgets/platform/image_file_io.dart'
    if (dart.library.html) 'package:flutter_client/widgets/platform/image_file_web.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_client/pages/chat/input/add_button_dialog.dart';
import 'package:flutter_client/pages/chat/input/submit.dart';

import '../../../logics/data/global_logics.dart';
import '../../../logics/data/providers/incognito_provider.dart';
import '../../../logics/data/repositories/authentication.dart';
import '../../../logics/domain/entities/agents/settings.dart';
import '../../../logics/domain/entities/base/repo.dart';
import '../../../logics/domain/entities/memory/misc/schemas.dart';
import '../../../logics/domain/usecases/memory/memory_usecase.dart';

/// Animated file thumbnail widget with entrance/exit animations
class _AnimatedFileThumbnail extends StatefulWidget {
  final PlatformFile file;
  final int index;
  final VoidCallback onRemove;

  const _AnimatedFileThumbnail({
    super.key,
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  State<_AnimatedFileThumbnail> createState() => _AnimatedFileThumbnailState();
}

class _AnimatedFileThumbnailState extends State<_AnimatedFileThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Staggered entrance based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRemove() async {
    await _controller.reverse();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final file = widget.file;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(file.extension?.toLowerCase());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.muted.withOpacity(0.3),
              borderRadius: Theme.of(context).borderRadiusXxl,
              border: Border.all(color: colors.muted, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isImage && (file.bytes != null || file.path != null))
                  Expanded(
                    child: ClipRRect(
                      borderRadius: Theme.of(context).borderRadiusMd,
                      child: file.bytes != null
                          ? Image.memory(
                              file.bytes!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            )
                          : buildImageFile(
                              file.path!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                    ),
                  )
                else ...[
                  Icon(
                    _getFileIcon(file.extension ?? ''),
                    size: 28,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      file.name.length > 10
                          ? '${file.name.substring(0, 7)}...'
                          : file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ).xSmall.muted,
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _handleRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.background.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return LucideIcons.fileImage;
      case 'doc':
      case 'docx':
        return LucideIcons.fileText;
      case 'xls':
      case 'xlsx':
        return LucideIcons.fileSpreadsheet;
      case 'zip':
      case 'rar':
        return LucideIcons.fileArchive;
      default:
        return LucideIcons.file;
    }
  }
}

/// Helper class for chip data
class _ChipData {
  final String key;
  final IconData icon;
  final String label;
  final VoidCallback onRemove;
  final int index;

  _ChipData({
    required this.key,
    required this.icon,
    required this.label,
    required this.onRemove,
    required this.index,
  });
}

/// Animated selection chip with entrance animation
class _AnimatedChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onRemove;
  final int index;

  const _AnimatedChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onRemove,
    required this.index,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered entrance
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRemove() async {
    await _controller.reverse();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.card.withAlpha(200),
          borderRadius: Theme.of(context).borderRadiusXxl,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 12),
            const SizedBox(width: 6),
            Text(widget.label).xSmall,
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _handleRemove,
              child: Icon(LucideIcons.x, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AgentInputBar extends StatefulWidget {
  final String? placeHolder;
  final Function? onClicked;
  final Function? updateDefaultValue;

  static final Map<Key, _AgentInputBarState> _instances = {};
  const AgentInputBar({
    super.key,
    this.placeHolder,
    this.onClicked,
    this.updateDefaultValue,
  });

  @override
  State<AgentInputBar> createState() => _AgentInputBarState();

  static void updateText(Key key, String text) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!.updateText(text);
  }
}

class _AgentInputBarState extends State<AgentInputBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  late final ValueNotifier<UserModelProvider?> _selectedModelNotifier;
  late final ValueNotifier<Set<String>> _selectedAddonsNotifier;
  late final ValueNotifier<Set<String>> _selectedMcpsNotifier;
  late final ValueNotifier<List<PlatformFile>> _attachedFilesNotifier;
  late final ValueNotifier<String?> _selectedModeNotifier;

  // Cached data for AddButtonDialog - fetched once
  List _models = [];
  List _addons = [];
  List _mcps = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _selectedModelNotifier = ValueNotifier(null);
    _selectedAddonsNotifier = ValueNotifier({});
    _selectedMcpsNotifier = ValueNotifier({});
    _attachedFilesNotifier = ValueNotifier([]);
    _selectedModeNotifier = ValueNotifier(null);
    if (widget.key != null) {
      AgentInputBar._instances[widget.key!] = this;
    }
    _fetchAddButtonData();
  }

  Future<void> _fetchAddButtonData() async {
    try {
      final modelsRepo = BaseRepository();
      final addonsRepo = BaseRepository();
      final mcpsRepo = BaseRepository();

      final results = await Future.wait([
        Memory.getLlmProviders(repo: modelsRepo),
        Memory.getUserAddons(repo: addonsRepo),
        Memory.getMcpConfigs(repo: mcpsRepo),
      ]);

      if (mounted) {
        setState(() {
          _models = results[0].items;
          _addons = results[1].items;
          _mcps = results[2].items;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _selectedModelNotifier.dispose();
    _selectedAddonsNotifier.dispose();
    _selectedMcpsNotifier.dispose();
    _attachedFilesNotifier.dispose();
    _selectedModeNotifier.dispose();
    super.dispose();
  }

  void updateText(String text) {
    setState(() {
      _controller.text = text;
    });
  }

  int index = 0;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Check if we have any attachments or selections
    final hasFiles = _attachedFilesNotifier.value.isNotEmpty;
    final hasAddons = _selectedAddonsNotifier.value.isNotEmpty;
    final hasMcps = _selectedMcpsNotifier.value.isNotEmpty;
    final hasModel = _selectedModelNotifier.value != null;
    final hasMode = _selectedModeNotifier.value != null;
    final hasExtras = hasFiles || hasAddons || hasMcps || hasModel || hasMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // File thumbnails above the input bar
        _buildFileThumbnails(),
        // Main input container with animated focus border
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.card,
            borderRadius: Theme.of(context).borderRadiusXxl,
            border: Border.all(
              color: _focusNode.hasFocus ? colors.primary : colors.muted,
              width: _focusNode.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection chips (model, addons, MCPs) - inside input bar
              _buildSelectionChips(),
              // Main input row
              _buildTextField(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileThumbnails() {
    return ValueListenableBuilder<List<PlatformFile>>(
      valueListenable: _attachedFilesNotifier,
      builder: (context, attachedFiles, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: attachedFiles.isEmpty ? 0 : 88,
          margin: EdgeInsets.only(bottom: attachedFiles.isEmpty ? 0 : 8),
          child: attachedFiles.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: attachedFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final file = attachedFiles[index];
                    return _AnimatedFileThumbnail(
                      key: ValueKey('file_${file.name}_$index'),
                      file: file,
                      index: index,
                      onRemove: () {
                        final currentFiles = List<PlatformFile>.from(
                          attachedFiles,
                        );
                        currentFiles.removeAt(index);
                        _attachedFilesNotifier.value = currentFiles;
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSelectionChips() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selectedAddonsNotifier,
      builder: (context, selectedAddons, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: _selectedMcpsNotifier,
          builder: (context, selectedMcps, _) {
            return ValueListenableBuilder<UserModelProvider?>(
              valueListenable: _selectedModelNotifier,
              builder: (context, selectedModel, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _selectedModeNotifier,
                  builder: (context, selectedMode, _) {
                    final hasSelections =
                        selectedAddons.isNotEmpty ||
                        selectedMcps.isNotEmpty ||
                        selectedModel != null ||
                        selectedMode != null;

                    // Build list of chip data for staggered animation
                    final List<_ChipData> chips = [];
                    int chipIndex = 0;

                    if (selectedMode != null) {
                      chips.add(_ChipData(
                        key: 'mode_$selectedMode',
                        icon: LucideIcons.layers,
                        label: selectedMode,
                        onRemove: () => _selectedModeNotifier.value = null,
                        index: chipIndex++,
                      ));
                    }
                    if (selectedModel != null) {
                      chips.add(_ChipData(
                        key: 'model_${selectedModel.id}',
                        icon: LucideIcons.brain,
                        label: selectedModel.llmModelName ?? 'Model',
                        onRemove: () => _selectedModelNotifier.value = null,
                        index: chipIndex++,
                      ));
                    }
                    if (selectedAddons.isNotEmpty) {
                      chips.add(_ChipData(
                        key: 'addons_${selectedAddons.length}',
                        icon: LucideIcons.puzzle,
                        label: "${selectedAddons.length} ${selectedAddons.length > 1 ? "Addons" : "Addon"}",
                        onRemove: () => _selectedAddonsNotifier.value = {},
                        index: chipIndex++,
                      ));
                    }
                    if (selectedMcps.isNotEmpty) {
                      chips.add(_ChipData(
                        key: 'mcps_${selectedMcps.length}',
                        icon: LucideIcons.server,
                        label: "${selectedMcps.length} ${selectedMcps.length > 1 ? "MCPs" : "MCP"}",
                        onRemove: () => _selectedMcpsNotifier.value = {},
                        index: chipIndex++,
                      ));
                    }

                    return AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.topLeft,
                      child: hasSelections
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 12,
                                bottom: 4,
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: chips
                                    .map((chip) => _AnimatedChip(
                                          key: ValueKey(chip.key),
                                          icon: chip.icon,
                                          label: chip.label,
                                          onRemove: chip.onRemove,
                                          index: chip.index,
                                        ))
                                    .toList(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTextField() {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed) {
          _handleSubmit();
        }
      },
      child: TextField(
        focusNode: _focusNode,
        padding: EdgeInsets.all(12),
        controller: _controller,
        maxLines: 6,
        minLines: 1,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: Theme.of(context).borderRadiusXxl,
          border: Border.all(color: Colors.transparent),
        ),
        onChanged: (v) {
          setState(() {});
        },
        features: [
          InputFeature.leading(
            AddButtonDialog(
              selectedModelNotifier: _selectedModelNotifier,
              selectedAddonsNotifier: _selectedAddonsNotifier,
              selectedMcpsNotifier: _selectedMcpsNotifier,
              attachedFilesNotifier: _attachedFilesNotifier,
              selectedModeNotifier: _selectedModeNotifier,
              models: _models,
              addons: _addons,
              mcps: _mcps,
            ),
          ),
          InputFeature.trailing(_buildLeftActions()),
        ],
        borderRadius: Theme.of(context).borderRadiusXxl,
        placeholder: Text(
          widget.placeHolder ?? 'Assign task or @mention a space',
        ).base,
      ),
    );
  }

  Widget _buildLeftActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(width: 6),
        SubmitButton(
          onPressed: _controller.text.isEmpty ? null : _handleSubmit,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.isEmpty) return;

    Map<String, dynamic> map = {};
    map['message'] = _controller.text;
    map['files'] = [];
    map['addons'] = [];
    map['mcp'] = [];

    for (var i in _attachedFilesNotifier.value) {
      try {
        MultipartFile multipartFile;
        // Check bytes first (works for Web & Mobile if bytes populated)
        if (i.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            i.bytes!,
            filename: i.name,
          );
        } else if (i.path != null) {
          // Fallback to path (Desktop/Mobile)
          multipartFile = await MultipartFile.fromFile(
            i.path!,
            filename: i.name,
          );
        } else {
          debugPrint("Skipping file ${i.name}: No bytes or path available");
          continue;
        }

        final response = await Memory.uploadFile(file: multipartFile);
        if (response is FileUploadResponse) {
          map['files'].add(response.fileId);
        }
      } catch (e) {
        // ignore: avoid_print
        debugPrint("Error uploading file: $e");
      }
    }

    for (var i in _selectedAddonsNotifier.value) {
      map['addons'].add(i);
    }

    for (var i in _selectedMcpsNotifier.value) {
      map['mcp'].add(i);
    }
    if (_selectedModelNotifier.value != null) {
      map['model'] = _selectedModelNotifier.value!.id;
    }
    if (_selectedModeNotifier.value != null) {
      map['mode'] = _selectedModeNotifier.value;
    }
    map['incognito'] = IncognitoModeProvider().value;
    final settings = DataConstants.settingsBox?.get(
      "settings_${AuthenticationProvider().loggedInUser!.email}",
    );
    map['customise'] = settings?['customise'];
    widget.onClicked!(map);
    _controller.clear();
    _attachedFilesNotifier.value = [];
  }
}
