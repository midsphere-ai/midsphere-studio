import 'dart:io';
import 'package:arcane/arcane.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_highlight/flutter_highlight.dart';

class FileViewerWidget extends StatelessWidget {
  final File file;

  const FileViewerWidget({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final extension = path.extension(file.path).toLowerCase();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(path.basename(file.path)).small),
              GhostButton(
                density: ButtonDensity.iconDense,
                shape: ButtonShape.circle,
                onPressed: () {
                  OpenFile.open(file.path);
                },
                child: Icon(LucideIcons.externalLink),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.card,
            ),
            child: _buildViewer(extension),
          ),
        ),
      ],
    );
  }

  Widget _buildViewer(String extension) {
    switch (extension) {
      case '.txt':
      case '.log':
      case '.md':
        return TextFileViewer(file: file);

      case '.dart':
      case '.java':
      case '.kt':
      case '.swift':
      case '.js':
      case '.py':
      case '.cpp':
      case '.c':
      case '.h':
      case '.css':
      case '.html':
      case '.xml':
      case '.json':
      case '.yaml':
      case '.yml':
        return CodeFileViewer(file: file);

      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.bmp':
      case '.webp':
        return ImageFileViewer(file: file);

      default:
        return UnsupportedFileViewer(file: file);
    }
  }
}

// Text File Viewer
class TextFileViewer extends StatefulWidget {
  final File file;

  const TextFileViewer({super.key, required this.file});

  @override
  _TextFileViewerState createState() => _TextFileViewerState();
}

class _TextFileViewerState extends State<TextFileViewer> {
  String? content;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final text = await widget.file.readAsString();
      setState(() {
        content = text;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error loading file: $error'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: SelectableText(content ?? '').small,
    );
  }
}

// Code File Viewer
class CodeFileViewer extends StatefulWidget {
  final File file;

  const CodeFileViewer({super.key, required this.file});

  @override
  _CodeFileViewerState createState() => _CodeFileViewerState();
}

class _CodeFileViewerState extends State<CodeFileViewer> {
  String? content;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final text = await widget.file.readAsString();
      setState(() {
        content = text;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _getLanguage() {
    final extension = path.extension(widget.file.path).toLowerCase();
    switch (extension) {
      case '.dart':
        return 'dart';
      case '.java':
        return 'java';
      case '.kt':
        return 'kotlin';
      case '.swift':
        return 'swift';
      case '.js':
        return 'javascript';
      case '.py':
        return 'python';
      case '.cpp':
      case '.c':
        return 'cpp';
      case '.css':
        return 'css';
      case '.html':
        return 'xml';
      case '.json':
        return 'json';
      case '.xml':
        return 'xml';
      case '.yaml':
      case '.yml':
        return 'yaml';
      default:
        return 'plaintext';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: HighlightView(
        content ?? '',
        language: _getLanguage(),
        theme: draculaTheme,
        padding: EdgeInsets.all(12),
        textStyle: GoogleFonts.ibmPlexMono(fontSize: 14),
      ),
    );
  }
}

// Image File Viewer
class ImageFileViewer extends StatelessWidget {
  final File file;

  const ImageFileViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.ban, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load image').muted,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// PDF File Viewer

// Unsupported File Viewer
class UnsupportedFileViewer extends StatelessWidget {
  final File file;

  const UnsupportedFileViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(file.path);
    final extension = path.extension(file.path);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.file,
              size: 100,
            ),
            SizedBox(height: 24),
            Text('Preview not available').muted,
            Text(fileName, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'File type: $extension',
              style: TextStyle(fontSize: 14),
            ).small.muted,
            SizedBox(height: 32),
            IconButton.ghost(
              icon: Icon(LucideIcons.externalLink),
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
