import 'dart:io';
import 'package:arcane/arcane.dart';
import 'package:path/path.dart' as path;

class FileItem extends StatelessWidget {
  final File file;
  final VoidCallback onTap;

  const FileItem({super.key, required this.file, required this.onTap});

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
      case '.java':
      case '.kt':
      case '.py':
      case '.js':
      case '.cpp':
      case '.c':
        return LucideIcons.code;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
        return LucideIcons.image;
      case '.pdf':
        return LucideIcons.file;
      case '.txt':
      case '.md':
        return LucideIcons.text;
      case '.mp4':
      case '.mov':
      case '.avi':
        return LucideIcons.video;
      case '.mp3':
      case '.wav':
        return LucideIcons.music;
      case '.json':
      case '.xml':
        return LucideIcons.fileCode;
      default:
        return LucideIcons.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(file.path);
    final extension = path.extension(file.path);

    return GhostButton(
      density: ButtonDensity.iconDense,
      onPressed: onTap,
      child: Row(
        children: [
          SizedBox(width: 24),
          Icon(_getFileIcon(extension), size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
            ).small,
          ),
        ],
      ),
    );
  }
}
