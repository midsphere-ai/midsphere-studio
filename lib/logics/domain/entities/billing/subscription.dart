import 'package:flutter_client/logics/domain/entities/base/base.dart';
import 'package:flutter_client/logics/domain/entities/billing/subscription_plan.dart';

class Subscription extends BaseModel {
  @override
  final String id;
  final SubscriptionPlan plan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final Map extras;
  final String? razorpaySubscriptionId;

  Subscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.extras,
    this.razorpaySubscriptionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      autoRenew: json['auto_renew'] as bool,
      extras: json['usage_schema'] ?? {},
      razorpaySubscriptionId: json['razorpay_subscription_id'] ?? "",
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan.toJson(),
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'usage_schema': extras,
      'razorpay_subscription_id': razorpaySubscriptionId,
    };
  }

  bool get isActive => status == 'active';
}
