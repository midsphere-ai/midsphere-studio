import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/pages/home/sidebar/common/sub_header.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';

import 'components/mcp_server_list.dart';
import 'forms/add_mcp_server_form.dart';

class ExpandedMcpView extends StatefulWidget {
  const ExpandedMcpView({super.key});

  @override
  State<ExpandedMcpView> createState() => _ExpandedMcpViewState();
}

class _ExpandedMcpViewState extends State<ExpandedMcpView> {
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
              child: Text("Add MCP Server").bold,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      padding: EdgeInsets.all(8),
                      content: SizedBox(
                        height: 400,
                        width: 500,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SidebarSubHeader(
                                icon: LucideIcons.lampCeiling,
                                title: "Add MCP server",
                              ),
                              AddMcpServerForm(
                                showToast: _showToast,
                                onSuccess: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              SizedBox(height: 32),
                            ],
                          ),
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
              Expanded(child: McpServerList(showToast: showToast, controller: controller)),
            ],
          ),
        ),
      ),
    );
  }
}
