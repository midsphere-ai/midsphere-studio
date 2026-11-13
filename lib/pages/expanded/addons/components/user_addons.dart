import 'package:arcane/arcane.dart';

import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/builders/item_builder_list_card.dart';
import 'addon.dart';

class EnabledAddon extends StatefulWidget {
  final String? searchQuery;
  final bool? authComplete;
  const EnabledAddon({super.key, this.searchQuery, this.authComplete});

  @override
  State<EnabledAddon> createState() => _EnabledAddonState();
}

class _EnabledAddonState extends State<EnabledAddon> {
  @override
  Widget build(BuildContext context) {
    return ItemBuilderBlocCard(
      blocKey: 'marketplace',
      paginated: true,
      shrinkWrap: true,
      customHeight: 90,
      dataSource: widget.searchQuery != null ? Memory.searchUserAddons : Memory.getUserAddons,
      dataSourceArgs: widget.searchQuery != null ?{'query': widget.searchQuery, 'auth_complete': widget.authComplete}: {},
      onDataEmpty: "No addons found",
      onError: "Error fetching addons",
      placeHolderItems: _placeholderAddons,
      item: (data) => _buildAddonCard(context, data),
    );
  }

  Widget _buildAddonCard(BuildContext context, dynamic data) {
    final String name;
    final String description;
    final String addonId;
    final String logo;

    if (data is Map) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
      logo = data['logo'] ?? '';
      addonId = '';
    } else {
      name = data.enabledAddon.name ?? '';
      description = data.enabledAddon.description ?? '';
      logo = data.enabledAddon.logo ?? '';
      addonId = data.enabledAddon.id;
    }

    return AddonCard(
      addonId: addonId,
      name: name,
      description: description,
      logo: logo,
    );
  }

  static const List<Map<String, String>> _placeholderAddons = [
    {
      "name": "Slack",
      "description":
          "Slack is a cloud-based team communication platform with channels, direct messages, file sharing, and thousands of integrations.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/7/76/Slack_Icon.png",
    },
    {
      "name": "Zoom",
      "description":
          "Zoom is a video conferencing platform offering HD video, audio, webinars, chat, and screen sharing for meetings and webinars.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/7/75/Zoom_Communications_Logo.svg",
    },
    {
      "name": "Microsoft Teams",
      "description":
          "Microsoft Teams is a collaboration platform that integrates chat, meetings, calling, and Office apps for teams.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/4/4f/Microsoft_Office_Teams_%282018%E2%80%93present%29.svg",
    },
    {
      "name": "Google Meet",
      "description":
          "Google Meet is Google's video-conferencing product providing secure meetings, screen sharing and integration with Google Workspace.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/2/2d/Google_Meet_icon_%282020%29.svg",
    },
  ];
}
