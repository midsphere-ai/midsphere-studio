import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/widgets/texts/settings_text_field.dart';

import '../../../../main.dart';
import '../../../home/home.dart';
import '../../../home/sidebar/common/header.dart';
import '../../../home/sidebar/common/sub_header.dart';
import '../main.dart';

enum ProviderMap {
  azureOpenAI("Azure OpenAI", "azure_openai"),
  openAI("OpenAI", "openai"),
  anthropic("Anthropic", "anthropic"),
  openRouter("OpenRouter", "openai"),
  ollama("Ollama", "openai"),
  anthropicBedrock("Anthropic Bedrock", "anthropic_bedrock"),
  google("Google", "google");

  final String label;
  final String providerId;

  const ProviderMap(this.label, this.providerId);
}

class LlmProviderForm extends StatefulWidget {
  final String type;
  final VoidCallback? onGoBack;
  final Function(String title, String message) showToast;
  final bool onboarding;
  final List<ProviderMap> disabledProviders;
  final VoidCallback? onSuccess;

  const LlmProviderForm({
    super.key,
    required this.type,
    this.onGoBack,
    required this.showToast,
    this.onboarding = false,
    this.disabledProviders = const [],
    this.onSuccess,
  });

  @override
  State<LlmProviderForm> createState() => _LlmProviderFormState();
}

class _LlmProviderFormState extends State<LlmProviderForm> {
  ProviderMap? _selectedProvider;

  // Standard fields
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();

  // Extra fields
  final TextEditingController _azureApiVersionController =
      TextEditingController();
  final TextEditingController _awsSecretAccessKeyController =
      TextEditingController();
  final TextEditingController _awsDefaultRegionController =
      TextEditingController();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _azureApiVersionController.dispose();
    _awsSecretAccessKeyController.dispose();
    _awsDefaultRegionController.dispose();
    super.dispose();
  }

  void _onProviderChanged(ProviderMap? provider) {
    setState(() {
      _selectedProvider = provider;
      // Pre-fill defaults
      if (provider == ProviderMap.openRouter) {
        _baseUrlController.text = "https://openrouter.ai/api/v1";
      } else if (provider == ProviderMap.ollama) {
        _baseUrlController.text = "http://localhost:11434/api";
      } else {
        _baseUrlController.clear();
      }
    });
  }

  Future<void> _save() async {
    if (_selectedProvider == null) {
      widget.showToast('Error', 'Please select a provider.');
      return;
    }

    if (_selectedProvider != ProviderMap.ollama &&
        _apiKeyController.text.isEmpty) {
      // Allow empty API key for Ollama
    }

    if (_modelNameController.text.isEmpty) {
      widget.showToast('Error', 'Model name is required.');
      return;
    }

    // Prepare extras
    Map<String, dynamic> extras = {};
    if (_selectedProvider == ProviderMap.azureOpenAI) {
      extras['AZURE_OPENAI_API_VERSION'] = _azureApiVersionController.text;
    } else if (_selectedProvider == ProviderMap.anthropicBedrock) {
      extras['AWS_SECRET_ACCESS_KEY'] = _awsSecretAccessKeyController.text;
      extras['AWS_DEFAULT_REGION'] = _awsDefaultRegionController.text;
      extras['AWS_ACCESS_KEY_ID'] = _apiKeyController.text;
    }

    try {
      await postHogInstance.capture(
        eventName: 'register_llm_provider',
        properties: {'provider_name': _selectedProvider!.providerId},
      );

      await Memory.registerLlmProvider(
        providerName: _selectedProvider!.providerId,
        llmBaseUrl: _baseUrlController.text,
        llmApiKey: _apiKeyController.text,
        llmModelName: _modelNameController.text,
        type: widget.type,
        extras: extras,
      );
      widget.showToast(
        'Success',
        '${widget.type == 'compression' ? 'Compression' : ''} LLM provider registered successfully.',
      );
      widget.onSuccess?.call();
      RootShell.updateAndRefresh(
        const ValueKey('main'),
        ExpandedLlmView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
        'Available LLMs',
        LucideIcons.brain,
      );
    } catch (e, s) {
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'provider_id': _selectedProvider!.providerId},
      );
      widget.showToast(
        'Error',
        'Failed to register ${widget.type == 'compression' ? 'compression' : ''} LLM provider.',
      );
    }

    closeOverlay(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onboarding) {
      return Card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderSelect(),
            if (_selectedProvider != null) ...[
              _buildFields(),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SidebarSubHeader(
            icon: FontAwesomeIcons.l,
            title:
                'Add ${widget.type == 'compression' ? 'Compression' : ''} LLM',
          ),
        ),
        const SizedBox(height: 16),
        _buildProviderSelect(),
        if (_selectedProvider != null) ...[
          _buildFields(),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ],
      ],
    );
  }

  Widget _buildProviderSelect() {
    final availableProviders = ProviderMap.values
        .where((p) => !widget.disabledProviders.contains(p))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onboarding) ...[
          Text("LLM Provider").small.muted,
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Select<ProviderMap>(
            constraints: BoxConstraints(minWidth: 600),
            itemBuilder: (context, item) {
              return Text(item.label);
            },
            popup: SelectPopup(
              items: SelectItemList(
                children: availableProviders
                    .map(
                      (e) => SelectItemButton(value: e, child: Text(e.label)),
                    )
                    .toList(),
              ),
            ).call,
            onChanged: _onProviderChanged,
            value: _selectedProvider,
            placeholder: const Text('Select a provider'),
          ),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Base URL
        if (_shouldShowBaseUrl()) ...[
          if (widget.onboarding)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text("LLM Base URL").small.muted,
            ),
          SettingsTextField(
            icon: LucideIcons.link,
            label: "LLM base URL",
            controller: _baseUrlController,
            withOutPadding: widget.onboarding,
          ),
        ],

        // API Key
        if (widget.onboarding)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(_getApiKeyLabel()).small.muted,
          ),
        SettingsTextField(
          icon: LucideIcons.key,
          label: _getApiKeyLabel(),
          controller: _apiKeyController,
          withOutPadding: widget.onboarding,
        ),

        // Model Name
        if (widget.onboarding)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text("Model Name").small.muted,
          ),
        SettingsTextField(
          icon: LucideIcons.text,
          label: "LLM name",
          controller: _modelNameController,
          withOutPadding: widget.onboarding,
        ),

        // Azure API Version
        if (_selectedProvider == ProviderMap.azureOpenAI) ...[
          if (widget.onboarding)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text("AZURE_OPENAI_API_VERSION").small.muted,
            ),
          SettingsTextField(
            icon: LucideIcons.calendar,
            label: "AZURE_OPENAI_API_VERSION",
            controller: _azureApiVersionController,
            withOutPadding: widget.onboarding,
          ),
        ],

        // AWS Extras
        if (_selectedProvider == ProviderMap.anthropicBedrock) ...[
          if (widget.onboarding)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text("AWS_SECRET_ACCESS_KEY").small.muted,
            ),
          SettingsTextField(
            icon: LucideIcons.lock,
            label: "AWS_SECRET_ACCESS_KEY",
            controller: _awsSecretAccessKeyController,
            withOutPadding: widget.onboarding,
          ),
          if (widget.onboarding)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text("AWS_DEFAULT_REGION").small.muted,
            ),
          SettingsTextField(
            icon: LucideIcons.globe,
            label: "AWS_DEFAULT_REGION",
            controller: _awsDefaultRegionController,
            withOutPadding: widget.onboarding,
          ),
        ],
      ],
    );
  }

  bool _shouldShowBaseUrl() {
    switch (_selectedProvider) {
      case ProviderMap.openAI:
      case ProviderMap.anthropic:
      case ProviderMap.anthropicBedrock:
      case ProviderMap.google:
        return false;
      default:
        return true;
    }
  }

  String _getApiKeyLabel() {
    if (_selectedProvider == ProviderMap.anthropicBedrock) {
      return "AWS_ACCESS_KEY_ID";
    }
    return "LLM API key";
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PrimaryButton(
        onPressed: _save,
        child: const Text("Save").bold,
      ),
    );
  }
}
