import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';

/// A widget that displays a different widget depending on whether the device
/// is a mobile device or a desktop device.
class MobileView extends StatelessWidget {
  /// The widget to display on mobile devices.
  final Widget mobile;

  /// The widget to display on desktop devices.
  final Widget desktop;

  /// Creates a new [MobileView] widget.
  ///
  /// The [mobile] and [desktop] parameters are required.
  const MobileView({super.key, required this.mobile, required this.desktop});

  @override
  Widget build(BuildContext context) {
    return Toolkit.isMobile(context) ? mobile : desktop;
  }
}
