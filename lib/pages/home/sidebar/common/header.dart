import 'package:arcane/arcane.dart';

class SidebarHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const SidebarHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton.ghost(
                  density: ButtonDensity.iconDense,
                  onPressed: onBack,
                  icon:  Icon(LucideIcons.arrowLeft),
                ),
              ),
            Text(title).small,
          ],
        ),
      ],
    );
  }
}
