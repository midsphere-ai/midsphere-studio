import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class TableContent extends StatelessWidget {
  final String rawData;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const TableContent({
    super.key,
    required this.rawData,
    required this.fallbackBuilder,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final data = JsonDecodeUtils.decodeNested(rawData);

      List<String> columns = [];
      List<List<dynamic>> rows = [];

      if (data is Map && data.containsKey('rows') && data.containsKey('columns')) {
        columns = (data['columns'] as List).cast<String>();
        rows = (data['rows'] as List).map((row) => row is List ? row : [row]).toList();
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        columns = (data.first as Map).keys.map((k) => k.toString()).toList();
        rows = data.map((row) => row is Map ? columns.map((col) => row[col]).toList() : [row]).toList();
      }

      if (columns.isEmpty) return fallbackBuilder();

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        contentPadding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: Table(
            rows: [
              TableRow(cells: columns.map((col) => TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text(col).xSmall.muted))).toList()),
              ...rows.map((row) => TableRow(cells: row.map((cell) => TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text(cell?.toString() ?? '-').xSmall))).toList())),
            ],
          ),
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }
}
