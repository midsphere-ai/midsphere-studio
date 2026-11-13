import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/logics/domain/entities/billing/all.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';
import 'package:url_launcher/url_launcher.dart';

class RazorpayButton extends StatefulWidget {
  final SubscriptionPlan plan;

  const RazorpayButton({super.key, required this.plan});

  @override
  State<RazorpayButton> createState() => _RazorpayButtonState();
}

class _RazorpayButtonState extends State<RazorpayButton> {
  bool isLoading = false;
  bool showRefresh = false;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      leading: isLoading
          ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator())
          : null,
      onPressed: isLoading
          ? null
          : () async {
              if (showRefresh) {
                setState(() {
                  isLoading = true;
                });
                await AuthenticationProvider().refreshSubscription();
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
                return;
              }

              final activeSubscription =
                  AuthenticationProvider().activeSubscription;
              if (activeSubscription != null && activeSubscription.isActive) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Change Subscription Plan?"),
                    content: Text(
                      "Are you sure you want to change your subscription to ${widget.plan.name}? This will take effect immediately.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Confirm Change"),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                setState(() {
                  isLoading = true;
                });

                try {
                  await Billing.changeSubscriptionPlan(
                    widget.plan.id,
                    immediate: true,
                  );
                  _showToast(
                    "Success",
                    "Subscription plan changed successfully",
                  );
                  await AuthenticationProvider().refreshSubscription();
                } catch (e) {
                  _showToast(
                    "Error",
                    "Failed to change subscription plan: $e",
                    isError: true,
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
              } else {
                setState(() {
                  isLoading = true;
                });

                try {
                  final createOrderInfo = await Billing.createSubscription(
                    planId: widget.plan.id,
                  );

                  if (createOrderInfo != null &&
                      createOrderInfo['short_url'] != null) {
                    final uri = Uri.parse(createOrderInfo['short_url']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                      if (mounted) {
                        setState(() {
                          showRefresh = true;
                        });
                      }
                    } else {
                      if (mounted) {
                        _showToast(
                          "Error",
                          "Could not launch payment page",
                          isError: true,
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      _showToast(
                        "Error",
                        "Failed to create subscription",
                        isError: true,
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) _showToast("Error", e.toString(), isError: true);
                } finally {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
              }
            },
      child: Text(
        isLoading
            ? "Processing..."
            : (showRefresh ? "Verify Payment" : "Subscribe"),
      ).bold,
    );
  }

  void _showToast(String title, String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            leading: Icon(
              isError ? LucideIcons.x : LucideIcons.check,
              color: isError ? Colors.red : Colors.green,
            ),
            title: Text(title),
            subtitle: Text(message),
          ),
        );
      },
      location: ToastLocation.topCenter,
    );
  }
}
