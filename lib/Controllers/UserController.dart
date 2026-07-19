import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Controllers/AuthController.dart';

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





  Future<void> fetchUserName(int id, String token) async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse('http://$serverApi:5194/api/User/$id');
    try {
      final response = await http.get(Uri.parse(url.toString()),
        headers: {
          'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("User data: $data");

        userName =  data['name'];
        balance = data['oustandingBalances'];
        hashedPassword = data['passwordHash'];
        tempId = data['id'];
        Deleted = data['deleted'];
        Role = data['RoleId'];
        userEmail = data['email'];
        cardId = data['cardId'];


       // debugPrint("User name loaded: $userName");
      } else {
        debugPrint("Failed to load user: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(int id, String text, String token ) async {
    final url = Uri.parse('http://$serverApi:5194/api/User/Delete/$id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Password': text}),

      );

      if (response.statusCode == 200) {
        debugPrint("Account successfully marked as deleted");
      } else {
        debugPrint("Failed to mark as deleted: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Network error during soft delete: $e");
    }

    }



  Future<String?> giveMeHeplPlease(String text, String type, int? VehicleId , String? email, int? userId) async {
    final auth = AuthController();

    if (text.isEmpty) {
      return "Text field is empty";
    }

    final url = Uri.parse('http://$serverApi:5194/api/Report');

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
        return "Report created successfully";
      } else {
        return "Failed to create report: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Network error during report creation: $e" ;
    }
  }

  Future<String?> addCard(String cardNumber, String cvv, String expiryDate, String token) async {
    String formattedDate = "";
    try {
      final parts = expiryDate.split('/');
      formattedDate = "20${parts[1]}-${parts[0]}-01";
    } catch (e) {
      return "Invalid date format. Use MM/YY";
    }

    final url = Uri.parse('http://$serverApi:5194/api/Card');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'cardNumber': cardNumber, // Змінено на camelCase
          'expiryDate': formattedDate, // Формат РРРР-ММ-ДД
          'cvvCode': cvv, // Змінено на 'cvvCode' (згідно з вашою моделлю)
        }),
      );

      if (response.statusCode == 201) {
        return "Success: Card added successfully";
      } else {
        return "Failed to add card: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Network error: $e";
    }
  }
  }





