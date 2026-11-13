import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class CodeBlockContent extends StatelessWidget {
  final String code;
  final bool animate;
  final Duration animationDelay;

  const CodeBlockContent({
    super.key,
    required this.code,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');

    return ContentCard(
      animate: animate,
      delay: animationDelay,
      contentPadding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(lines.length, (i) => Text('${i + 1}').mono.xSmall.muted),
                ),
                const SizedBox(width: 6),
                SelectableText(code).mono.xSmall,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
