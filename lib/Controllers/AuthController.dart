import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../ViewModels/map.dart';

class AuthController extends ChangeNotifier {
  String message = '';
  String? token;
  int? userId;
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  Color nameBorderColor = Colors.black;
   Color confirmBorderColor = Colors.black;
  String? Email;


  final String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  String get serverApi => dotenv.env['SERVER'] ?? 'localhost';

  void setMessage(String msg, {bool isError = false}) {
    message = msg;
    notifyListeners();
  }

 void clearMessage(){
    message ='';
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    nameBorderColor = Colors.black;
    confirmBorderColor = Colors.black;
    notifyListeners();
  }
  void clearSomeData() {
    token = null;
    userId = null;
    Email = null;
    notifyListeners();
  }

  Future<void> register(BuildContext context, String name, String email, String password, String confirmPassword) async {
    clearMessage();
    if (name.isEmpty && email.isEmpty && password.isEmpty && confirmPassword.isEmpty) {
      nameBorderColor = Colors.red;
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      confirmBorderColor = Colors.red;
      setMessage("Please enter all fields", isError: true);
      return;
    }

    if (name.isEmpty) {
      nameBorderColor = Colors.red;
      setMessage("Please enter your name", isError: true);
      return;
    }
    if (email.isEmpty) {
      emailBorderColor = Colors.red;
      setMessage("Please enter your email", isError: true);
      return;
    }
    if (password.isEmpty) {
      passwordBorderColor = Colors.red;
      setMessage("Please enter your password", isError: true);
      return;
    }

    if (!RegExp(emailRegex).hasMatch(email)) {
      emailBorderColor = Colors.red;
      setMessage("Invalid email format", isError: true);
      return;
    }

    if (password.length < 8) {
      passwordBorderColor = Colors.red;
      setMessage("Password must be at least 8 characters long", isError: true);
      return;
    }

    if (password != confirmPassword) {
      setMessage("Passwords do not match", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverApi:5194/api/User/register/app'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'Name': name, 'Email': email, 'Password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        token = data['token'];
        userId = data['id'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MapPage()));
      } else {
        setMessage(json.decode(response.body)['message'] ?? "Registration failed", isError: true);
      }
    } catch (e) {
      setMessage("Connection failed", isError: true);
    }
  }

  Future<void> login(BuildContext context, String email, String password) async {
    clearMessage();
    if(email.isEmpty && password.isEmpty) {
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      setMessage("Please enter all fields", isError: true);
      return;
    }
    if(email.isEmpty){
      emailBorderColor = Colors.red;
      setMessage("Please enter your email", isError: true);
      return;
    }
    if(password.isEmpty){
      passwordBorderColor = Colors.red;
      setMessage("Please enter your password", isError: true);
      return;
    }
    if (!RegExp(emailRegex).hasMatch(email)) {
      emailBorderColor = Colors.red;
      setMessage("Invalid email format", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverApi:5194/api/User/login/app'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'Email': email, 'Password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        token = data['token'];
        userId = data['id'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MapPage()));
      } else {
        setMessage(json.decode(response.body)['message'] ?? "Login failed", isError: true);

      }
    } catch (e) {
      setMessage("Connection failed", isError: true);
    }
  }



  Future<void> ResetPassword(BuildContext context, String email) async {
    clearMessage();
    if (email.isEmpty) {
      emailBorderColor = Colors.red;
      setMessage("Please enter your email", isError: true);
      return;
    }
    if (!RegExp(emailRegex).hasMatch(email)) {
      emailBorderColor = Colors.red;
      setMessage("Invalid email format", isError: true);
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
        final data = json.decode(response.body);
        Email = data['email'];
        setMessage("Reset link has been sent to your email");
      } else {
        final errorData = json.decode(response.body);
        setMessage(errorData['message'] ?? "Failed to send reset email", isError: true);
      }
    } catch (e) {
      debugPrint("ResetPassword error: $e");
      setMessage("Connection failed", isError: true);
    }
  }

  Future<void> changePassword(BuildContext context, String token, String newPassword, String confirmPassword) async {
    clearMessage();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      passwordBorderColor = Colors.red;
      setMessage("Please enter all fields", isError: true);
      return;
    }

    if (newPassword.length < 8) {
      passwordBorderColor = Colors.red;
      setMessage("Password must be at least 8 characters", isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      passwordBorderColor = Colors.red;
      setMessage("Passwords do not match", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverApi:5194/api/User/ChangePassword'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Token': token,
          'NewPassword': newPassword
        }),
      );

      if (response.statusCode == 200) {
        setMessage("Password changed successfully!");
      } else {
        final errorData = json.decode(response.body);
        setMessage(errorData['message'] ?? "Error changing password", isError: true);
      }
    } catch (e) {
      setMessage("Connection error", isError: true);
    }
  }
}