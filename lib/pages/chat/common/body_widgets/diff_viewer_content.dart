import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

enum DiffLineType { addition, deletion, context }

class DiffLine {
  final DiffLineType type;
  final String content;
  final int? lineNum;
  DiffLine({required this.type, required this.content, this.lineNum});
}

class DiffViewerContent extends StatelessWidget {
  final Map<String, dynamic> arguments;
  final String? rawData;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const DiffViewerContent({
    super.key,
    required this.arguments,
    this.rawData,
    required this.fallbackBuilder,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    try {
      List<dynamic> edits = arguments['edits'] ?? arguments['changes'] ?? [];

      if (edits.isEmpty && rawData != null) {
        final data = JsonDecodeUtils.decodeNested(rawData!);
        if (data is Map) edits = data['edits'] ?? data['changes'] ?? [];
      }

      if (edits.isEmpty) return const Center(child: Text('No changes'));

      List<DiffLine> lines = [];
      int ln = 1;

      for (final edit in edits) {
        final old = (edit['old_text'] ?? edit['old_string'] ?? edit['oldString'] ?? '').toString();
        final neu = (edit['new_text'] ?? edit['new_string'] ?? edit['newString'] ?? '').toString();

        if (old.isNotEmpty) {
          for (final l in old.split('\n')) {
            lines.add(DiffLine(type: DiffLineType.deletion, content: l, lineNum: ln++));
          }
        }
        if (neu.isNotEmpty) {
          for (final l in neu.split('\n')) {
            lines.add(DiffLine(type: DiffLineType.addition, content: l, lineNum: ln++));
          }
        }
      }

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        contentPadding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lines.map((l) {
              final isAdd = l.type == DiffLineType.addition;
              final isDel = l.type == DiffLineType.deletion;
              return Container(
                color: isAdd ? const Color(0xFF1A3D1A).withOpacity(0.25) : (isDel ? const Color(0xFF3D1A1A).withOpacity(0.25) : null),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Row(
                  children: [
                    SizedBox(width: 16, child: Text('${l.lineNum ?? ''}').mono.xSmall.muted),
                    SizedBox(width: 10, child: Text(isAdd ? '+' : (isDel ? '-' : ' '), style: TextStyle(color: isAdd ? Colors.green : (isDel ? Colors.red : colors.foreground))).mono.xSmall),
                    Expanded(child: Text(l.content.isEmpty ? ' ' : l.content, style: TextStyle(color: isAdd ? const Color(0xFF7EE787) : (isDel ? const Color(0xFFE78787) : colors.foreground))).mono.xSmall),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }
}
