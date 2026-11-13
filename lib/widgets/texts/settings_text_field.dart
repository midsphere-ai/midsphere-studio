import 'package:arcane/arcane.dart';

/// A text field widget for settings pages.
///
/// This widget displays a text field with an icon and a label.
class SettingsTextField extends StatelessWidget {
  /// The icon to display before the text field.
  final IconData icon;

  /// The label to display as a placeholder in the text field.
  final String label;

  /// The controller for the text field.
  final TextEditingController? controller;

  final bool withOutPadding;
  final bool isTextArea;

  /// Creates a new [SettingsTextField] widget.
  ///
  /// The [icon] and [label] parameters are required.
  const SettingsTextField({
    super.key,
    required this.icon,
    required this.label,
    this.controller,
    this.withOutPadding = false,
    this.isTextArea = false
  });

  @override
  Widget build(BuildContext context) {
    if (withOutPadding) {
      return TextField(
        controller: controller,
        initialValue: controller?.text,
        placeholder: Text(label),
        features: [InputFeature.leading(Icon(icon))],
      );
    }

    if (isTextArea){
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextArea(
          controller: controller,
          placeholder: Text(label),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        placeholder: Text(label),
        features: [InputFeature.leading(Icon(icon))],
      ),
    );
  }
}
