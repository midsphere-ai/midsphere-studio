import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';

/// A helper class for showing toasts.
class ToastHelper {
  /// Shows a toast with a title and description.
  static void show(BuildContext context, String title, IconData leading) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            leading: Icon(leading),
            title: Text(title),
            trailingAlignment: Alignment.center,
          ),
        );
      },
      location: ToastLocation.topCenter,
    );
  }
}
