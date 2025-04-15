import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../Helper/cart_var.dart';
import '../../Provider/UserProvider.dart';

class StripeTransactionResponse {
  final String? message;
  final String? status;
  bool? success;
  StripeTransactionResponse({this.message, this.success, this.status});
}

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeService.apiBase}/payment_intents';
  static String? secret;
  static Map<String, String> headers = {
    'Authorization': 'Bearer ${StripeService.secret}',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  static init(String? stripeId, String? stripeMode) async {
    Stripe.publishableKey = stripeId ?? '';
    Stripe.merchantIdentifier = "App Identifier";
    await Stripe.instance.applySettings();
  }

  static Future<StripeTransactionResponse> payWithPaymentSheet(
      {String? amount,
      String? currency,
      String? from,
      BuildContext? context,
      String? awaitedOrderId,}) async {
    try {
      final paymentIntent = await StripeService.createPaymentIntent(
          amount, currency, from, context, awaitedOrderId,);
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'],
              applePay: const PaymentSheetApplePay(
                merchantCountryCode: 'IN',
              ),
              googlePay: const PaymentSheetGooglePay(
                merchantCountryCode: 'IN',
                testEnv: true,
              ),
              style: ThemeMode.light,
              merchantDisplayName: 'Test',),);
      await Stripe.instance.presentPaymentSheet();
      stripePayId = paymentIntent['id'];
      final response = await http.post(
          Uri.parse('${StripeService.paymentApiUrl}/$stripePayId'),
          headers: headers,);
      print("stripe-response-->$response");
      final getdata = json.decode(response.body);
      print("stripe-getdata-->$getdata");
      final statusOfTransaction = getdata['status'];
      print("trnsactionstatus--->$statusOfTransaction");
      if (statusOfTransaction == 'succeeded') {
        return StripeTransactionResponse(
            message: 'Transaction successful',
            success: true,
            status: statusOfTransaction,);
      } else if (statusOfTransaction == 'pending' ||
          statusOfTransaction == 'captured') {
        return StripeTransactionResponse(
            message: 'Transaction pending',
            success: true,
            status: statusOfTransaction,);
      } else {
        return StripeTransactionResponse(
            message: 'Transaction failed',
            success: false,
            status: statusOfTransaction,);
      }
    } on Exception catch (e) {
      if (e is StripeException) {
        return StripeTransactionResponse(
            message: 'Transaction failed: ${e.error.localizedMessage}',
            success: false,
            status: 'fail',);
      } else {
        return StripeTransactionResponse(
            message: 'Unforeseen error: $e',
            success: false,
            status: 'fail',);
      }
    }
  }

  static StripeTransactionResponse getPlatformExceptionErrorResult(err) {
    String message = 'Something went wrong';
    if (err.code == 'cancelled') {
      message = 'Transaction cancelled';
    }
    return StripeTransactionResponse(
        message: message, success: false, status: 'cancelled',);
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
      String? amount,
      String? currency,
      String? from,
      BuildContext? context,
      String? awaitedOrderID,) async {
    final String orderId =
        'wallet-refill-user-${context!.read<UserProvider>().userId}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';
    try {
      final Map<String, dynamic> parameter = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card',
        'description': from,
      };
      if (from == 'wallet') parameter['metadata[order_id]'] = orderId;
      if (from == 'order') parameter['metadata[order_id]'] = awaitedOrderID;
      final response = await http.post(Uri.parse(StripeService.paymentApiUrl),
          body: parameter, headers: StripeService.headers,);
      return jsonDecode(response.body);
    } catch (err) {
    }
    return null;
  }
}
