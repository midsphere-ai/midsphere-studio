// ===================== ENUMS =====================
enum MessageType { user, assistant, system, tool, summary }

enum MessageRole { human, ai, system, tool }

// ===================== MARKETPLACE ADDON =====================
class AddonBaseResult {
  final String addonId;

  AddonBaseResult({required this.addonId});

  factory AddonBaseResult.fromJson(Map<String, dynamic> json) {
    return AddonBaseResult(addonId: json['addon_id']);
  }

  Map<String, dynamic> toJson() => {'addon_id': addonId};
}

class UserAddonBaseResult {
  final String userAddonId;

  UserAddonBaseResult({required this.userAddonId});

  factory UserAddonBaseResult.fromJson(Map<String, dynamic> json) {
    return UserAddonBaseResult(userAddonId: json['user_addon_id']);
  }

  Map<String, dynamic> toJson() => {'user_addon_id': userAddonId};
}

class RegisterAddonResult extends UserAddonBaseResult {
  final bool isNew;

  RegisterAddonResult({required super.userAddonId, required this.isNew});

  factory RegisterAddonResult.fromJson(Map<String, dynamic> json) {
    return RegisterAddonResult(
      userAddonId: json['user_addon_id'],
      isNew: json['is_new'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'user_addon_id': userAddonId,
    'is_new': isNew,
  };
}

class UnRegisterAddonResult extends UserAddonBaseResult {
  final bool removed;

  UnRegisterAddonResult({required super.userAddonId, required this.removed});

  factory UnRegisterAddonResult.fromJson(Map<String, dynamic> json) {
    return UnRegisterAddonResult(
      userAddonId: json['user_addon_id'],
      removed: json['removed'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'user_addon_id': userAddonId,
    'removed': removed,
  };
}

class AddonAuthLink extends UserAddonBaseResult {
  final String authLink;

  AddonAuthLink({required super.userAddonId, required this.authLink});

  factory AddonAuthLink.fromJson(Map<String, dynamic> json) {
    return AddonAuthLink(
      userAddonId: json['user_addon_id'],
      authLink: json['auth_link'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'user_addon_id': userAddonId,
    'auth_link': authLink,
  };
}

class AddonAuthenticationStatus extends UserAddonBaseResult {
  final bool isAuthorised;

  AddonAuthenticationStatus({
    required super.userAddonId,
    required this.isAuthorised,
  });

  factory AddonAuthenticationStatus.fromJson(Map<String, dynamic> json) {
    return AddonAuthenticationStatus(
      userAddonId: json['user_addon_id'],
      isAuthorised: json['is_authorised'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'user_addon_id': userAddonId,
    'is_authorised': isAuthorised,
  };
}

enum AddonStatus {
  notInitiated,
  initiated,
  pending,
  active,
  expired,
  failed,
  inactive,
  unknown;

  static AddonStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'NOT_INITIATED' => AddonStatus.notInitiated,
      'INITIATED' => AddonStatus.initiated,
      'PENDING' => AddonStatus.pending,
      'ACTIVE' => AddonStatus.active,
      'EXPIRED' => AddonStatus.expired,
      'FAILED' => AddonStatus.failed,
      'INACTIVE' => AddonStatus.inactive,
      _ => AddonStatus.unknown,
    };
  }

  String get displayText => switch (this) {
    AddonStatus.notInitiated => 'Not connected',
    AddonStatus.initiated => 'Waiting for you to authorize...',
    AddonStatus.pending => 'Processing authorization...',
    AddonStatus.active => 'Connected',
    AddonStatus.expired => 'Link expired - please try again',
    AddonStatus.failed => 'Authorization failed',
    AddonStatus.inactive => 'Connection disabled',
    AddonStatus.unknown => 'Checking status...',
  };

  bool get shouldContinuePolling =>
    this == AddonStatus.initiated || this == AddonStatus.pending;
}

class AddonConnectionStatus extends UserAddonBaseResult {
  final String addonName;
  final AddonStatus status;
  final bool isActive;
  final bool authComplete;

  AddonConnectionStatus({
    required super.userAddonId,
    required this.addonName,
    required this.status,
    required this.isActive,
    required this.authComplete,
  });

  factory AddonConnectionStatus.fromJson(Map<String, dynamic> json) {
    return AddonConnectionStatus(
      userAddonId: json['user_addon_id'],
      addonName: json['addon_name'] ?? '',
      status: AddonStatus.fromString(json['status'] ?? 'UNKNOWN'),
      isActive: json['is_active'] ?? false,
      authComplete: json['auth_complete'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'user_addon_id': userAddonId,
    'addon_name': addonName,
    'status': status.name.toUpperCase(),
    'is_active': isActive,
    'auth_complete': authComplete,
  };
}

enum RegenerateAuthError {
  alreadyAuthorised,
  authLinkNotExpired,
  nonExistentAddon,
  unauthorizedAccess,
  unknown;

  static RegenerateAuthError? fromErrorCode(String? code) {
    if (code == null) return null;
    return switch (code.toUpperCase()) {
      'ALREADY_AUTHORISED' => RegenerateAuthError.alreadyAuthorised,
      'AUTH_LINK_NOT_EXPIRED' => RegenerateAuthError.authLinkNotExpired,
      'NON_EXISTENT_ADDON' => RegenerateAuthError.nonExistentAddon,
      'UNAUTHORIZED_ACCESS' => RegenerateAuthError.unauthorizedAccess,
      _ => RegenerateAuthError.unknown,
    };
  }

  String get displayText => switch (this) {
    RegenerateAuthError.alreadyAuthorised => 'Already authorized',
    RegenerateAuthError.authLinkNotExpired => 'Authorization still in progress',
    RegenerateAuthError.nonExistentAddon => 'Add-on not found',
    RegenerateAuthError.unauthorizedAccess => 'Permission denied',
    RegenerateAuthError.unknown => 'An error occurred',
  };
}

class ExpandedAddon {
  final Map<String, dynamic> marketplaceAddon;
  final Map<String, dynamic>? userAddon;
  final List<Map<String, dynamic>> features;

  ExpandedAddon({
    required this.marketplaceAddon,
    required this.userAddon,
    required this.features,
  });

  factory ExpandedAddon.fromJson(Map<String, dynamic> json) {
    return ExpandedAddon(
      marketplaceAddon: json['marketplace_addon'],
      userAddon: json['user_addon'],
      features: List<Map<String, dynamic>>.from(json['features']),
    );
  }

  Map<String, dynamic> toJson() => {
    'marketplace_addon': marketplaceAddon,
    'user_addon': userAddon,
    'features': features,
  };
}

class RegisterAddon {
  final String addonId;

  RegisterAddon({required this.addonId});

  factory RegisterAddon.fromJson(Map<String, dynamic> json) {
    return RegisterAddon(addonId: json['addon_id']);
  }

  Map<String, dynamic> toJson() => {'addon_id': addonId};
}

class UserAddonRequest {
  final String userAddonId;

  UserAddonRequest({required this.userAddonId});

  factory UserAddonRequest.fromJson(Map<String, dynamic> json) {
    return UserAddonRequest(userAddonId: json['user_addon_id']);
  }

  Map<String, dynamic> toJson() => {'user_addon_id': userAddonId};
}

class SearchUserAddons {
  final String query;
  final bool authComplete;

  SearchUserAddons({required this.query, required this.authComplete});

  factory SearchUserAddons.fromJson(Map<String, dynamic> json) {
    return SearchUserAddons(
      query: json['query'],
      authComplete: json['auth_complete'],
    );
  }

  Map<String, dynamic> toJson() => {
    'query': query,
    'auth_complete': authComplete,
  };
}

class SearchMarketAddons {
  final String query;

  SearchMarketAddons({required this.query});

  factory SearchMarketAddons.fromJson(Map<String, dynamic> json) {
    return SearchMarketAddons(query: json['query']);
  }

  Map<String, dynamic> toJson() => {'query': query};
}

// ===================== CONVERSATION =====================
class ConversationCreateResult {
  final String conversationId;
  final bool isNew;

  ConversationCreateResult({required this.conversationId, required this.isNew});

  factory ConversationCreateResult.fromJson(Map<String, dynamic> json) {
    return ConversationCreateResult(
      conversationId: json['conversation_id'],
      isNew: json['is_new'],
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'is_new': isNew,
  };
}

class FileUploadResult {
  final String fileId;
  final String filename;
  final int size;
  final String mimeType;

  FileUploadResult({
    required this.fileId,
    required this.filename,
    required this.size,
    required this.mimeType,
  });

  factory FileUploadResult.fromJson(Map<String, dynamic> json) {
    return FileUploadResult(
      fileId: json['file_id'],
      filename: json['filename'],
      size: json['size'],
      mimeType: json['mime_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'file_id': fileId,
    'filename': filename,
    'size': size,
    'mime_type': mimeType,
  };
}

class MessageData {
  final String id;
  final String content;
  final MessageRole role;
  final MessageType category;
  final Map<String, dynamic> metadata;

  MessageData({
    required this.id,
    required this.content,
    required this.role,
    required this.category,
    required this.metadata,
  });

  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      id: json['id'],
      content: json['content'],
      role: MessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      category: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.toString().split('.').last,
    'category': category.toString().split('.').last,
    'metadata': metadata,
  };
}

class SearchThreads {
  final String query;

  SearchThreads({required this.query});

  factory SearchThreads.fromJson(Map<String, dynamic> json) {
    return SearchThreads(query: json['query']);
  }

  Map<String, dynamic> toJson() => {'query': query};
}

class NewConversationRequest {
  final String appId;

  NewConversationRequest({required this.appId});

  factory NewConversationRequest.fromJson(Map<String, dynamic> json) {
    return NewConversationRequest(appId: json['app_id']);
  }

  Map<String, dynamic> toJson() => {'app_id': appId};
}

class FetchConversationMessagesRequest {
  final String conversationId;

  FetchConversationMessagesRequest({required this.conversationId});

  factory FetchConversationMessagesRequest.fromJson(Map<String, dynamic> json) {
    return FetchConversationMessagesRequest(
      conversationId: json['conversation_id'],
    );
  }

  Map<String, dynamic> toJson() => {'conversation_id': conversationId};
}

class ConversationCreateResponse {
  final String conversationId;
  final bool isNew;
  final String message;

  ConversationCreateResponse({
    required this.conversationId,
    required this.isNew,
    this.message = "Conversation created successfully",
  });

  factory ConversationCreateResponse.fromJson(Map<String, dynamic> json) {
    return ConversationCreateResponse(
      conversationId: json['conversation_id'],
      isNew: json['is_new'],
      message: json['message'] ?? "Conversation created successfully",
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'is_new': isNew,
    'message': message,
  };
}

class DeleteResponse {
  final String message;
  final int? deletedCount;

  DeleteResponse({required this.message, this.deletedCount});

  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      message: json['message'],
      deletedCount: json['deleted_count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'deleted_count': deletedCount,
  };
}

class FileUploadResponse {
  final String fileId;
  final String filename;
  final int size;
  final String mimeType;
  final String message;

  FileUploadResponse({
    required this.fileId,
    required this.filename,
    required this.size,
    required this.mimeType,
    this.message = "File uploaded successfully",
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      fileId: json['file_id'],
      filename: json['filename'],
      size: json['size'],
      mimeType: json['mime_type'],
      message: json['message'] ?? "File uploaded successfully",
    );
  }

  Map<String, dynamic> toJson() => {
    'file_id': fileId,
    'filename': filename,
    'size': size,
    'mime_type': mimeType,
    'message': message,
  };
}

class HealthResponse {
  final String status;
  final String version;
  final bool cacheEnabled;
  final String timestamp;

  HealthResponse({
    required this.status,
    required this.version,
    required this.cacheEnabled,
    required this.timestamp,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'],
      version: json['version'],
      cacheEnabled: json['cache_enabled'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'version': version,
    'cache_enabled': cacheEnabled,
    'timestamp': timestamp,
  };
}

class FileDownloadResponse {
  final String url;
  final String filename;
  final String mimeType;
  final int? size;

  FileDownloadResponse({
    required this.url,
    required this.filename,
    required this.mimeType,
    this.size,
  });

  factory FileDownloadResponse.fromJson(Map<String, dynamic> json) {
    return FileDownloadResponse(
      url: json['url'],
      filename: json['filename'],
      mimeType: json['mime_type'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'filename': filename,
    'mime_type': mimeType,
    'size': size,
  };
}

/// Represents an enriched file attachment from the backend.
/// Handles both old format (simple strings) and new format (full StoredFile info).
class EnrichedAttachment {
  final String id;
  final String name;
  final String url;
  final int size;
  final String mimeType;

  EnrichedAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.mimeType,
  });

  /// Check if the attachment is an enriched object (new format)
  static bool isEnriched(dynamic attachment) {
    return attachment is Map<String, dynamic> && attachment.containsKey('id');
  }

  /// Parse an attachment from either old format (string) or new format (object)
  static EnrichedAttachment? tryParse(dynamic attachment) {
    if (attachment == null) return null;

    // New enriched format (object with id, name, url, etc.)
    if (attachment is Map<String, dynamic>) {
      if (attachment.containsKey('id')) {
        return EnrichedAttachment(
          id: attachment['id']?.toString() ?? '',
          name: attachment['name']?.toString() ?? 'Attachment',
          url: attachment['url']?.toString() ?? '',
          size: (attachment['size'] as num?)?.toInt() ?? 0,
          mimeType: attachment['mime_type']?.toString() ?? 'application/octet-stream',
        );
      }
    }

    // Old format (string - file path or ID)
    if (attachment is String) {
      final fileName = attachment.split('/').last;
      return EnrichedAttachment(
        id: attachment, // Use the path/ID as the identifier
        name: fileName,
        url: attachment,
        size: 0,
        mimeType: _guessMimeType(fileName),
      );
    }

    return null;
  }

  /// Parse a list of attachments from mixed formats
  static List<EnrichedAttachment> parseList(dynamic attachments) {
    if (attachments == null) return [];

    List<dynamic> attachmentList;
    if (attachments is String) {
      // Handle comma-separated string format
      attachmentList = attachments.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (attachments is List) {
      attachmentList = attachments;
    } else {
      return [];
    }

    return attachmentList
        .map((a) => tryParse(a))
        .whereType<EnrichedAttachment>()
        .toList();
  }

  /// Guess MIME type from file extension
  static String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      // Images
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'ico':
        return 'image/x-icon';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'rtf':
        return 'application/rtf';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      // Spreadsheets
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      // Presentations
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';
      // Text and code files
      case 'txt':
        return 'text/plain';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'ts':
        return 'application/typescript';
      case 'py':
        return 'text/x-python';
      case 'dart':
        return 'application/dart';
      case 'java':
        return 'text/x-java-source';
      case 'kt':
        return 'text/x-kotlin';
      case 'swift':
        return 'text/x-swift';
      case 'go':
        return 'text/x-go';
      case 'rs':
        return 'text/x-rust';
      case 'c':
      case 'h':
        return 'text/x-c';
      case 'cpp':
      case 'hpp':
      case 'cc':
        return 'text/x-c++';
      case 'cs':
        return 'text/x-csharp';
      case 'php':
        return 'text/x-php';
      case 'rb':
        return 'text/x-ruby';
      case 'sh':
      case 'bash':
        return 'text/x-shellscript';
      case 'sql':
        return 'text/x-sql';
      case 'xml':
        return 'application/xml';
      case 'yaml':
      case 'yml':
        return 'application/yaml';
      case 'toml':
        return 'application/toml';
      // Archives
      case 'zip':
        return 'application/zip';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
      case 'gzip':
        return 'application/gzip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'bz2':
        return 'application/x-bzip2';
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      // Fonts
      case 'ttf':
        return 'font/ttf';
      case 'otf':
        return 'font/otf';
      case 'woff':
        return 'font/woff';
      case 'woff2':
        return 'font/woff2';
      // Executables
      case 'exe':
        return 'application/x-msdownload';
      case 'dmg':
        return 'application/x-apple-diskimage';
      case 'deb':
        return 'application/vnd.debian.binary-package';
      case 'rpm':
        return 'application/x-rpm';
      case 'apk':
        return 'application/vnd.android.package-archive';
      // Database
      case 'db':
      case 'sqlite':
      case 'sqlite3':
        return 'application/x-sqlite3';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if this is an image file
  bool get isImage => mimeType.startsWith('image/') && !mimeType.contains('svg');

  /// Check if this is a legacy attachment (old format without enriched data)
  bool get isLegacy => size == 0 && !url.startsWith('/media/') && !url.startsWith('http');

  factory EnrichedAttachment.fromJson(Map<String, dynamic> json) {
    return EnrichedAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Attachment',
      url: json['url']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'size': size,
    'mime_type': mimeType,
  };
}
