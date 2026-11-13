/// Desktop/mobile implementation using dart:io File.
import 'dart:io';
import 'package:flutter/widgets.dart';

Widget buildImageFile(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
  );
}
