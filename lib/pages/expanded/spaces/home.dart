import 'package:arcane/arcane.dart' hide Avatar;
import 'package:flutter_client/pages/expanded/spaces/components/user_spaces.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';

import '../../../logics/data/global_logics.dart';

class SpacesHome extends StatefulWidget {
  const SpacesHome({super.key});

  @override
  State<SpacesHome> createState() => _SpacesHomeState();
}

class _SpacesHomeState extends State<SpacesHome> {
  int index = 0;
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: LimitedWindowBox(
        customWidth: DataConstants.pageWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            Text("Welcome to Spaces").h3,
            SizedBox(height: 8),
            Text(
              "Organise your work according to topics, artifacts and knowledge.",
            ).muted,
            SizedBox(height: 32),
            Expanded(child: _buildYourSpaces()),
          ],
        ),
      ),
    );
  }

  Widget _buildYourSpaces() {
    return Column(children: [Expanded(child: UserSpaces())]);
  }
}
