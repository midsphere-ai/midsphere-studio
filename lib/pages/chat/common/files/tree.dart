import 'dart:io';
import 'package:arcane/arcane.dart';
import 'package:path/path.dart' as path;

import 'directory_item.dart';
import 'file_item.dart';

class FileSystemTree extends StatelessWidget {
  final Directory directory;
  final Function(File) onFileSelected;

  const FileSystemTree({
    super.key,
    required this.directory,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: directory.list().toList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final entities = snapshot.data ?? [];
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path.basename(a.path).compareTo(path.basename(b.path));
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entities.map((entity) {
            if (entity is Directory) {
              return DirectoryItem(
                directory: entity,
                onFileSelected: onFileSelected,
              );
            } else {
              return FileItem(
                file: entity as File,
                onTap: () => onFileSelected(entity),
              );
            }
          }).toList(),
        );
      },
    );
  }
}
