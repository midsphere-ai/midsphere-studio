import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/widgets/texts/settings_text_field.dart';

import '../../../logics/data/helpers/general_utils.dart';
import '../../home/sidebar/common/header.dart';

/// A widget that displays the context and memory settings.
///
/// This widget allows the user to configure LLM-based compression,
/// context auto-optimization, and the compression model.
class ContextMemoryView extends StatefulWidget {
  /// A callback function that is called when the user taps the "Go back" button.
  final VoidCallback? onGoBack;
  final TextEditingController compressionTriggerController;
  final Function(String, String) showToast;
  final VoidCallback onShowCompressionModelForm;

  /// Creates a new [ContextMemoryView] widget.
  ///
  /// The [onGoBack] parameter is required.
  const ContextMemoryView({
    super.key,
    this.onGoBack,
    required this.compressionTriggerController,
    required this.showToast,
    required this.onShowCompressionModelForm,
  });

  @override
  State<ContextMemoryView> createState() => _ContextMemoryViewState();
}

class _ContextMemoryViewState extends State<ContextMemoryView> {
  bool _useLlmCompression = false;
  bool _contextAutoOptimisation = true;
  SliderValue _maxTokenBudgetRatio = const SliderValue.single(0.9);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        if (widget.onGoBack != null && !Toolkit.isMobile(context))
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: SidebarHeader(
              title: 'Context and Memory',
              onBack: widget.onGoBack,
            ),
          ),
        if (widget.onGoBack != null) Divider(),
        if (widget.onGoBack != null) const SizedBox(height: 16),
        _buildOptionRow(
          title: 'LLM-based Compression',
          description:
              'Summarizes conversation history to save space when the context limit is reached.',
          control: Switch(
            value: _useLlmCompression,
            onChanged: (value) => setState(() => _useLlmCompression = value),
          ),
        ),
        _buildOptionRow(
          title: 'Trigger Compression at',
          description:
              'Sets the context length (in characters) that triggers the compression.',
          control: SettingsTextField(
            controller: widget.compressionTriggerController,
            icon: LucideIcons.target,
            label: 'Length',
          ),
        ),
        _buildOptionRow(
          title: 'Context Auto-optimization',
          description:
              'Automatically prunes less relevant parts of the context to save tokens.',
          control: Switch(
            value: _contextAutoOptimisation,
            onChanged: (value) =>
                setState(() => _contextAutoOptimisation = value),
          ),
        ),
        _buildOptionRow(
          title: 'Max Token Budget Ratio',
          description:
              "The maximum percentage of the model's token limit to use for context (e.g., 0.9 = 90%).",
          control: Column(
            children: [
              Slider(
                value: _maxTokenBudgetRatio,
                onChanged: (value) =>
                    setState(() => _maxTokenBudgetRatio = value),
              ),
              Text(
                '${((_maxTokenBudgetRatio.value) * 100).toStringAsFixed(0)}%',
              ).small.muted,
            ],
          ),
        ),
        _buildSettingsItem(
          icon: LucideIcons.cog,
          label: 'Compression Model',
          description:
              'Choose the specific LLM to use for context compression.',
          onTap: widget.onShowCompressionModelForm,
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PrimaryButton(
            child: Text("Update configuration").bold,
            onPressed: () async {
              try {
                await Memory.updateContextConfig(
                  llmBasedCompression: _useLlmCompression,
                  triggerCompressionLength: int.parse(
                    widget.compressionTriggerController.text,
                  ),
                  contextAutoOptimisation: _contextAutoOptimisation,
                  maxTokenBudgetRatio: _maxTokenBudgetRatio.value,
                  compressionLlmId: '',
                );
                widget.showToast(
                  'Success',
                  'Context configuration updated successfully.',
                );
              } catch (e) {
                widget.showToast(
                  'Error',
                  'Failed to update context configuration.',
                );
              }
            },
          ),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  /// Builds a row with a title, description, and a control widget.
  Widget _buildOptionRow({
    required String title,
    required String description,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.accentForeground,
                      ),
                    ).bold.small,
                    const SizedBox(height: 4),
                    Text(description).small.muted,
                  ],
                ),
              ),
              Flexible(flex: 1, fit: FlexFit.loose, child: control),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
        ],
      ),
    );
  }

  /// Builds a settings item with an icon, label, description, and a callback.
  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GhostButton(
      onPressed: onTap,
      leading: Icon(icon),
      child: Text(label),
    );
  }
}
