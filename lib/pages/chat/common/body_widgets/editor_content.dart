import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';
import 'package:flutter_client/widgets/texts/json_pretty.dart';

class EditorContent extends StatelessWidget {
  final String? specificContent;
  final String? rawData;
  final bool animate;
  final Duration animationDelay;

  const EditorContent({
    super.key,
    this.specificContent,
    this.rawData,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (specificContent != null && specificContent!.isNotEmpty) {
      final lines = specificContent!.split('\n');
      return ContentCard(
        animate: animate,
        delay: animationDelay,
        contentPadding: EdgeInsets.zero,
        scrollable: true,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lines.asMap().entries.map((e) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 16, child: Text('${e.key + 1}').mono.xSmall.muted),
                Expanded(child: SelectableText(e.value.isEmpty ? ' ' : e.value).mono.xSmall),
              ],
            )).toList(),
          ),
        ),
      );
    }

    if (rawData != null) {
      return FormattedDataContent(rawData: rawData!, animate: animate, animationDelay: animationDelay);
    }

    return const Center(child: Text('No content'));
  }
}

class FormattedDataContent extends StatelessWidget {
  final String rawData;
  final bool animate;
  final Duration animationDelay;

  const FormattedDataContent({super.key, required this.rawData, this.animate = true, this.animationDelay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    try {
      final data = JsonDecodeUtils.decodeNested(rawData);

      if (data is Map) {
        final content = JsonDecodeUtils.extractContent(data);
        if (content != null && content.isNotEmpty) {
          return ContentCard(
            animate: animate,
            delay: animationDelay,
            scrollable: true,
            child: SelectableText(content).mono.xSmall,
          );
        }
        return KeyValueContent(data: data, success: JsonDecodeUtils.isSuccess(data), animate: animate, animationDelay: animationDelay);
      }

      if (data is String) {
        return ContentCard(animate: animate, delay: animationDelay, scrollable: true, child: SelectableText(data).mono.xSmall);
      }

      return JsonPrettyPrint(jsonObject: rawData);
    } catch (e) {
      return JsonPrettyPrint(jsonObject: rawData);
    }
  }
}

class KeyValueContent extends StatelessWidget {
  final Map data;
  final bool success;
  final bool animate;
  final Duration animationDelay;

  const KeyValueContent({super.key, required this.data, this.success = false, this.animate = true, this.animationDelay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.where((k) => !['success', 'metadata', 'error'].contains(k)).toList();

    return ContentCard(
      animate: animate,
      delay: animationDelay,
      child: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final key = keys[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$key: ').mono.xSmall.muted,
                Expanded(child: SelectableText(_fmt(data[key])).mono.xSmall),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    if (v is String) return v;
    if (v is List) return v.join(', ');
    if (v is Map) return v.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return v.toString();
  }
}
