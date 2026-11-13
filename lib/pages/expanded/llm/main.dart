import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import '../../../main.dart';
import 'components/llm_provider_list.dart';
import 'forms/llm_provider_form.dart';

class ExpandedLlmView extends StatefulWidget {
  const ExpandedLlmView({super.key});

  @override
  State<ExpandedLlmView> createState() => _ExpandedLlmViewState();
}

class _ExpandedLlmViewState extends State<ExpandedLlmView> {
  final ScrollController controller = ScrollController();

  void _showToast(String title, String message) {
    bool isError = title.toLowerCase() == 'error';
    Color indicatorColor = isError ? Colors.red : Colors.green;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: LimitedWindowBox(
        customWidth: DataConstants.pageWidth,
        child: Screen(
          fab: Container(
            margin: EdgeInsets.only(bottom: 50, right: 50),
            child: PrimaryButton(
              leading: Icon(LucideIcons.plus),
              child: Text("Add new LLM").bold,
              onPressed: ()  async {
                await postHogInstance.capture(
                  eventName: 'user_clicked_add_new_llm',
                );
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      padding: EdgeInsets.all(8),
                      content: SizedBox(
                        height: 400,
                        width: 500,
                        child: LlmProviderForm(
                          type: 'chat',
                          showToast: _showToast,
                          onSuccess: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Expanded(child: LlmProviderList(key: ValueKey(DateTime.now().millisecondsSinceEpoch),controller: controller)),
            ],
          ),
        ),
      ),
    );
  }
}
