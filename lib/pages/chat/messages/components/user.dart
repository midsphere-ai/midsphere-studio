import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../logics/data/global_logics.dart';
import '../../../../logics/data/helpers/general_utils.dart';
import '../../../../logics/domain/entities/memory/misc/schemas.dart';
import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/state/toast_helper.dart';

/// A widget that displays a user's message in a chat bubble.
class UserMessageBubble extends StatefulWidget {
  /// The message to display.
  final TextMessage message;

  /// Creates a new [UserMessageBubble] widget.
  ///
  /// The [message] parameter is required.
  const UserMessageBubble({super.key, required this.message});

  @override
  State<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<UserMessageBubble> {
  @override
  Widget build(BuildContext context) {
    // Show placeholder loading state using skeleton
    if (widget.message.metadata?['status'] == 'PLACEHOLDER') {
      return _buildPlaceholder();
    }

    final rawFiles = widget.message.metadata?['files'];
    final attachments = EnrichedAttachment.parseList(rawFiles);
    final hasAttachments = attachments.isNotEmpty;

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        spacing: 8,
        children: [
          if (hasAttachments) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var attachment in attachments)
                  _EnrichedFileAttachment(attachment: attachment),
              ],
            ),
          ],
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(Theme.of(context).radiusXl),
            ),
            child: SelectableText(
              widget.message.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondaryForeground,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(Theme.of(context).radiusXl),
        ),
        child: Text('Loading message...'),
      ),
    ).asSkeleton();
  }
}

class _EnrichedFileAttachment extends StatefulWidget {
  final EnrichedAttachment attachment;

  const _EnrichedFileAttachment({required this.attachment});

  @override
  State<_EnrichedFileAttachment> createState() => _EnrichedFileAttachmentState();
}

class _EnrichedFileAttachmentState extends State<_EnrichedFileAttachment> {
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _isLoadingPreview = false;
  String? _textPreview;
  String? _previewError;

  static const int _maxPreviewLines = 10;
  static const int _maxPreviewChars = 1500;

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

  bool get _canPreview => (_isImageFile || _isTextFile) && !widget.attachment.isLegacy;

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
    if (mimeType.contains('java') && !mimeType.contains('javascript')) return 'java';
    if (mimeType.contains('c++') || mimeType.contains('cpp')) return 'cpp';
    if (mimeType.contains('go')) return 'go';
    if (mimeType.contains('rust')) return 'rust';
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
        final hasMore = lines.length > _maxPreviewLines || response.data!.length >= _maxPreviewChars;

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
    if (mimeType.contains('font') || mimeType.contains('woff') || mimeType.contains('ttf')) {
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

  String _getFileTypeLabel(String mimeType) {
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
    if (mimeType.contains('font') || mimeType.contains('woff') || mimeType.contains('ttf')) {
      return 'Font';
    }
    return 'File';
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
      // For enriched attachments with a direct URL, use it
      if (!widget.attachment.isLegacy && widget.attachment.url.isNotEmpty) {
        final downloadUrl = _getDownloadUrl();
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open download URL');
        }
      } else {
        // For legacy attachments, use the download endpoint
        final response = await Memory.downloadFile(fileId: widget.attachment.id);

        if (response is FileDownloadResponse) {
          final uri = Uri.parse(response.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not open download URL');
          }
        } else {
          throw Exception('Invalid response from server');
        }
      }
    } catch (e) {
      String errorMessage = 'Failed to download file';

      if (e.toString().contains('403')) {
        errorMessage = "You don't have permission to access this file";
      } else if (e.toString().contains('404')) {
        errorMessage = 'File not found';
      }

      if (mounted) {
        ToastHelper.show(context, errorMessage, LucideIcons.circleAlert);
      }
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
    final isImage = attachment.isImage && !attachment.isLegacy;

    // Expanded view with preview
    if (_isExpanded) {
      return Container(
        constraints: BoxConstraints(maxWidth: 320),
        child: Card(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                children: [
                  _buildIconContainer(fileColor),
                  SizedBox(width: 10),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getFileTypeLabel(attachment.mimeType)).xSmall.muted,
                            if (attachment.size > 0) ...[
                              Text(' · ').xSmall.muted,
                              Text(Toolkit.formatFileSize(attachment.size)).mono.xSmall.muted,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _toggleExpanded,
                        child: Icon(LucideIcons.chevronUp, size: 16).iconMutedForeground(),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleDownload,
                        child: _isLoading
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(LucideIcons.download, size: 16).iconMutedForeground(),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Preview content
              _buildPreviewContent(fileColor),
            ],
          ),
        ),
      );
    }

    // Compact view
    return Card(
      onPressed: _canPreview ? _toggleExpanded : _handleDownload,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show thumbnail for images, icon for all other file types
                if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CachedNetworkImage(
                        imageUrl: _getDownloadUrl(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildIconContainer(fileColor),
                        errorWidget: (context, url, error) => _buildIconContainer(fileColor),
                      ),
                    ),
                  )
                else
                  _buildIconContainer(fileColor),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 150),
                      child: Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).small,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getFileTypeLabel(attachment.mimeType)).xSmall.muted,
                        if (attachment.size > 0) ...[
                          Text(' · ').xSmall.muted,
                          Text(Toolkit.formatFileSize(attachment.size)).mono.xSmall.muted,
                        ],
                      ],
                    ),
                  ],
                ),
                if (_canPreview) ...[
                  SizedBox(width: 6),
                  Icon(LucideIcons.eye, size: 12).iconMutedForeground(),
                ],
              ],
            ),
    );
  }

  Widget _buildIconContainer(Color fileColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: fileColor.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          _getFileIcon(widget.attachment.mimeType),
          size: 14,
          color: fileColor,
        ),
      ),
    );
  }

  Widget _buildPreviewContent(Color fileColor) {
    final attachment = widget.attachment;

    // Image preview
    if (_isImageFile && !attachment.isLegacy) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Toolkit.radius),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200),
          child: CachedNetworkImage(
            imageUrl: _getDownloadUrl(),
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              height: 100,
              color: fileColor.withAlpha(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              height: 80,
              color: fileColor.withAlpha(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.imageOff, color: fileColor, size: 20),
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
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.muted.withAlpha(30),
            borderRadius: BorderRadius.circular(Toolkit.radius),
          ),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      if (_previewError != null) {
        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.destructive.withAlpha(20),
            borderRadius: BorderRadius.circular(Toolkit.radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, size: 12, color: Theme.of(context).colorScheme.destructive),
              SizedBox(width: 6),
              Text(_previewError!).xSmall,
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
            constraints: BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: HighlightView(
                _textPreview!,
                language: language,
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.all(10),
                textStyle: TextStyle(
                  fontFamily: 'GeistMono',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }

      // Load preview if not loaded yet
      _loadTextPreview();
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.muted.withAlpha(30),
          borderRadius: BorderRadius.circular(Toolkit.radius),
        ),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return SizedBox.shrink();
  }
}
