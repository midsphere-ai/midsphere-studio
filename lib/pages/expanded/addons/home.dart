import 'package:arcane/arcane.dart' hide Avatar;
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';

import '../../../logics/data/global_logics.dart';
import 'components/marketplace.dart';
import 'components/user_addons.dart';

class AddonsHome extends StatefulWidget {
  final String mode;
  const AddonsHome({super.key, this.mode = "Marketplace"});

  @override
  State<AddonsHome> createState() => _AddonsHomeState();
}

class _AddonsHomeState extends State<AddonsHome> {
  int index = 0;
  TextEditingController search = TextEditingController();
  bool searchAuthComplete = false;
  ScrollController controller = ScrollController();

  final data = [
    {'name': 'GitHub', 'description': 'GitHub is an version control software'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: LimitedWindowBox(
        customWidth: DataConstants.pageWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 240,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Column(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.shapes, size: 72, color: Theme.of(context).colorScheme.primary,),
                      Text("Connectors").h3,
                      Text(
                        "Let Midsphere's agents work across all your favourite apps to provide you best possible experience.",
                        textAlign: TextAlign.center,
                      ).muted,
                    ],
                  ),
                ),
              ),
              TabList(
                // TabList is a lower-level tab header; it doesn't manage content.
                index: index,
                onChanged: (value) {
                  setState(() {
                    index = value;
                  });
                },
                children: const [
                  TabItem(child: Text('Store')),
                  TabItem(child: Text('Installed')),
                ],
              ),
              SizedBox(height: 16),
              IndexedStack(
                index: index,
                children: [
                  _buildMarketplace(),
                  _buildEnabledExtensions()
                ],
              ),
              // widget.mode == "Installed Addons"
              //     ? _buildEnabledExtensions()
              //     : _buildMarketplace(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnabledExtensions() {
    return Column(
      children: [
        TextField(
          placeholder: Text("Search your enabled extensions"),
          features: [InputFeature.leading(Icon(LucideIcons.search))],
        ),
        SizedBox(height: 16),
        EnabledAddon(
          key: search.text.isNotEmpty
              ? ValueKey(search.text)
              : ValueKey('default'),
          searchQuery: search.text.isEmpty ? null : search.text,
          authComplete: searchAuthComplete,
        ),
      ],
    );
  }

  Widget _buildMarketplace() {
    return Column(
      children: [
        TextField(
          placeholder: Text("Search Marketplace"),
          controller: search,
          onChanged: (v) {
            setState(() {});
          },
          features: [InputFeature.leading(Icon(LucideIcons.search))],
        ),
        SizedBox(height: 16),
        Marketplace(
          key: search.text.isNotEmpty
              ? ValueKey(search.text)
              : ValueKey('default'),
          searchQuery: search.text.isEmpty ? null : search.text,
        ),
      ],
    );
  }
}
