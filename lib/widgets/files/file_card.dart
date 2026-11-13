import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logics/data/helpers/general_utils.dart';
import '../../logics/domain/entities/memory/misc/file.dart';
import '../../logics/domain/entities/memory/misc/schemas.dart';
import '../../logics/domain/usecases/memory/memory_usecase.dart';
import '../state/toast_helper.dart';

enum FileCardSize { small, medium, large }

class FileCard extends StatefulWidget {
  final StoredFile file;
  final FileCardSize size;
  final VoidCallback? onTap;
  final bool showThumbnail;

  const FileCard({
    super.key,
    required this.file,
    this.size = FileCardSize.medium,
    this.onTap,
    this.showThumbnail = true,
  });

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleDownload() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Memory.downloadFile(fileId: widget.file.id);

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
    } catch (e) {
      String errorMessage = 'Failed to download file';

      if (e.toString().contains('403')) {
        errorMessage = "You don't have permission to access this file";
      } else if (e.toString().contains('404')) {
        errorMessage = 'File not found';
      }

      setState(() => _error = errorMessage);

      if (mounted) {
        ToastHelper.show(context, errorMessage, LucideIcons.circleAlert);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return LucideIcons.image;
    if (mimeType.startsWith('video/')) return LucideIcons.video;
    if (mimeType.startsWith('audio/')) return LucideIcons.music;
    if (mimeType.contains('pdf')) return LucideIcons.fileText;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return LucideIcons.fileSpreadsheet;
    }
    if (mimeType.contains('document') || mimeType.contains('word')) {
      return LucideIcons.fileText;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return LucideIcons.presentation;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip')) {
      return LucideIcons.fileArchive;
    }
    if (mimeType.contains('text/') || mimeType.contains('json')) {
      return LucideIcons.fileCode;
    }
    return LucideIcons.file;
  }

  Color _getFileColor(BuildContext context, String mimeType) {
    if (mimeType.startsWith('image/')) return Colors.blue;
    if (mimeType.startsWith('video/')) return Colors.purple;
    if (mimeType.startsWith('audio/')) return Colors.orange;
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return Colors.green;
    }
    if (mimeType.contains('document') || mimeType.contains('word')) {
      return Colors.blue;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Colors.orange;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip')) {
      return Colors.amber;
    }
    return Theme.of(context).colorScheme.mutedForeground;
  }

  bool _isImageFile(String mimeType) {
    return mimeType.startsWith('image/') &&
        !mimeType.contains('svg') &&
        !mimeType.contains('ico');
  }

  double get _iconSize {
    switch (widget.size) {
      case FileCardSize.small:
        return 24;
      case FileCardSize.medium:
        return 32;
      case FileCardSize.large:
        return 48;
    }
  }

  double get _thumbnailSize {
    switch (widget.size) {
      case FileCardSize.small:
        return 40;
      case FileCardSize.medium:
        return 56;
      case FileCardSize.large:
        return 80;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      onPressed: widget.onTap ?? _handleDownload,
      children: [
        Row(
          children: [
            _buildThumbnail(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).small,
                  SizedBox(height: 4),
                  Text(Toolkit.formatFileSize(widget.file.size)).mono.xSmall.muted,
                  if (_error != null) ...[
                    SizedBox(height: 4),
                    Text(_error!, style: TextStyle(color: Colors.red)).xSmall,
                  ],
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(LucideIcons.download, size: 16).iconMutedForeground(),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    final isImage = _isImageFile(widget.file.mimeType);

    if (widget.showThumbnail && isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Toolkit.radius),
        child: SizedBox(
          width: _thumbnailSize,
          height: _thumbnailSize,
          child: CachedNetworkImage(
            imageUrl: widget.file.file,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildIconPlaceholder(),
            errorWidget: (context, url, error) => _buildIconPlaceholder(),
          ),
        ),
      );
    }

    return _buildIconPlaceholder();
  }

  Widget _buildIconPlaceholder() {
    final fileColor = _getFileColor(context, widget.file.mimeType);
    return Container(
      width: _thumbnailSize,
      height: _thumbnailSize,
      decoration: BoxDecoration(
        color: fileColor.withAlpha(25),
        borderRadius: BorderRadius.circular(Toolkit.radius),
      ),
      child: Center(
        child: Icon(
          _getFileIcon(widget.file.mimeType),
          size: _iconSize,
          color: fileColor,
        ),
      ),
    );
  }
}

class FileCardCompact extends StatefulWidget {
  final StoredFile file;
  final VoidCallback? onTap;

  const FileCardCompact({
    super.key,
    required this.file,
    this.onTap,
  });

  @override
  State<FileCardCompact> createState() => _FileCardCompactState();
}

class _FileCardCompactState extends State<FileCardCompact> {
  bool _isLoading = false;

  Future<void> _handleDownload() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await Memory.downloadFile(fileId: widget.file.id);

      if (response is FileDownloadResponse) {
        final uri = Uri.parse(response.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return LucideIcons.image;
    if (mimeType.startsWith('video/')) return LucideIcons.video;
    if (mimeType.startsWith('audio/')) return LucideIcons.music;
    if (mimeType.contains('pdf')) return LucideIcons.fileText;
    return LucideIcons.file;
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      onPressed: widget.onTap ?? _handleDownload,
      child: _isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getFileIcon(widget.file.mimeType), size: 14),
                SizedBox(width: 6),
                Text(widget.file.name).mono.xSmall,
              ],
            ),
    );
  }
}
