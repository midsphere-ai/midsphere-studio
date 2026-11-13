import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/agents/settings.dart';
import 'package:flutter_client/pages/expanded/llm/components/llm_provider_card.dart';

import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/builders/item_builder_list_card.dart';

class LlmProviderList extends StatelessWidget {
  final ScrollController controller;
  const LlmProviderList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ItemBuilderBlocCard(
      blocKey: 'llmProviderList',
      paginated: true,
      customHeight: 65,
      customWidth: 400,
      dataSource: Memory.getLlmProviders,
      dataSourceArgs: {},
      onDataEmpty: "No LLM providers found",
      onError: "Error fetching LLM providers",
      placeHolderItems: [
        UserModelProvider(
          providerName: 'OpenAI',
          llmModelName: 'gpt-4',
          dateUpdated: DateTime.now(), userId: 1,
        ).toJson(),
        UserModelProvider(
          userId: 1,
          providerName: 'Groq',
          llmModelName: 'llama3-70b-8192',
          dateUpdated: DateTime.now(),
        ).toJson(),
      ],
      item: (data) {
        if (data is UserModelProvider) {
          return LlmProviderCard(provider: data);
        }
        return LlmProviderCard(
          provider: UserModelProvider.fromJson(data),
        );
      },
    );
  }
}
