import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  bool isLoading = false;
  String message = '';

  Future<String?> payForRental(
    int rentalId,
    int userId,
    String token,
    String? cardNum,
    String? cardExpiryDate,
    String? cardCvv,
    String? userEmail,
  ) async {
    isLoading = true;
    message = '';
    notifyListeners();

    if (cardNum == null || cardExpiryDate == null) {
      isLoading = false;
      notifyListeners();
      return "No card found. The trip amount has been added to your outstanding balance.";
    }

    int expMonth = 0;
    int expYear = 0;
    try {
      final parts = cardExpiryDate.split('/');
      expMonth = int.parse(parts[0]);
      expYear = int.parse("20${parts[1]}");
    } catch (_) {
      isLoading = false;
      notifyListeners();
      return "Invalid card date format. Amount added to outstanding balance.";
    }

    String? freshPaymentMethodId;
    String? stripeErrorMessage;

    try {
      Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails(
          number: cardNum,
          expirationMonth: expMonth,
          expirationYear: expYear,
          cvc: cardCvv,
        ),
      );

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(email: userEmail),
          ),
        ),
      );
      freshPaymentMethodId = paymentMethod.id;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains("incorrect_number") ||
          errorStr.contains("invalid") ||
          errorStr.contains("number")) {
        stripeErrorMessage = "Invalid card number entered.";
      } else if (errorStr.contains("expired") || errorStr.contains("expiry")) {
        stripeErrorMessage = "The card has expired.";
      } else if (errorStr.contains("cvc") || errorStr.contains("cvv")) {
        stripeErrorMessage = "Invalid CVC/CVV code.";
      } else {
        stripeErrorMessage = "Bank card error.";
      }
    }

    if (stripeErrorMessage != null) {
      isLoading = false;
      notifyListeners();
      return "$stripeErrorMessage Amount added to outstanding balance.";
    }

    String endpoint = '$serverApi/api/Payment/pay/$rentalId/$userId';
    if (freshPaymentMethodId != null && freshPaymentMethodId.isNotEmpty) {
      endpoint += '?paymentMethodId=$freshPaymentMethodId';
    }

    final url = Uri.parse(endpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        message = data['message'] ?? "Success: Payment processed successfully.";
        return message;
      } else {
        String backendMsg = data['message'] ?? "Payment failed";
        if (stripeErrorMessage != null) {
          message = "$stripeErrorMessage $backendMsg";
        } else {
          message = backendMsg;
        }
        return message;
      }
    } catch (_) {
      message =
          "Network error. The trip amount has been added to your outstanding balance.";
      return message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ЗМІНЕНО НА ПОЗИЦІЙНІ АРГУМЕНТИ (БЕЗ ФІГУРНИХ ДУЖОК)
  Future<bool> payOutstandingBalance(
    int userId,
    String token,
    String? cardNum,
    String? cardExpiryDate,
    String? cardCvv,
    String? userEmail,
  ) async {
    isLoading = true;
    message = '';
    notifyListeners();

    String? freshPaymentMethodId;
    String? stripeErrorMessage;

    if (cardNum != null && cardExpiryDate != null) {
      try {
        int expMonth = 0;
        int expYear = 0;
        final parts = cardExpiryDate.split('/');
        expMonth = int.parse(parts[0]);
        expYear = int.parse("20${parts[1]}");

        Stripe.instance.dangerouslyUpdateCardDetails(
          CardDetails(
            number: cardNum,
            expirationMonth: expMonth,
            expirationYear: expYear,
            cvc: cardCvv,
          ),
        );

        final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(email: userEmail),
            ),
          ),
        );
        freshPaymentMethodId = paymentMethod.id;
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains("incorrect_number") ||
            errorStr.contains("invalid") ||
            errorStr.contains("number")) {
          stripeErrorMessage = "Invalid card number entered.";
        } else if (errorStr.contains("expired") ||
            errorStr.contains("expiry")) {
          stripeErrorMessage = "The card has expired.";
        } else if (errorStr.contains("cvc") || errorStr.contains("cvv")) {
          stripeErrorMessage = "Invalid CVC/CVV code.";
        } else {
          stripeErrorMessage = "Bank card error.";
        }
      }
    }

    if (stripeErrorMessage != null) {
      message = stripeErrorMessage!;
      isLoading = false;
      notifyListeners();
      return false;
    }

    String endpoint = '$serverApi/api/Payment/OutstandingBalance/$userId';
    if (freshPaymentMethodId != null && freshPaymentMethodId.isNotEmpty) {
      endpoint += '?paymentMethodId=$freshPaymentMethodId';
    }

    final url = Uri.parse(endpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token,
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 202) {
        message =
            responseData['message'] ?? "Outstanding balance paid successfully";
        return true;
      } else {
        message = responseData['message'] ?? "Payment failed";
        return false;
      }
    } catch (e) {
      message = "Network error during payment: " + e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}