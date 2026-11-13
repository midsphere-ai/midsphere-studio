part of 'task.dart';

/// A card widget for displaying enriched file attachments from agent messages.
/// Supports inline previews for images and text/code files.
class _AttachmentCard extends StatefulWidget {
  final EnrichedAttachment attachment;

  const _AttachmentCard({required this.attachment});

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();

  /// Check if this attachment type supports inline preview
  static bool supportsPreview(String mimeType) {
    return mimeType.startsWith('image/') ||
        mimeType.startsWith('text/') ||
        mimeType.contains('json') ||
        mimeType.contains('javascript') ||
        mimeType.contains('typescript') ||
        mimeType.contains('xml') ||
        mimeType.contains('yaml') ||
        mimeType.contains('markdown') ||
        mimeType.contains('html') ||
        mimeType.contains('css');
  }
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _isLoadingPreview = false;
  String? _textPreview;
  String? _previewError;

  // Maximum lines to show in preview
  static const int _maxPreviewLines = 12;
  // Maximum characters to fetch for preview
  static const int _maxPreviewChars = 2000;

  bool get _isTextFile {
    final mime = widget.attachment.mimeType;
    return mime.startsWith('text/') ||
        mime.contains('json') ||
        mime.contains('javascript') ||
        mime.contains('typescript') ||
        mime.contains('xml') ||
        mime.contains('yaml') ||
        mime.contains('markdown') ||
        mime.contains('html') ||
        mime.contains('css') ||
        mime.contains('python') ||
        mime.contains('dart');
  }

  bool get _isImageFile => widget.attachment.isImage;

  String _getLanguageFromMimeType(String mimeType) {
    if (mimeType.contains('javascript')) return 'javascript';
    if (mimeType.contains('typescript')) return 'typescript';
    if (mimeType.contains('json')) return 'json';
    if (mimeType.contains('xml')) return 'xml';
    if (mimeType.contains('yaml')) return 'yaml';
    if (mimeType.contains('html')) return 'html';
    if (mimeType.contains('css')) return 'css';
    if (mimeType.contains('python')) return 'python';
    if (mimeType.contains('dart')) return 'dart';
    if (mimeType.contains('markdown')) return 'markdown';
    if (mimeType.contains('java') && !mimeType.contains('javascript'))
      return 'java';
    if (mimeType.contains('c++') || mimeType.contains('cpp')) return 'cpp';
    if (mimeType.contains('csharp') || mimeType.contains('c#')) return 'csharp';
    if (mimeType.contains('ruby')) return 'ruby';
    if (mimeType.contains('go')) return 'go';
    if (mimeType.contains('rust')) return 'rust';
    if (mimeType.contains('php')) return 'php';
    if (mimeType.contains('sql')) return 'sql';
    if (mimeType.contains('shell') || mimeType.contains('bash')) return 'bash';
    return 'plaintext';
  }

  Future<void> _loadTextPreview() async {
    if (_textPreview != null || _isLoadingPreview) return;

    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });

    try {
      final url = _getDownloadUrl();
      final response = await Dio().get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Range': 'bytes=0-$_maxPreviewChars'},
        ),
      );

      if (response.data != null) {
        final lines = response.data!.split('\n');
        final previewLines = lines.take(_maxPreviewLines).join('\n');
        final hasMore =
            lines.length > _maxPreviewLines ||
            response.data!.length >= _maxPreviewChars;

        setState(() {
          _textPreview = hasMore ? '$previewLines\n...' : previewLines;
        });
      }
    } catch (e) {
      setState(() {
        _previewError = 'Could not load preview';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded && _isTextFile && _textPreview == null) {
      _loadTextPreview();
    }
  }

  IconData _getFileIcon(String mimeType) {
    // Images
    if (mimeType.startsWith('image/')) return LucideIcons.image;
    // Video
    if (mimeType.startsWith('video/')) return LucideIcons.video;
    // Audio
    if (mimeType.startsWith('audio/')) return LucideIcons.music;
    // PDF
    if (mimeType.contains('pdf')) return LucideIcons.fileText;
    // Spreadsheets (Excel, Google Sheets, etc.)
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('csv')) {
      return LucideIcons.fileSpreadsheet;
    }
    // Documents (Word, Google Docs, etc.)
    if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('rtf')) {
      return LucideIcons.fileText;
    }
    // Presentations (PowerPoint, Google Slides, etc.)
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return LucideIcons.presentation;
    }
    // Archives (zip, tar, rar, etc.)
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip') ||
        mimeType.contains('7z') ||
        mimeType.contains('compressed')) {
      return LucideIcons.fileArchive;
    }
    // Code and text files
    if (mimeType.startsWith('text/') ||
        mimeType.contains('json') ||
        mimeType.contains('javascript') ||
        mimeType.contains('typescript') ||
        mimeType.contains('python') ||
        mimeType.contains('dart') ||
        mimeType.contains('java') ||
        mimeType.contains('xml') ||
        mimeType.contains('yaml') ||
        mimeType.contains('html') ||
        mimeType.contains('css') ||
        mimeType.contains('markdown')) {
      return LucideIcons.fileCode;
    }
    // Executables and binaries
    if (mimeType.contains('executable') ||
        mimeType.contains('octet-stream') ||
        mimeType.contains('x-msdownload')) {
      return LucideIcons.fileCog;
    }
    // Database files
    if (mimeType.contains('sql') || mimeType.contains('database')) {
      return LucideIcons.database;
    }
    // Font files
    if (mimeType.contains('font') ||
        mimeType.contains('woff') ||
        mimeType.contains('ttf')) {
      return LucideIcons.type;
    }
    // Default
    return LucideIcons.file;
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.startsWith('image/')) return Colors.blue;
    if (mimeType.startsWith('video/')) return Colors.purple;
    if (mimeType.startsWith('audio/')) return Colors.orange;
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('csv')) {
      return Colors.green;
    }
    if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('rtf')) {
      return Colors.blue;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Colors.orange;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip') ||
        mimeType.contains('7z') ||
        mimeType.contains('compressed')) {
      return Colors.amber;
    }
    if (mimeType.startsWith('text/') ||
        mimeType.contains('json') ||
        mimeType.contains('javascript') ||
        mimeType.contains('xml') ||
        mimeType.contains('html') ||
        mimeType.contains('css')) {
      return Colors.cyan;
    }
    if (mimeType.contains('executable') || mimeType.contains('octet-stream')) {
      return Theme.of(context).colorScheme.mutedForeground;
    }
    return Theme.of(context).colorScheme.mutedForeground;
  }

  String _getDownloadUrl() {
    final url = widget.attachment.url;
    // If URL is already absolute (starts with http/https), use it directly
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Otherwise, it's a relative path - prepend the API base URL
    return '${DataConstants.url.replaceAll(RegExp(r'/$'), '')}$url';
  }

  Future<void> _handleDownload() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final attachment = widget.attachment;

      // For enriched attachments, use the URL directly
      if (!attachment.isLegacy && attachment.url.isNotEmpty) {
        final downloadUrl = _getDownloadUrl();
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open download URL');
        }
      } else {
        // For legacy attachments (sandbox paths), try to open directly
        OpenFile.open(attachment.url);
      }
    } catch (e) {
      // Silently handle file open errors
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final fileColor = _getFileColor(attachment.mimeType);
    final canPreview = _isImageFile || _isTextFile;

    return Container(
      width: _isExpanded ? 400 : 280,
      child: Card(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row (always visible)
            GestureDetector(
              onTap: _handleDownload,
              child: Row(
                children: [
                  // Thumbnail or icon
                  if (_isImageFile && !attachment.isLegacy)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Toolkit.radius),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CachedNetworkImage(
                          imageUrl: _getDownloadUrl(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildIconPlaceholder(fileColor),
                          errorWidget: (context, url, error) =>
                              _buildIconPlaceholder(fileColor),
                        ),
                      ),
                    )
                  else
                    _buildIconPlaceholder(fileColor),
                  SizedBox(width: 12),
                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).small,
                        SizedBox(height: 2),
                        Row(
                          children: [
                            if (attachment.size > 0) ...[
                              Text(
                                Toolkit.formatFileSize(attachment.size),
                              ).mono.xSmall.muted,
                              SizedBox(width: 8),
                            ],
                            Text(
                              _getMimeTypeLabel(attachment.mimeType),
                            ).xSmall.muted,
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Loading or download icon
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(LucideIcons.download, size: 16).iconMutedForeground(),
                ],
              ),
            ),

            // Expand/collapse button for previewable files
            if (canPreview && !attachment.isLegacy) ...[
              SizedBox(height: 8),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                    ).iconMutedForeground(),
                    SizedBox(width: 4),
                    Text(
                      _isExpanded ? 'Hide preview' : 'Show preview',
                    ).xSmall.muted,
                  ],
                ),
              ),
            ],

            // Preview content
            if (_isExpanded) ...[
              SizedBox(height: 8),
              _buildPreviewContent(fileColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(Color fileColor) {
    final attachment = widget.attachment;

    // Image preview - larger inline view
    if (_isImageFile && !attachment.isLegacy) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Toolkit.radius),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300),
          child: CachedNetworkImage(
            imageUrl: _getDownloadUrl(),
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              height: 150,
              color: fileColor.withAlpha(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              height: 100,
              color: fileColor.withAlpha(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.imageOff, color: fileColor),
                    SizedBox(height: 4),
                    Text('Could not load image').xSmall.muted,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Text/Code preview
    if (_isTextFile) {
      if (_isLoadingPreview) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.muted.withAlpha(30),
            borderRadius: BorderRadius.circular(Toolkit.radius),
          ),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      if (_previewError != null) {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.destructive.withAlpha(20),
            borderRadius: BorderRadius.circular(Toolkit.radius),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 14,
                color: Theme.of(context).colorScheme.destructive,
              ),
              SizedBox(width: 8),
              Text(_previewError!).small,
            ],
          ),
        );
      }

      if (_textPreview != null) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final language = _getLanguageFromMimeType(attachment.mimeType);

        return ClipRRect(
          borderRadius: BorderRadius.circular(Toolkit.radius),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: HighlightView(
                _textPreview!,
                language: language,
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.all(12),
                textStyle: TextStyle(fontFamily: 'GeistMono', fontSize: 12),
              ),
            ),
          ),
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildIconPlaceholder(Color fileColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: fileColor.withAlpha(25),
        borderRadius: BorderRadius.circular(Toolkit.radius),
      ),
      child: Center(
        child: Icon(
          _getFileIcon(widget.attachment.mimeType),
          size: 24,
          color: fileColor,
        ),
      ),
    );
  }

  String _getMimeTypeLabel(String mimeType) {
    if (mimeType.startsWith('image/')) return 'Image';
    if (mimeType.startsWith('video/')) return 'Video';
    if (mimeType.startsWith('audio/')) return 'Audio';
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('csv')) {
      return 'Spreadsheet';
    }
    if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('rtf')) {
      return 'Document';
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return 'Slides';
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip') ||
        mimeType.contains('7z') ||
        mimeType.contains('compressed')) {
      return 'Archive';
    }
    if (mimeType.startsWith('text/') ||
        mimeType.contains('json') ||
        mimeType.contains('javascript') ||
        mimeType.contains('typescript') ||
        mimeType.contains('python') ||
        mimeType.contains('dart') ||
        mimeType.contains('java') ||
        mimeType.contains('xml') ||
        mimeType.contains('yaml') ||
        mimeType.contains('html') ||
        mimeType.contains('css') ||
        mimeType.contains('markdown')) {
      return 'Code';
    }
    if (mimeType.contains('executable') || mimeType.contains('x-msdownload')) {
      return 'Executable';
    }
    if (mimeType.contains('sql') || mimeType.contains('database')) {
      return 'Database';
    }
    if (mimeType.contains('font') ||
        mimeType.contains('woff') ||
        mimeType.contains('ttf')) {
      return 'Font';
    }
    return 'File';
  }
}
