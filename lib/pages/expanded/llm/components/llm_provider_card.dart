import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/agents/settings.dart';
import 'package:flutter_client/pages/expanded/llm/components/llm_provider_menu.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

class LlmProviderCard extends StatelessWidget {
  final UserModelProvider provider;

  const LlmProviderCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard.subtle(
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "${provider.providerName} ${provider.llmModelName}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            LlmProviderMenu(provider: provider),
          ],
        ),
      ),
    );
  }
}
