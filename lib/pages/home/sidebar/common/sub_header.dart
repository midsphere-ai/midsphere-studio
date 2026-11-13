import 'package:arcane/arcane.dart';

// ignore: must_be_immutable
class SidebarSubHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? extra;
  final VoidCallback? onIconClicked;
  IconData? leading;

  SidebarSubHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onIconClicked,
    this.leading,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 0, bottom: 16),
      child: Column(
        children: [
          SizedBox(height: 8),
          Row(
            spacing: 0,
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Icon(leading),
                ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.accentForeground,
                ),
              ).bold.base,
              const Spacer(),
              if (onIconClicked != null)
                IconButton.ghost(
                  shape: ButtonShape.circle,
                  icon: Icon(icon),
                  onPressed: onIconClicked,
                ),
              SizedBox(width: 8),
              if (extra != null) ...[
                Container(
                  width: 1,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.border,
                  ),
                ),
                extra!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
