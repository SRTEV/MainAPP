import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class UserController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;
  String? userName;
  double? balance;
  String? hashedPassword;
  int? tempId;
  bool isLoading = false;
  bool? Deleted;
  int? Role;
  String? userEmail;
  int? cardId;
  bool? isBlocked;
  String? banReason;
  String? CardNumb;
  String? cardExpiryDate;
  String? cardCvv; // Зберігаємо CVV в пам'яті для автоматичної оплати

  Future<void> fetchUserName(int id, String token) async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse('$serverApi/api/User/$id');
    try {
      final response = await http.get(Uri.parse(url.toString()),
          headers: {
            'Authorization': 'Bearer $token',
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        userName = data['name'];
        balance = data['oustandingBalances'];
        hashedPassword = data['passwordHash'];
        tempId = data['id'];
        Deleted = data['deleted'];
        Role = data['RoleId'];
        userEmail = data['email'];
        cardId = data['cardId'];
        isBlocked = data['isBlocked'];
        banReason = data['blockedReason'];
        if (cardId != null) {
          await getCardNumb(id, token);
        } else {
          CardNumb = null;
          cardCvv = null;
        }
      }
    } catch (_) {} finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(int id, String text, String token) async {
    final url = Uri.parse('$serverApi/api/User/Delete/$id');
    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Password': text}),
      );
    } catch (_) {}
  }

  Future<String?> giveMeHeplPlease(String text, String type, int? VehicleId,
      String? email, int? userId) async {
    if (text.isEmpty) return "Text field is empty";

    final url = Uri.parse('$serverApi/api/Report');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Text': text,
          'Type': type,
          'email': email,
          'UserId': userId,
          'VehicleID': VehicleId,
        }),
      );

      if (response.statusCode == 201) {
        return "Success: Report created successfully";
      } else {
        return "Failed to create report";
      }
    } catch (_) {
      return "Network error";
    }
  }

  Future<String?> addCard(String cardNumber, String cvv, String expiryDate, String token) async {
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

    int expMonth = 0;
    int expYear = 0;
    try {
      final parts = expiryDate.split('/');
      expMonth = int.parse(parts[0]);
      expYear = int.parse("20${parts[1]}");
    } catch (_) {
      return "Invalid date format (MM/YY)";
    }

    // Зберігаємо CVV в пам'яті контролера для майбутньої оплати
    cardCvv = cvv;

    final url = Uri.parse('$serverApi/api/Card');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'cardNumber': cleanCardNumber,
          'expiryDate': "$expYear-${expMonth.toString().padLeft(2, '0')}-01",
          'cvvCode': cvv, // Тепер тут зберігається справжній CVV
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "Success: Card added successfully";
      } else {
        return "Failed to save card";
      }
    } catch (_) {
      return "Network error";
    }
  }

  Future<String?> deleteCard(int cardId, String token) async {
    final url = Uri.parse('$serverApi/api/Card/delete/$cardId');
    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        CardNumb = null;
        cardExpiryDate = null;
        cardCvv = null;
        return "Success: Card deleted successfully";
      } else {
        return "Failed to delete card";
      }
    } catch (_) {
      return "Network error";
    }
  }

  Future<String?> updateCard(int userId, String token, String cardNumber,
      String cvv, String expiryDate) async {
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

    int expMonth = 0;
    int expYear = 0;
    try {
      final parts = expiryDate.split('/');
      expMonth = int.parse(parts[0]);
      expYear = int.parse("20${parts[1]}");
    } catch (_) {
      return "Invalid date format (MM/YY)";
    }

    cardCvv = cvv;

    final url = Uri.parse('$serverApi/api/Card/$cardId');
    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'cardNumber': cleanCardNumber,
          'expiryDate': "$expYear-${expMonth.toString().padLeft(2, '0')}-01",
          'cvvCode': cvv, // Зберігаємо справжній CVV
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "Success: Card updated successfully";
      } else {
        return "Failed to update card";
      }
    } catch (_) {
      return "Network error";
    }
  }
  Future<String?> payForRental({
    required int rentalId,
    required int userId,
    required String token,
  }) async {
    if (CardNumb == null || cardExpiryDate == null) {
      return "No card found";
    }

    int expMonth = 0;
    int expYear = 0;
    try {
      final parts = cardExpiryDate!.split('/');
      expMonth = int.parse(parts[0]);
      expYear = int.parse("20${parts[1]}");
    } catch (_) {
      return "Invalid stored card date format";
    }

    String freshPaymentMethodId;
    try {
      Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails(
          number: CardNumb!,
          expirationMonth: expMonth,
          expirationYear: expYear,
          cvc: cardCvv ?? "123", // Використовуємо збережений CVV або дефолтний
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
      return "Failed to generate payment method: $e";
    }

    final url = Uri.parse(
        '$serverApi/api/Payment/pay/$rentalId/$userId?paymentMethodId=$freshPaymentMethodId');
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
        return data['message'] ?? "Success: Payment processed successfully.";
      } else {
        return data['message'] ?? "Payment failed";
      }
    } catch (_) {
      return "Network error during payment";
    }
  }

  Future<String?> updateUser(int userId, String name, String email,
      String token) async {
    final url = Uri.parse('$serverApi/api/User/ChangeAccountInfo/$userId');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'name': name,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return "Success: Account updated successfully";
      } else {
        return "Failed to update account";
      }
    } catch (_) {
      return "Network error";
    }
  }

  Future<void> getCardNumb(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$serverApi/api/Card/user-card/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        CardNumb = data['cardNumber'];
        cardCvv =
        data['cvvCode']; // Підтягуємо справжній CVV з бази (якщо він там є)

        String rawDate = data['expiryDate'] ?? '';
        if (rawDate.isNotEmpty) {
          try {
            DateTime parsedDate = DateTime.parse(rawDate);
            String month = parsedDate.month.toString().padLeft(2, '0');
            String year = parsedDate.year.toString().substring(2);
            cardExpiryDate = "$month/$year";
          } catch (_) {
            cardExpiryDate = "";
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }
}