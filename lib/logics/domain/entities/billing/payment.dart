import 'package:flutter_client/logics/domain/entities/base/base.dart';

class Payment extends BaseModel {
  @override
  final String id;
  final String amount;
  final String currency;
  final String status;
  final String? method;
  final DateTime createdAt;
  final String? description;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.method,
    required this.createdAt,
    this.description,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      amount: json['amount'],
      currency: json['currency'] as String,
      status: json['status'] as String,
      method: json['method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'created_at': createdAt.toIso8601String(),
      'description': description,
    };
  }
}
