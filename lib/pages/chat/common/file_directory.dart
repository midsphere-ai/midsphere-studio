import 'dart:io';
import 'package:arcane/arcane.dart';

import 'files/tree.dart';
import 'files/viewers.dart';

class FileExplorerWithViewer extends StatefulWidget {
  final String path;

  const FileExplorerWithViewer({super.key, required this.path});
  @override
  _FileExplorerWithViewerState createState() => _FileExplorerWithViewerState();
}

class _FileExplorerWithViewerState extends State<FileExplorerWithViewer> {
  late Directory rootDirectory;
  File? selectedFile;

  @override
  void initState() {
    super.initState();
    // Set your root directory here
    rootDirectory = Directory(widget.path);
  }

  void _onFileSelected(File file) {
    setState(() {
      selectedFile = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar with tree view
        Container(
          width: 200,
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Theme.of(context).colorScheme.border),
            ),
          ),
          child: FutureBuilder<bool>(
            future: rootDirectory.exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.data == false) {
                return Center(child: Text('Workspace not found').small);
              }
              return SingleChildScrollView(
                child: FileSystemTree(
                  directory: rootDirectory,
                  onFileSelected: _onFileSelected,
                ),
              );
            },
          ),
        ),
        // Main content area with file viewer
        Expanded(
          child: selectedFile == null
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.card,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 48).iconMutedForeground(),
                        SizedBox(height: 16),
                        Text(
                          'Select a file to view',
                          style: TextStyle(fontSize: 18),
                        ).muted.small,
                      ],
                    ),
                  ),
                )
              : FileViewerWidget(
                  key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  file: selectedFile!,
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// TREE VIEW COMPONENTS
// ============================================================================

// ============================================================================
// FILE VIEWER COMPONENTS
// ============================================================================
