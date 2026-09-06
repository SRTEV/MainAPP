import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  bool isLoading = false;
  String message = '';

  Future<bool> payForRental({
    required int rentalId,
    required int userId,
    required String token,
    String? paymentMethodId,
  }) async {
    isLoading = true;
    message = '';
    notifyListeners();

    // Формуємо URL без суми, оскільки сервер рахує її самостійно за Start_time
    String endpoint = '$serverApi/api/Payment/pay/$rentalId/$userId';
    if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
      endpoint += '?paymentMethodId=$paymentMethodId';
    }

    final url = Uri.parse(endpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        message = responseData['message'] ?? "Payment processed successfully";
        return true;
      } else if (response.statusCode == 400 || response.statusCode == 202) {
        message = responseData['message'] ?? "Payment failed";
        return false;
      } else {
        message = "Failed to process payment: ${response.statusCode}";
        return false;
      }
    } catch (e) {
      message = "Network error during payment: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
