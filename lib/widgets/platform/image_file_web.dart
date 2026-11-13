/// Web implementation - uses Image.network for blob/http URLs.
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

Widget buildImageFile(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  // On web, file_picker returns blob URLs (blob:http://...) or object URLs
  // which can be loaded via Image.network
  if (path.startsWith('blob:') || path.startsWith('http')) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.broken_image, size: 24),
          ),
        );
      },
    );
  }

  // Fallback for unsupported paths
  return SizedBox(
    width: width,
    height: height,
    child: const Center(
      child: Icon(Icons.image_not_supported, size: 24),
    ),
  );
}
