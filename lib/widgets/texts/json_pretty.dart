import 'package:arcane/arcane.dart';

class JsonPrettyPrint extends StatefulWidget {
  final dynamic jsonObject;
  final TextStyle? keyStyle;
  final TextStyle? stringStyle;
  final TextStyle? numberStyle;
  final TextStyle? boolStyle;
  final TextStyle? nullStyle;
  final double indent;

  const JsonPrettyPrint({
    super.key,
    required this.jsonObject,
    this.keyStyle,
    this.stringStyle,
    this.numberStyle,
    this.boolStyle,
    this.nullStyle,
    this.indent = 20.0,
  });

  @override
  State<JsonPrettyPrint> createState() => _JsonPrettyPrintState();
}

class _JsonPrettyPrintState extends State<JsonPrettyPrint> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(
            children: _buildJson(widget.jsonObject, 0),
          ),
        ),
      ),
    ).small;
  }

  List<InlineSpan> _buildJson(dynamic obj, int level) {
    if (obj == null) {
      return [_styledText('null', widget.nullStyle ?? TextStyle())];
    }

    if (obj is Map) {
      return _buildObject(obj, level);
    }

    if (obj is List) {
      return _buildArray(obj, level);
    }

    if (obj is String) {
      String escaped = _escapeString(obj);
      return [_styledText('"$escaped"', widget.stringStyle ?? const TextStyle(color: Colors.green))];
    }

    if (obj is num) {
      return [_styledText('$obj', widget.numberStyle ?? const TextStyle(color: Colors.orange))];
    }

    if (obj is bool) {
      return [_styledText('$obj', widget.boolStyle ?? const TextStyle(color: Colors.blue))];
    }

    return [_styledText('$obj', const TextStyle(color: Colors.white))];
  }

  String _escapeString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll('\b', '\\b')
        .replaceAll('\f', '\\f');
  }

  List<InlineSpan> _buildObject(Map obj, int level) {
    if (obj.isEmpty) {
      return [_styledText('{}', const TextStyle(color: Colors.white))];
    }

    List<InlineSpan> spans = [];
    spans.add(_styledText('{\n', const TextStyle(color: Colors.white)));

    final entries = obj.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      spans.add(_styledText(_indent(level + 1), const TextStyle(color: Colors.white)));

      String escapedKey = _escapeString(entry.key.toString());
      spans.add(_styledText('"$escapedKey"', widget.keyStyle ?? const TextStyle(color: Colors.cyan)));
      spans.add(_styledText(': ', const TextStyle(color: Colors.white)));
      spans.addAll(_buildJson(entry.value, level + 1));

      if (i < entries.length - 1) {
        spans.add(_styledText(',', const TextStyle(color: Colors.white)));
      }
      spans.add(_styledText('\n', const TextStyle(color: Colors.white)));
    }

    spans.add(_styledText('${_indent(level)}}', const TextStyle(color: Colors.white)));
    return spans;
  }

  List<InlineSpan> _buildArray(List obj, int level) {
    if (obj.isEmpty) {
      return [_styledText('[]', const TextStyle(color: Colors.white))];
    }

    List<InlineSpan> spans = [];
    spans.add(_styledText('[\n', const TextStyle(color: Colors.white)));

    for (int i = 0; i < obj.length; i++) {
      spans.add(_styledText(_indent(level + 1), const TextStyle(color: Colors.white)));
      spans.addAll(_buildJson(obj[i], level + 1));

      if (i < obj.length - 1) {
        spans.add(_styledText(',', const TextStyle(color: Colors.white)));
      }
      spans.add(_styledText('\n', const TextStyle(color: Colors.white)));
    }

    spans.add(_styledText('${_indent(level)}]', const TextStyle(color: Colors.white)));
    return spans;
  }

  TextSpan _styledText(String text, TextStyle style) {
    return TextSpan(text: text, style: style);
  }

  String _indent(int level) {
    return '  ' * level;
  }
}

