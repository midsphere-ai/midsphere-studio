import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for handling nested JSON decode patterns.
///
/// Many body widgets receive data that may be double/triple encoded JSON strings,
/// wrapped in lists, or contain nested result structures. This class provides
/// standardized methods to extract the actual data.
class JsonDecodeUtils {
  JsonDecodeUtils._();

  /// Decodes potentially nested JSON data.
  ///
  /// Handles cases where:
  /// - Data is already decoded (Map/List)
  /// - Data is a JSON string
  /// - Data is a List containing a JSON string
  /// - Data is double-encoded JSON
  ///
  /// Returns the decoded data, or the original data if decoding fails.
  static dynamic decodeNested(dynamic rawData) {
    dynamic data = rawData;

    // First level decode if string
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (e) {
        debugPrint('[JsonDecodeUtils] First decode failed, keeping as string: $e');
        return data;
      }
    }

    // Handle list wrapper with nested JSON string
    if (data is List && data.isNotEmpty) {
      var firstItem = data[0];
      if (firstItem is String) {
        try {
          firstItem = jsonDecode(firstItem);
        } catch (e) {
          debugPrint('[JsonDecodeUtils] Nested decode failed, keeping as string: $e');
          // Return original list if inner decode fails
          return data;
        }
      }
      return firstItem;
    }

    return data;
  }

  /// Extracts a list from various data structures.
  ///
  /// Looks for lists in common keys: 'results', 'items', 'data', 'rows'.
  /// Returns an empty list if no list data is found.
  static List<dynamic> extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      // Try common list keys in order of priority
      for (final key in ['results', 'items', 'data', 'rows']) {
        if (data[key] is List) {
          return data[key] as List;
        }
      }
      // Convert map entries to list as fallback
      return data.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
    }

    return [];
  }

  /// Extracts the main content string from a Map.
  ///
  /// Checks common content keys: 'message', 'content', 'text', 'result', 'output'.
  /// Returns null if no content field is found.
  static String? extractContent(Map<dynamic, dynamic> data) {
    for (final key in ['message', 'content', 'text', 'result', 'output']) {
      if (data[key] != null) {
        return data[key].toString();
      }
    }
    return null;
  }

  /// Extracts file path from a Map.
  ///
  /// Checks common path keys: 'file_path', 'path', 'image_path', 'video_path'.
  static String? extractPath(Map<dynamic, dynamic> data) {
    for (final key in ['file_path', 'path', 'image_path', 'video_path']) {
      if (data[key] != null) {
        return data[key].toString();
      }
    }
    return null;
  }

  /// Extracts URL from a Map.
  ///
  /// Checks common URL keys: 'url', 'image_url', 'video_url', 'link'.
  static String? extractUrl(Map<dynamic, dynamic> data) {
    for (final key in ['url', 'image_url', 'video_url', 'link']) {
      if (data[key] != null) {
        return data[key].toString();
      }
    }
    return null;
  }

  /// Checks if the response indicates success.
  static bool isSuccess(Map<dynamic, dynamic> data) {
    return data['success'] == true;
  }

  /// Extracts metadata map from a response.
  static Map<String, dynamic>? extractMetadata(Map<dynamic, dynamic> data) {
    if (data['metadata'] is Map) {
      return Map<String, dynamic>.from(data['metadata']);
    }
    return null;
  }
}
