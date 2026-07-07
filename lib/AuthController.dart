import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'db.dart';
import 'map.dart';

class AuthController extends ChangeNotifier {
  String message = '';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  Color nameBorderColor = Colors.black;

  void clearMessage() {
    message = '';
     emailBorderColor = Colors.black;
     passwordBorderColor = Colors.black;
     nameBorderColor = Colors.black;
    notifyListeners();
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> Register(BuildContext context, String name, String email, String password, String confirmPassword) async {
    clearMessage();
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      message = "Please fill in all fields";
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      nameBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    if (password != confirmPassword) {
      message = "Passwords do not match";
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      message = "Invalid email format";
      emailBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(DatabaseHelper.settings);
      String hashedPassword = _hashPassword(password);

      await conn.query(
        'INSERT INTO User (name, Password_hash, email, created_at, updated_at, Oustanding_balances, is_Blocked, RoleID) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [name, hashedPassword, email, DateTime.now().toUtc(), DateTime.now().toUtc(), 0, 0, 1],
      );

      message = "Registration successful!";
    } catch (e) {
      debugPrint("Database error: $e");
      message = "Error connecting to database";
    } finally {
      await conn?.close();
    }
    notifyListeners();
  }

  Future<void> Login(BuildContext context, String email, String password) async {
    clearMessage();
    if (email.isEmpty || password.isEmpty) {
      message = "Please fill in all fields";
      emailBorderColor = Colors.red;
      passwordBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      message = "Invalid email format";
      emailBorderColor = Colors.red;
      notifyListeners();
      return;
    }

    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(DatabaseHelper.settings);
      String hashedPassword = _hashPassword(password);

      var results = await conn.query(
        'SELECT * FROM User WHERE Email = ? AND Password_hash = ?',
        [email, hashedPassword],
      );

      if (results.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      } else {
        message = "Invalid email or password";
      }
    } catch (e) {
      debugPrint("Database error: $e");
      message = "Error connecting to database";
    } finally {
      await conn?.close();
    }
    notifyListeners();
  }
}