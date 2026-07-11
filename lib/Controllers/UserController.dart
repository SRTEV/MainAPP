import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;
  String? userName;
  double? balance;
  bool isLoading = false;

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

        debugPrint("User name loaded: $userName");
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
}