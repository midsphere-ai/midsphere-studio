import 'package:arcane/arcane.dart';

class CustomLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CustomLogo({
    super.key,
    this.size = 32,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 12,
      children: [
        ClipRRect(
          borderRadius: Theme.of(context).borderRadiusMd,
          child: Image.asset(
            "assets/images/logo.png",
            height: size,
            width: size,
            color: primaryColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
