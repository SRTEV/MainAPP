import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;
  String? userName;
  double? balance;
  String? hashedPassword;
  int? tempId;
  bool isLoading = false;
  bool? Deleted;
  int? Role;


  Future<void> fetchUserName(int id) async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse('http://$serverApi:5194/api/User/$id');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("User data: $data");

        userName =  data['name'];
        balance = data['oustandingBalances'];
        hashedPassword = data['passwordHash'];
        tempId = data['id'];
        Deleted = data['deleted'];
        Role = data['RoleId'];
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

  Future<void> deleteAccount(int id) async {
    final url = Uri.parse('http://$serverApi:5194/api/User/Delete/$id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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


  }


