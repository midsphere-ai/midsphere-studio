import 'package:flutter_client/logics/domain/entities/billing/all.dart';

import '../../../data/helpers/general_utils.dart';
import '../base.dart';

enum BillingEndpoints implements Endpoint {
  getPlans,
  getCurrentSubscription,
  createSubscription,
  changeSubscriptionPlan,
  cancelActiveSubscription,
  cancelPendingSubscription,
  reactivateSubscription,
  checkGracePeriod,
  verifyPayment,
  getPaymentHistory,
  retryFailedPayment,
  requestRefund,
  createTicket,
  getTickets,
  getTicket,
  updateTicket,
  deleteTicket;

  @override
  String get value => "billing/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "billing";

  @override
  APIReference get requiredParams {
    switch (this) {
      case BillingEndpoints.getPlans:
        return APIReference(
          endpoint: "/plans",
          method: "GET",
          parameters: [],
          returnType: [List<Map>, SubscriptionPlan.fromJson],
        );
      case BillingEndpoints.getCurrentSubscription:
        return APIReference(
          endpoint: "/subscription",
          method: "GET",
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.createSubscription:
        return APIReference(
          endpoint: "/subscription/create",
          method: "POST",
          parameters: ['plan_id'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.changeSubscriptionPlan:
        return APIReference(
          endpoint: "/subscription/change",
          method: "POST",
          parameters: ['plan_id', 'immediate'],
          returnType: [bool],
        );
      case BillingEndpoints.cancelActiveSubscription:
        return APIReference(
          endpoint: "/subscription/cancel",
          method: "POST",
          parameters: ['immediate'],
          returnType: [bool],
        );
      case BillingEndpoints.cancelPendingSubscription:
        return APIReference(
          endpoint: "/subscription/cancel-pending",
          method: "POST",
          parameters: [],
          returnType: [bool],
        );
      case BillingEndpoints.reactivateSubscription:
        return APIReference(
          endpoint: "/subscription/reactivate",
          method: "POST",
          parameters: [],
          returnType: [bool],
        );
      case BillingEndpoints.checkGracePeriod:
        return APIReference(
          endpoint: "/subscription/grace-period",
          method: "GET",
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.verifyPayment:
        return APIReference(
          endpoint: "/verify-payment",
          method: "POST",
          parameters: ['payment_id', 'subscription_id', 'signature'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.getPaymentHistory:
        return APIReference(
          endpoint: "/payments",
          method: "GET",
          parameters: [],
          returnType: [List<Map>, Payment.fromJson],
        );
      case BillingEndpoints.retryFailedPayment:
        return APIReference(
          endpoint: "/payment/retry",
          method: "POST",
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.requestRefund:
        return APIReference(
          endpoint: "/refund",
          method: "POST",
          parameters: ['payment_id', 'reason'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.createTicket:
        return APIReference(
          endpoint: "/support/tickets",
          method: "POST",
          parameters: ['title', 'message'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
      case BillingEndpoints.getTickets:
        return APIReference(
          endpoint: "/support/tickets",
          method: "GET",
          parameters: [],
          returnType: [List<Map>, Ticket.fromJson],
        );
      case BillingEndpoints.getTicket:
        return APIReference(
          endpoint: "/support/tickets/{ticket_id}",
          method: "GET",
          parameters: ['ticket_id'],
          returnType: [Map, Ticket.fromJson],
        );
      case BillingEndpoints.updateTicket:
        return APIReference(
          endpoint: "/support/tickets/{ticket_id}",
          method: "PUT",
          parameters: ['ticket_id', 'title', 'message', 'status'],
          returnType: [Map, Ticket.fromJson],
        );
      case BillingEndpoints.deleteTicket:
        return APIReference(
          endpoint: "/support/tickets/{ticket_id}",
          method: "DELETE",
          parameters: ['ticket_id'],
          returnType: [bool],
        );
    }
  }
}
