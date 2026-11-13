import 'package:arcane/arcane.dart' hide SearchBox, Avatar;
import 'package:dice_bear/dice_bear.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/state/simple_bloc.dart';

import '../../../logics/data/helpers/general_utils.dart';
import '../../../logics/domain/blocs/simple/simple_bloc.dart';
import '../../../logics/domain/entities/spaces/spaces.dart';
import '../../../logics/domain/usecases/spaces/spaces_usecase.dart';
import '../../chat/input/agent_input.dart';

class ExpandedSpaces extends StatefulWidget {
  final String spaceId;
  const ExpandedSpaces({super.key, required this.spaceId});

  @override
  State<ExpandedSpaces> createState() => _ExpandedSpacesState();
}

class _ExpandedSpacesState extends State<ExpandedSpaces> {
  int index = 0;
  Space? space;
  String spaceHeader = "PlaceHolder Pro Max";
  String spaceDescription =
      "Big ass statement with some random information and whatever here i write will never be released";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SimpleBlocWidget(
        key: ValueKey('expandedSpaces'),
        loadingWidget: _mainContent().asSkeleton(),
        errorWidgetBuilder: (error) {
          return _mainContent(error: error);
        },
        successWidgetBuilder: (space) {
          space = space;
          spaceHeader = space!.name;
          spaceDescription = space!.description;
          return _mainContent();
        },
        blocInit: (SimpleBloc bloc) {
          bloc.run(
            function: Spaces.getSpaceInfo,
            args: {'space_id': widget.spaceId},
            errorType: ErrorType.widget,
            successType: SuccessType.widget,
          );
        },
        child: _mainContent(),
      ),
    );
  }

  Widget _mainContent({String error = ""}) {
    return Scaffold(
      child: Stack(
        children: [
          error.isEmpty
              ? _spacesContent()
              : CenterBody(
                  icon: LucideIcons.badgeAlert,
                  message: "Failed to fetch Space info.",
                ),
        ],
      ),
    );
  }

  Widget _spacesContent() {

    Avatar avatar = DiceBearBuilder(
      seed: spaceHeader,
      radius: 49,
      size: 16,
      backgroundColor: Theme.of(context).colorScheme.background,
      sprite: DiceBearSprite.icons,
    ).build();

    return LimitedWindowBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          // Avatar with elastic scale entrance
          FadeSlideScaleTransition(
            delay: const Duration(milliseconds: 0),
            curve: AnimationConstants.elasticCurve,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: avatar.toImage(height: 48, width: 48, color: Toolkit.pastelColorLight()),
            ),
          ),
          // Header with staggered entrance
          FadeSlideTransition(
            delay: const Duration(milliseconds: 50),
            child: _buildSpaceHeader(),
          ),
          SizedBox(height: 32),
          // Input bar with staggered entrance
          FadeSlideTransition(
            delay: const Duration(milliseconds: 100),
            child: AgentInputBar(placeHolder: "Assign a task to $spaceHeader",),
          ),
          SizedBox(height: 32),
          // Threads section with staggered entrance
          FadeSlideTransition(
            delay: const Duration(milliseconds: 150),
            child: _buildSpacesThreads(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spaceHeader).x3Large.medium,
          SizedBox(height: 8),
          Text(spaceDescription),
        ],
      ),
    );
  }

  Widget _buildSpacesThreads() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabList(
        index: index,
        onChanged: (value) {
          setState(() {
            index = value;
          });
        },
        children: [
          TabItem(
            child: Row(
              spacing: 8,
              children: [
                Icon(LucideIcons.history, size: 16),
                Text('My threads'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
