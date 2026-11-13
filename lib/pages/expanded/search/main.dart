import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';

import '../../../logics/data/global_logics.dart';
import 'components/chat_history.dart';
import 'components/file_history.dart';

class ExpandedSearchView extends StatefulWidget {
  final String mode;
  const ExpandedSearchView({super.key, this.mode = "Threads"});

  @override
  State<ExpandedSearchView> createState() => _ExpandedSearchViewState();
}

class _ExpandedSearchViewState extends State<ExpandedSearchView> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: LimitedWindowBox(
        customWidth: DataConstants.pageWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabList(
              // TabList is a lower-level tab header; it doesn't manage content.
              index: index,
              onChanged: (value) {
                setState(() {
                  index = value;
                });
              },
              children: const [
                TabItem(child: Text('Threads')),
                TabItem(child: Text('Files')),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Expanded(
              child: IndexedStack(
                index: index,
                children: [
                  _buildThreadSection(),
                  _buildArtifactSearch()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadSection() {
    return ExpandedChatHistory(
      key: ValueKey('default'),
      searchQuery: null,
    );
  }

  Widget _buildArtifactSearch() {
    return ExpandedFileView(
      searchQuery: "",
    );
  }
}
