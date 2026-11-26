import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Оплата відбувається на сервері збереженим токеном Stripe (pm_...), який створюється
// один раз під час додавання картки. Застосунок більше не передає номер картки чи CVV
// при оплаті і не створює метод оплати повторно.
class PaymentController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  static const String paymentMethodMissingCode = 'payment_method_missing';

  bool isLoading = false;
  String message = '';

  // true, якщо сервер повідомив, що в користувача немає дійсного методу оплати
  bool paymentMethodMissing = false;

  Future<String?> payForRental(int rentalId,
      int userId,
      String token,) async {
    isLoading = true;
    message = '';
    paymentMethodMissing = false;
    notifyListeners();

    final url = Uri.parse('$serverApi/api/Payment/pay/$rentalId');
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
      } else {
        // Сервер повертає зрозуміле повідомлення, зокрема коли немає дійсного методу оплати
        // (errorCode = payment_method_missing) — тоді сума додається до заборгованості.
        paymentMethodMissing = data['errorCode'] == paymentMethodMissingCode;
        message =
            data['message'] ?? "Payment failed. Added to outstanding balance.";
      }
      return message;
    } catch (_) {
      message =
          "Network error. The trip amount has been added to your outstanding balance.";
      return message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> payOutstandingBalance(
    String token,
  ) async {
    isLoading = true;
    message = '';
    paymentMethodMissing = false;
    notifyListeners();

    final url = Uri.parse('$serverApi/api/Payment/OutstandingBalance');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 202) {
        message =
            responseData['message'] ?? "Outstanding balance paid successfully";
        return true;
      } else {
        paymentMethodMissing =
            responseData['errorCode'] == paymentMethodMissingCode;
        message = responseData['message'] ?? "Payment failed";
        return false;
      }
    } catch (e) {
      message = "Network error during payment.";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
