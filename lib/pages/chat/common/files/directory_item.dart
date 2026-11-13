import 'dart:io';
import 'package:arcane/arcane.dart';
import 'package:flutter_client/pages/chat/common/files/tree.dart';
import 'package:path/path.dart' as path;

class DirectoryItem extends StatefulWidget {
  final Directory directory;
  final Function(File) onFileSelected;

  const DirectoryItem({
    super.key,
    required this.directory,
    required this.onFileSelected,
  });

  @override
  _DirectoryItemState createState() => _DirectoryItemState();
}

class _DirectoryItemState extends State<DirectoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dirName = path.basename(widget.directory.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GhostButton(
          density: ButtonDensity.iconDense,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded
                    ? LucideIcons.chevronDown
                    : LucideIcons.chevronRight,
                size: 16,
              ),
              Icon(
                _isExpanded ? Icons.folder_open : Icons.folder,
                size: 14,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  dirName,
                  overflow: TextOverflow.ellipsis,
                ).small,
              ),
            ],
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: FileSystemTree(
              directory: widget.directory,
              onFileSelected: widget.onFileSelected,
            ),
          ),
      ],
    );
  }
}
