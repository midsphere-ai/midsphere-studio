# Billing API Documentation

This document outlines the API endpoints available in the Billing module (`apps/billing`). All endpoints are prefixed with `/api/billing` (assuming the standard configuration connects the `billing_api` router to `/api/billing`).

**Authentication**: Most endpoints require authentication (handled by `NinjaAuthAdapter`). The Webhook endpoint is public.

## Subscription Management

### Get Subscription Plans
**GET** `/plans`
- **Description**: Retrieves a list of all active subscription plans available for purchase.
- **Response**: List of `SubscriptionPlan` objects (id, name, tier, price, features, is_active).

### Get Current Subscription
**GET** `/subscription`
- **Description**: Retrieves the authenticated user's current subscription details.
- **Response**: `UserSubscription` object (id, status, dates, etc.) or `null` if no subscription exists.

### Create Subscription
**POST** `/subscription/create`
- **Description**: Initiates a new subscription for the user.
- **Request Body**:
  ```json
  {
    "plan_id": "string"
  }
  ```
- **Response**: Returns subscription details including Razorpay Order ID to proceed with client-side payment.

### Change Subscription Plan
**POST** `/subscription/change`
- **Description**: Upgrades or downgrades the user's subscription plan.
- **Request Body**:
  ```json
  {
    "plan_id": "string",
    "immediate": boolean // Default: false (changes at end of cycle)
  }
  ```
- **Response**: Status message indicating if the change was immediate or scheduled.

### Cancel Active Subscription
**POST** `/subscription/cancel`
- **Description**: Cancels the user's current active subscription.
- **Query Parameters**:
  - `immediate` (bool, default: `false`): If true, cancels immediately; otherwise, cancels at the end of the billing cycle.
- **Response**: Confirmation message.

### Cancel Pending Subscription
**POST** `/subscription/cancel-pending`
- **Description**: Cancels a subscription that is in a 'pending' state (e.g., payment initiated but not completed).
- **Response**: Confirmation message.

### Reactivate Subscription
**POST** `/subscription/reactivate`
- **Description**: Reactivates a previously cancelled subscription if it hasn't fully expired.
- **Response**: Confirmation message.

### Check Grace Period
**GET** `/subscription/grace-period`
- **Description**: Checks if the user's subscription is currently in a grace period (after payment failure or expiration).
- **Response**: Status object containing `days_remaining`, `in_grace_period` (bool), and `grace_ends` date.

---

## Payments

### Verify Payment
**POST** `/verify-payment`
- **Description**: Verifies the Razorpay payment signature after a successful client-side transaction.
- **Request Body**:
  ```json
  {
    "payment_id": "string",
    "subscription_id": "string",
    "signature": "string"
  }
  ```
- **Response**: Verification success message.

### Payment History
**GET** `/payments`
- **Description**: Retrieves a paginated list of the user's past payments.
- **Response**: List of `Payment` objects.

### Retry Failed Payment
**POST** `/payment/retry`
- **Description**: Fetches details to retry a failed subscription payment.
- **Response**: Invoice details (`invoice_id`, `amount`, `short_url`) or 404 if no retry is applicable.

### Request Refund
**POST** `/refund`
- **Description**: Request a refund for a specific payment.
- **Request Body**:
  ```json
  {
    "payment_id": "string",
    "reason": "string" (optional)
  }
  ```
- **Response**: Refund details including `refund_id`.

---

## Webhooks

### Razorpay Webhook
**POST** `/webhook`
- **Auth**: Public (Signature verification handled internally).
- **Description**: Receives events from Razorpay (e.g., `subscription.charged`, `subscription.cancelled`, `payment.failed`) and updates local subscription state accordingly.
