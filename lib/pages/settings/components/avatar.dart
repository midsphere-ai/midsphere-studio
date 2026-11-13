import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';

/// A widget that displays a user's avatar.
///
/// This widget displays a user's avatar with a tooltip showing their name.
class AccountAvatar extends StatelessWidget {
  /// Creates a new [AccountAvatar] widget.
  const AccountAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        (AuthenticationProvider().loggedInUser?.name?.trim().isNotEmpty ??
            false)
        ? AuthenticationProvider().loggedInUser!.name!
        : "Default Account";
    return SecondaryButton(
      shape: ButtonShape.circle,
      onPressed: () {},
      child: Text(
        Avatar.getInitials(userName),
      ).base,
    );
  }
}
