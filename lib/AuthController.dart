import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'map.dart';

class AuthController extends ChangeNotifier {
  String message = '';
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  Color nameBorderColor = Colors.black;
  String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  String get serverApi => dotenv.env['SERVER']!;

  void clearMessage() {
    message = '';
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    nameBorderColor = Colors.black;
    notifyListeners();
  }

  Future<void> Register(BuildContext context, String name, String email, String password, String confirmPassword) async {
    clearMessage();
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      message = "Please fill in all fields";
      nameBorderColor = Colors.red;
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }
    if (password.length < 5) {
      message = "Password must be at least 5 characters long";
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }
    if (password != confirmPassword) {
      message = "Passwords do not match";
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }
    if (!RegExp(emailRegex).hasMatch(email)) {
      message = "Invalid email format";
      emailBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    final url = Uri.parse('http://$serverApi:5194/api/User/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Name': name,
          'Email': email,
          'Password': password,
        }),
      );

      debugPrint("Register Status: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MapPage()));
      } else {
        final errorData = json.decode(response.body);
        message = errorData['message'] ?? "Registration failed";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Register error: $e");
      message = "Connection failed";
      notifyListeners();
    }
  }

  Future<void> Login(BuildContext context, String email, String password) async {
    clearMessage();

    final url = Uri.parse('http://$serverApi:5194/api/User/login');
    if (email.isEmpty || password.isEmpty) {
      message = "Please fill in all fields";
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Email': email,
          'Password': password,
        }),
      );

      debugPrint("Login Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      } else if(response.statusCode == 401){
        final errorData = json.decode(response.body);
        message = errorData['message'] ?? "Invalid email or password";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Login error: $e");
      message = "Connection failed. Is the server running?";
      notifyListeners();
    }
  }


  Future<void> ResetPassword(BuildContext context, String email) async {
    clearMessage();

    if (email.isEmpty) {
      message = "Please enter your email";
      emailBorderColor = Colors.red;
      notifyListeners();
      return;
    }
    if (!RegExp(emailRegex).hasMatch(email)) {
      message = "Invalid email format";
      emailBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    final url = Uri.parse('http://$serverApi:5194/api/User/ResetPassword');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Email': email,
        }),
      );

      debugPrint("ResetPassword Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        message = "Reset link has been sent to your email";
        notifyListeners();
        message = "Reset link has been sent to your email";
      } else {
        final errorData = json.decode(response.body);
        message = errorData['message'] ?? "Failed to send reset email";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("ResetPassword error: $e");
      message = "Connection failed";
      notifyListeners();
    }
  }

}
