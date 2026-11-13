import 'package:flutter_client/logics/domain/entities/base/base.dart';

class SubscriptionPlan extends BaseModel {
  @override
  final String id;
  final String name;
  final String tier;
  final double price;
  final String? razorpayPlanId;
  final Map<String, dynamic> features;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.price,
    this.razorpayPlanId,
    required this.features,
    required this.isActive,
    // required this.createdAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: json['tier'] as String,
      price: json['price'] != null ? double.parse(json['price']) : 0,
      razorpayPlanId: json['razorpay_plan_id'] as String?,
      features: json['features'] as Map<String, dynamic>,
      isActive: json['is_active'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'price': price,
      'razorpay_plan_id': razorpayPlanId,
      'features': features,
      'is_active': isActive,
      // 'created_at': createdAt.toIso8601String(),
    };
  }
}
