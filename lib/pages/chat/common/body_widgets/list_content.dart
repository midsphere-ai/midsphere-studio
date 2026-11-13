import 'dart:convert';
import 'package:arcane/arcane.dart';
import 'package:image_network/image_network.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class ListContent extends StatelessWidget {
  final String rawData;
  final String bodyType;
  final String functionName;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const ListContent({
    super.key,
    required this.rawData,
    required this.bodyType,
    required this.functionName,
    required this.fallbackBuilder,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    try {
      if (functionName == "mcp_search_google") return _buildSearch(context);

      List<String> fields = [];
      final fieldMatch = RegExp(r'list\[([^\]]+)\]').firstMatch(bodyType);
      if (fieldMatch != null) {
        fields = fieldMatch.group(1)!.split(',').map((f) => f.trim()).toList();
      }

      List<dynamic> listData = _decode();
      if (listData.isEmpty) return fallbackBuilder();

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        child: ListView.builder(
          itemCount: listData.length,
          itemBuilder: (context, index) {
            final item = listData[index];
            if (item is Map) {
              final keys = fields.isNotEmpty ? fields : item.keys.toList();
              return Text(keys.map((k) => item[k]?.toString() ?? '-').join(' · ')).xSmall;
            }
            return Text(item.toString()).xSmall;
          },
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }

  Widget _buildSearch(BuildContext context) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded[0];
        data = first is String ? Map<String, dynamic>.from(jsonDecode(first)) : Map<String, dynamic>.from(first);
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      return fallbackBuilder();
    }

    final List results = data['results'] is List ? data['results'] : [];
    if (results.isEmpty) return fallbackBuilder();

    return ContentCard(
      animate: animate,
      delay: animationDelay,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final r = results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: Theme.of(context).borderRadiusSm,
                  child: ImageNetwork(height: 10, width: 10, image: "http://www.google.com/s2/favicons?domain=${r['url']}"),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis).xSmall,
                      Text(r['snippet'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis).xSmall.muted,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _decode() {
    dynamic decoded = rawData;
    if (decoded is String) {
      try { decoded = jsonDecode(decoded); } catch (e) {}
    }

    if (decoded is List && decoded.isNotEmpty) {
      var first = decoded[0];
      if (first is String) {
        try {
          var inner = jsonDecode(first);
          if (inner is List) return inner;
          if (inner is Map) {
            if (inner.containsKey('results')) return inner['results'] as List;
            if (inner.containsKey('items')) return inner['items'] as List;
            if (inner.containsKey('data') && inner['data'] is List) return inner['data'] as List;
            return [inner];
          }
        } catch (e) { return decoded; }
      }
      return decoded;
    }

    if (decoded is Map) {
      if (decoded.containsKey('results')) return decoded['results'] as List;
      if (decoded.containsKey('items')) return decoded['items'] as List;
      if (decoded.containsKey('data') && decoded['data'] is List) return decoded['data'] as List;
      return decoded.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
    }

    return [];
  }
}
