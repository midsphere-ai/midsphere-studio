import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/pages/settings/billing.dart';

/// Displays the current subscription plan with an upgrade button.
class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: AuthenticationProvider(),
      builder: (context, _) {
        final subscription = AuthenticationProvider().activeSubscription;
        final planName = subscription?.plan.name ?? 'Free plan';
        final planTier = subscription?.plan.tier ?? 'free';
        final isPaid = subscription?.isActive == true && planTier != 'free';
        final isPremium = planTier == 'premium' || planName == 'Midsphere Pro';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                planName,
                style: TextStyle(
                  fontSize: 13,
                  color: isPaid ? scheme.primary : scheme.mutedForeground,
                  fontWeight: isPaid ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (!isPremium) ...[
                SizedBox(width: 8),
                Container(width: 1, height: 14, color: scheme.border),
                SizedBox(width: 8),
                LinkButton(
                  density: ButtonDensity.compact,
                  onPressed: () => _navigateToBilling(context),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToBilling(BuildContext context) {
    RootShell.updateAndRefresh(
      ValueKey('main'),
      const BillingScreen(),
      'Subscription and Billing',
      LucideIcons.creditCard,
    );
  }
}
