import 'package:flutter_client/logics/domain/entities/base/repo.dart';

import '../base.dart';
import 'endpoint_enums.dart';

class Billing {
  static Future<dynamic> getPlans({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(repo, BillingEndpoints.getPlans, {});
  }

  static Future<dynamic> getCurrentSubscription() async {
    return NetworkConnector.callEndpoint(
        BillingEndpoints.getCurrentSubscription, {});
  }

  static Future<dynamic> createSubscription({required String planId}) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.createSubscription, {
      'plan_id': planId,
    });
  }

  static Future<dynamic> changeSubscriptionPlan(String planId,
      {bool immediate = false}) async {
    return NetworkConnector.callEndpoint(
        BillingEndpoints.changeSubscriptionPlan, {
      'plan_id': planId,
      'immediate': immediate,
    });
  }

  static Future<dynamic> cancelActiveSubscription(
      {bool immediate = false}) async {
    return NetworkConnector.callEndpoint(
        BillingEndpoints.cancelActiveSubscription, {
      'immediate': immediate,
    });
  }

  static Future<dynamic> cancelPendingSubscription() async {
    return NetworkConnector.callEndpoint(
        BillingEndpoints.cancelPendingSubscription, {});
  }

  static Future<dynamic> reactivateSubscription() async {
    return NetworkConnector.callEndpoint(
        BillingEndpoints.reactivateSubscription, {});
  }

  static Future<dynamic> checkGracePeriod() async {
    return NetworkConnector.callEndpoint(BillingEndpoints.checkGracePeriod, {});
  }

  static Future<dynamic> verifyPayment({
    required String paymentId,
    required String subscriptionId,
    required String signature,
  }) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.verifyPayment, {
      'payment_id': paymentId,
      'subscription_id': subscriptionId,
      'signature': signature,
    });
  }

  static Future<dynamic> getPaymentHistory({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(repo, BillingEndpoints.getPaymentHistory, {});
  }

  static Future<dynamic> retryFailedPayment() async {
    return NetworkConnector.callEndpoint(BillingEndpoints.retryFailedPayment, {});
  }

  static Future<dynamic> requestRefund({
    required String paymentId,
    String? reason,
  }) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.requestRefund, {
      'payment_id': paymentId,
      'reason': reason,
    });
  }

  static Future<dynamic> createTicket({
    required String title,
    required String message,
  }) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.createTicket, {
      'title': title,
      'message': message,
    });
  }

  static Future<dynamic> getTickets({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
        repo, BillingEndpoints.getTickets, {});
  }

  static Future<dynamic> getTicket({required String ticketId}) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.getTicket, {
      'ticket_id': ticketId,
    });
  }

  static Future<dynamic> updateTicket({
    required String ticketId,
    String? title,
    String? message,
    String? status,
  }) async {
    final Map<String, dynamic> params = {'ticket_id': ticketId};
    if (title != null) params['title'] = title;
    if (message != null) params['message'] = message;
    if (status != null) params['status'] = status;

    return NetworkConnector.callEndpoint(BillingEndpoints.updateTicket, params);
  }

  static Future<dynamic> deleteTicket({required String ticketId}) async {
    return NetworkConnector.callEndpoint(BillingEndpoints.deleteTicket, {
      'ticket_id': ticketId,
    });
  }
}
