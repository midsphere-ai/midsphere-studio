import 'dart:ui';

import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'package:flutter_client/logics/domain/entities/billing/all.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';
import 'package:flutter_client/pages/settings/components/razorpay.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:intl/intl.dart';

import '../../widgets/builders/item_builder_list_card.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final items = [
    {
      "id": "1",
      "name": "Loading Plan...",
      "price": "0",
      "tier": "basic",
      "features": {},
      "is_active": true,
    },
    {
      "id": "1",
      "name": "Loading Plan...",
      "price": "0",
      "tier": "basic",
      "features": {},
      "is_active": true,
    },
    {
      "id": "1",
      "name": "Loading Plan...",
      "price": "0",
      "tier": "basic",
      "features": {},
      "is_active": true,
    },
  ];

  final double _progress = 60;

  @override
  Widget build(BuildContext context) {
    return LimitedWindowBox(
      customWidth: 840,
      child: ListenableBuilder(
        listenable: AuthenticationProvider(),
        builder: (context, _) {
          final subscription = AuthenticationProvider().activeSubscription;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(32),
                  (subscription != null &&
                          subscription.isActive &&
                          subscription.plan.tier != "free")
                      ? _buildActiveSubscription(subscription)
                      : _buildNoActiveSubscription(),
                  const Gap(32),
                  Text("Usage limits").h4,
                  const Gap(16),
                  _usageLimits(),
                  const Gap(32),
                  Text("Available plans").h4,
                  const Gap(16),
                  _buildPlans(subscription),
                  const Gap(32),
                  Text("Payment history").h4,
                  const Gap(16),
                  _buildPaymentHistory(),
                  Gap(32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _usageLimitWidget(String label, {int index = 0}) {
    final subscription = AuthenticationProvider().activeSubscription;
    if (subscription == null) {
      return SizedBox.shrink();
    }

    final limits = subscription.extras[label];
    if (limits == null) {
      return SizedBox.shrink();
    }

    final limit = _parseDouble(limits['limit']);
    final used = _parseDouble(limits['used']);
    final displayLabel = limits['label'] as String;

    return AnimatedListItem(
      index: index,
      staggerDelay: AnimationConstants.staggerDelaySlow,
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayLabel),
          Column(
            spacing: 4,
            children: [
              SizedBox(
                width: 400,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(used.toStringAsFixed(0)).mono.xSmall.muted,
                    Text(limit.toStringAsFixed(0)).mono.xSmall.muted,
                  ],
                ),
              ),
              SizedBox(
                width: 400,
                child: TweenAnimationBuilder<double>(
                  duration: AnimationConstants.progressBar,
                  curve: AnimationConstants.entranceCurve,
                  tween: Tween<double>(begin: 0, end: used.clamp(0, limit)),
                  builder: (context, value, child) {
                    return Progress(
                      progress: value,
                      min: 0,
                      max: limit,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usageLimits() {
    if (AuthenticationProvider().activeSubscription == null) {
      return SizedBox.shrink();
    }

    final extras = AuthenticationProvider().activeSubscription?.extras;

    if (extras == null || extras.isEmpty) {
      return SizedBox.shrink();
    }

    final keys = extras.keys.toList();
    return Column(
      spacing: 8,
      children: [
        for (int i = 0; i < keys.length; i++)
          _usageLimitWidget(keys[i], index: i),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return ItemBuilderBlocCard(
      blocKey: 'paymentHistory',
      paginated: true,
      shrinkWrap: true,
      customHeight: 70,
      dataSource: Billing.getPaymentHistory,
      dataSourceArgs: {},
      onDataEmpty: "No payment history found",
      onError: "Error fetching payments",
      placeHolderItems: List.generate(
        3,
        (index) => {"id": "load", "amount": 0},
      ),
      item: (data) {
        Payment payment;
        if (data is Payment) {
          payment = data;
        } else {
          if (data['id'] == 'load') {
            return Card(child: ListTile(title: Text("Loading...")));
          }
          payment = Payment.fromJson(data);
        }

        final dateFormat = DateFormat('MMM d, yyyy');
        return ListTile(
          title: Text("\$${payment.amount}"),
          subtitle: Text(
            "${dateFormat.format(payment.createdAt)} • ${payment.method?.toUpperCase() ?? 'UNKNOWN'}",
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: payment.status == 'captured'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: Theme.of(context).borderRadiusMd,
              border: Border.all(
                color: payment.status == 'captured' ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              payment.status.toUpperCase(),
              style: TextStyle(
                color: payment.status == 'captured' ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSubscription(Subscription subscription) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    return FadeSlideScaleTransition(
      duration: AnimationConstants.entranceFadeSlow,
      scaleStart: 0.97,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 6,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("You are on").h3,
                      Text(subscription.plan.name).h3,
                    ],
                  ),
                ],
              ),
              if (subscription.autoRenew) const Gap(16),
              if (!subscription.autoRenew)
                Column(
                  children: [
                    Gap(12),
                    if (subscription.endDate != null )Text(
                      "Your subscription will end on ${dateFormat.format(subscription.endDate!)}",
                    ),
                    Gap(12),
                  ],
                ),

              Row(
                spacing: 16,
                children: [
                  _buildDetailItem(
                    "Price",
                    "\$${subscription.plan.price.toStringAsFixed(2)} / month",
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Theme.of(context).colorScheme.border,
                  ),
                  if(subscription.startDate != null)
                  _buildDetailItem(
                    "Start Date",
                    dateFormat.format(subscription.startDate!),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Theme.of(context).colorScheme.border,
                  ),
                  if(subscription.endDate != null)
                  _buildDetailItem(
                    subscription.autoRenew ? "Renews On" : "Ends on",
                    dateFormat.format(subscription.endDate!),
                  ),
                ],
              ),
              const Gap(24),
              Row(
                children: [
                  if (subscription.autoRenew)
                    DestructiveButton(
                      onPressed: _cancelSubscription,
                      child: Text("Cancel Subscription").bold,
                    )
                  else if (subscription.isActive && !subscription.autoRenew)
                    PrimaryButton(
                      onPressed: _reactivateSubscription,
                      child: Text("Reactivate Subscription").bold,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label).small.muted, const Gap(4), Text(value).medium],
    );
  }

  Widget _buildNoActiveSubscription() {
    return FadeSlideTransition(
      duration: AnimationConstants.entranceFade,
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.podcast, size: 48),
            const Gap(16),
            Text("No Active Subscription").h4,
            Text("Subscribe to a plan to unlock premium features.").small.muted,
          ],
        ),
      ),
    );
  }

  Widget _buildPlans(Subscription? activeSubscription) {
    return ItemBuilderBlocCard(
      blocKey: 'billingPlans',
      paginated: false,
      shrinkWrap: true,
      customHeight: 550,
      customWidth: 400,
      dataSource: Billing.getPlans,
      dataSourceArgs: {},
      onDataEmpty: "No plans found",
      onError: "Error fetching plans",
      placeHolderItems: items,
      item: (data) {
        SubscriptionPlan plan;
        if (data is SubscriptionPlan) {
          plan = data;
        } else {
          return Card();
        }

        final isCurrentPlan =
            activeSubscription?.isActive == true &&
            activeSubscription?.plan.id == plan.id;

        return Card(
          filled: true,
          fillColor: Theme.of(context).colorScheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).h4,
                  if (isCurrentPlan) PrimaryBadge(child: Text("Active").bold),
                ],
              ),
              (plan.price == 0)
                  ? SizedBox.shrink()
                  : Text("\$${plan.price.toStringAsFixed(0)} /month").h3,
              const Gap(8),
              if (plan.features.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: plan.features.length,
                  itemBuilder: (context, index) {
                    final feature = plan.features.values.toList()[index];
                    final featureValue = feature.toList().first;
                    if (featureValue == 0) {
                      return SizedBox.shrink();
                    }
                    if (featureValue == false) {
                      return SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: Colors.green,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(feature.toList().last).muted.small,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const Gap(16),
              if (isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  child: OutlineButton(
                    onPressed: () async {
                      await _cancelSubscription(immediate: true);
                    },
                    child: Text("Cancel immediately").bold,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: RazorpayButton(plan: plan),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reactivateSubscription() async {
    try {
      await Billing.reactivateSubscription();
      if (mounted) {
        _showToast("Success", "Subscription reactivated successfully");
        await AuthenticationProvider().refreshSubscription();
      }
    } catch (e) {
      if (mounted) {
        _showToast("Error", "Failed to reactivate subscription", isError: true);
      }
    }
  }

  Future<void> _cancelSubscription({bool immediate = false}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Cancel Subscription?"),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.",
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                SecondaryButton(
                  onPressed: () {
                    closeOverlay(context);
                  },
                  child: Text("Keep Subscription"),
                ),
                TextButton(
                  onPressed: () {
                    closeOverlay(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await Billing.cancelActiveSubscription(
          immediate: result['immediate'] ?? false,
        );

        if (mounted) {
          _showToast("Success", "Subscription cancelled");

          await AuthenticationProvider().refreshSubscription();
        }
      } catch (e) {
        if (mounted) {
          _showToast("Error", "Failed to cancel subscription", isError: true);
        }
      }
    }
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
