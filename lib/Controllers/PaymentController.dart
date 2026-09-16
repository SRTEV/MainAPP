import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  bool isLoading = false;
  String message = '';

  Future payForRental(
    int rentalId,
    int userId,
    String token,
    String? paymentMethodId,
  ) async {
    isLoading = true;
    message = '';
    notifyListeners();

    // Використовуємо звичайне додавання рядків (+), щоб чат не ламав код
    String endpoint =
        serverApi +
        '/api/Payment/pay/' +
        rentalId.toString() +
        '/' +
        userId.toString();

    if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
      endpoint = endpoint + '?paymentMethodId=' + paymentMethodId;
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

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        message = responseData['message'] ?? "Payment processed successfully";
        return true;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        message = responseData['message'] ?? "Payment failed";
        return false;
      } else {
        message =
            "Failed to process payment: " + response.statusCode.toString();
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

  Future payOutstandingBalance(
    int userId,
    String token,
    String? paymentMethodId,
  ) async {
    isLoading = true;
    message = '';
    notifyListeners();

    // Використовуємо звичайне додавання рядків (+), щоб чат не ламав код
    String endpoint =
        serverApi + '/api/Payment/OutstandingBalance/' + userId.toString();

    if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
      endpoint = endpoint + '?paymentMethodId=' + paymentMethodId;
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
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        message = responseData['message'] ?? "Payment failed";
        return false;
      } else {
        message =
            "Failed to pay outstanding balance: " +
            response.statusCode.toString();
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