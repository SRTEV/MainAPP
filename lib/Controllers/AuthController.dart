import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../ViewModels/map.dart';
import 'package:bcrypt/bcrypt.dart';
import 'UserController.dart';


class AuthController extends ChangeNotifier {
  String message = '';
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  Color nameBorderColor = Colors.black;
  Color confirmBorderColor = Colors.black;
  String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  String get serverApi => dotenv.env['SERVER']!;
  String? tempEmail;
  int? tempId;


  void saveSomeData(String email, int? id) {
    tempEmail = email;
    tempId = id;
    notifyListeners();
  }

  void clearSomeData() {
    tempEmail = null;
    tempId = null;
    notifyListeners();
  }

  void clearMessage() {
    message = '';
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    nameBorderColor = Colors.black;
    notifyListeners();
  }

  void setMessage(String msg , {bool isError = false}) {
    message = msg;
    notifyListeners();
  }

  String hash_pass(String password) {
    final String? salt = dotenv.env['SALT'];
    if (salt == null) {
      debugPrint("ERROR: SALT is missing in .env");
      return password;
    }
    return BCrypt.hashpw(password, salt);
  }

  Future<void> Register(BuildContext context, String name, String email,
      String password, String confirmPassword) async {
    clearMessage();
    if (name.isEmpty || email.isEmpty || password.isEmpty ||
        confirmPassword.isEmpty) {
      if (name.isEmpty) nameBorderColor = Colors.red;
      if (email.isEmpty) emailBorderColor = Colors.red;
      if (password.isEmpty) passwordBorderColor = Colors.red;
      setMessage("Please fill in all fields", isError: true);
      return;
    }
    if (password.length < 5) {
      setMessage("Password must be at least 5 characters long", isError: true);
      passwordBorderColor = Colors.red;
      return;
    }
    if (password != confirmPassword) {
      setMessage("Passwords do not match", isError: true);
      passwordBorderColor = Colors.red;
      return;
    }
    if (!RegExp(emailRegex).hasMatch(email)) {
      emailBorderColor = Colors.red;
      setMessage("Invalid email format", isError: true);
      emailBorderColor = Colors.red;
      return;
    }

    final url = Uri.parse('http://$serverApi:5194/api/User/register/app');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Name': name,
          'Email': email,
          'Password': hash_pass(password),
        }),
      );

      debugPrint("Register Status: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        saveSomeData(email, data['userId']);//замінити
        setMessage("Registration successful!");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MapPage()));
      } else {
        final errorData = json.decode(response.body);
        setMessage(errorData['message'] ?? "Registration failed", isError: true);
      }
    } catch (e) {
      debugPrint("Register error: $e");
      setMessage("Connection failed", isError: true);
    }
  }

  Future<void> Login(BuildContext context, String email,
      String password) async {
    final userModel = Provider.of<UserController>(context, listen: false);
    clearMessage();
    final url = Uri.parse('http://$serverApi:5194/api/User/login/app');
    if (email.isEmpty || password.isEmpty) {
      if (email.isEmpty) emailBorderColor = Colors.red;
      if (password.isEmpty) passwordBorderColor = Colors.red;
      setMessage("Please fill in all fields", isError: true);

      return;
    }
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Email': email,
          'Password': hash_pass(password),
        }),
      );

      debugPrint("Login Status: ${response.statusCode}");
      if (!RegExp(emailRegex).hasMatch(email)) {
        emailBorderColor = Colors.red;
        setMessage("Invalid email format", isError: true);
        return;
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        saveSomeData(email, data['userId']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      } else if (response.statusCode == 401) {
        final errorData = json.decode(response.body);
        setMessage(errorData['message'] ?? "Invalid email or password", isError: true);
      } else {
        setMessage("Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      setMessage("Connection failed. Is the server running?", isError: true);
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
        saveSomeData(email, data['userId']);
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

  Future<void> ChangePassword(BuildContext context,
      String newPassword,
      String confirmPassword,
      String email) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setMessage("Please fill in all fields", isError: true);
      return;
    }

    if (newPassword.length < 5) {
      setMessage("Password must be at least 5 characters long", isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      setMessage("Passwords do not match", isError: true);
      return;
    }

    final url = Uri.parse('http://$serverApi:5194/api/User/ChangePassword');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'Email': email,
          'NewPassword': hash_pass(newPassword),
        }),
      );

      debugPrint("Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        setMessage("Password changed successfully!");
      } else {
        setMessage("Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      debugPrint("ChangePassword Exception: $e");
      setMessage("Connection error. Please try again.", isError: true);
    }
  }
}
