import 'package:arcane/arcane.dart' hide Avatar;
import 'package:flutter_client/pages/expanded/addons/components/addon.dart';
import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/builders/item_builder_list_card.dart';

class Marketplace extends StatefulWidget {
  final String? searchQuery;
  const Marketplace({super.key, this.searchQuery});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  @override
  Widget build(BuildContext context) {
    return ItemBuilderBlocCard(
      blocKey: 'userAddon',
      paginated: true,
      shrinkWrap: true,
      customHeight: 90,
      dataSource: widget.searchQuery == null ? Memory.getAllAddons: Memory.searchAllAddons,
      dataSourceArgs: widget.searchQuery == null ? {}: {'query': widget.searchQuery},
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
      name = data.name ?? '';
      description = data.description ?? '';
      logo = data.logo ?? '';
      addonId = data.id;
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
