import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/menu/dropdown_menu.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/domain/entities/agents/settings.dart';
import 'package:flutter_client/logics/domain/usecases/memory/memory_usecase.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client/widgets/state/toast_helper.dart';

import '../../../../main.dart';
import '../main.dart'; // For kDebugMode

enum _ToastType { success, danger }

class LlmProviderMenu extends StatelessWidget {
  final UserModelProvider provider;

  const LlmProviderMenu({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return IconButton.secondary(
      density: ButtonDensity.iconDense,
      icon: Icon(LucideIcons.ellipsis),
      onPressed: () => _showOptionsMenu(context),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showDropdown(
      context: context,
      builder: (context) {
        return LlmProviderMenuDropdown(provider: provider);
      },
    ).future.then((_) {
      if (kDebugMode) {
      }
    });
  }
}

class LlmProviderMenuDropdown extends StatelessWidget {
  final UserModelProvider provider;

  const LlmProviderMenuDropdown({super.key, required this.provider});

  Future<void> updateEndpoint(String type) async {
    try {
      await postHogInstance.capture(
          eventName: 'update_type_llm',
          properties: {
            'type': type,
            'provider_id': provider.id
          }
      );
      Map response = await Memory.updateTypeLlm(
        llmType: type,
        providerId: provider.id,
      );
      if (response.containsKey('id')) {
        ToastHelper.show(
          RootShell.context(ValueKey('main')),
          'Updated LLM for type $type',
          LucideIcons.check,
        );
      } else {
        ToastHelper.show(
          RootShell.context(ValueKey('main')),
          "Failed to update: $response",
          LucideIcons.x,
        );
      }
    } catch (e,s) {
      await postHogInstance.captureException(
          error: e,
          stackTrace: s,
          properties: {
            'type': type,
            'provider_id': provider.id
          }
      );
      ToastHelper.show(
        RootShell.context(ValueKey('main')),
        "Error while updating LLM: $e",
        LucideIcons.x,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      children: [
        MenuButton(
          leading: Icon(LucideIcons.settings),
          subMenu: [
            MenuButton(
              child: const Text('Primary'),
              onPressed: () async {
                await updateEndpoint("primary");
              },
            ),
            MenuDivider(),
            MenuLabel(child: Text('Media')),
            MenuButton(
              child: const Text('Audio'),
              onPressed: () async {
                await updateEndpoint("audio");
              },
            ),
            MenuButton(
              child: const Text('Image'),
              onPressed: () async {
                await updateEndpoint("image");
              },
            ),
            MenuButton(
              child: const Text('Video'),
              onPressed: () async {
                await updateEndpoint("video");
              },
            ),
            MenuButton(
              child: const Text('Browser'),
              onPressed: () async {
                await updateEndpoint("browser");
              },
            ),
            MenuDivider(),
            MenuLabel(child: Text('Reasoning')),
            MenuButton(
              child: const Text('Code'),
              onPressed: () async {
                await updateEndpoint('code');
              },
            ),
            MenuButton(
              child: const Text('Complex reasoning'),
              onPressed: () async {
                await updateEndpoint("think");
              },
            ),
            MenuDivider(),
            MenuButton(
              child: const Text('Computer use'),
              onPressed: () async {
                await updateEndpoint("computer_use");
              },
            ),
          ],
          child: const Text('Set default for'),
        ),
        MenuDivider(),
        MenuButton(
          leading: Icon(LucideIcons.trash2),
          onPressed: () async {
            await _deleteProvider(context);
          },
          child: const Text('Delete Provider'),
        ),
      ],
    );
  }

  Future<void> _deleteProvider(BuildContext context) async {
    final res = await Memory.unregisterLlmProvider(providerId: provider.id);
    try {
      _showToast(
        context: context,
        type: _ToastType.success,
        title: 'Provider Deleted',
        message: '${provider.providerName} has been removed.',
      );
      await postHogInstance.capture(
          eventName: 'delete_provider',
          properties: {
            'provider_id': provider.id
          }
      );
      RootShell.updateAndRefresh(
        const ValueKey('main'),
        ExpandedLlmView(key: ValueKey(Uuid().v4())),
        'Available LLMs',
        LucideIcons.brain,
      );
    } catch (e,s) {
      await postHogInstance.captureException(
          error: e,
          stackTrace: s,
          properties: {
            'provider_id': provider.id
          }
      );
      _showToast(
        context: context,
        type: _ToastType.danger,
        title: 'Provider failed to delete',
        message: '${provider.providerName} has not been removed.',
      );
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
                    child: Basic(title: Text(title), subtitle: Text(message)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
