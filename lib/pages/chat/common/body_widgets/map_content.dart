import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class MapContent extends StatelessWidget {
  final String rawData;
  final String bodyType;
  final bool animate;
  final Duration animationDelay;

  const MapContent({
    super.key,
    required this.rawData,
    required this.bodyType,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    try {
      List<String> keys = [];
      final keyMatch = RegExp(r'map\[([^\]]+)\]').firstMatch(bodyType);
      if (keyMatch != null) {
        keys = keyMatch.group(1)!.split(',').map((k) => k.trim()).toList();
      }

      final data = JsonDecodeUtils.decodeNested(rawData);

      if (data is Map) {
        final displayKeys = keys.isNotEmpty ? keys : data.keys.toList();
        return ContentCard(
          animate: animate,
          delay: animationDelay,
          child: ListView.builder(
            itemCount: displayKeys.length,
            itemBuilder: (context, index) {
              final key = displayKeys[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$key: ').mono.xSmall.muted,
                    Expanded(child: Text(data[key]?.toString() ?? '-').mono.xSmall),
                  ],
                ),
              );
            },
          ),
        );
      }
      return const Center(child: Text('No data'));
    } catch (e) {
      return const Center(child: Text('Failed'));
    }
  }
}
