import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'db.dart';
import 'map.dart';

class ScooterViewModel extends ChangeNotifier {
  Color nameBorderColor = Colors.black;
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  String message = '';

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> Register(String name, String email, String password, String confirmPassword) async {
    nameBorderColor = Colors.black;
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    message = '';

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (name.isEmpty) nameBorderColor = Colors.red;
      if (email.isEmpty) emailBorderColor = Colors.red;
      if (password.isEmpty) passwordBorderColor = Colors.red;
      if (confirmPassword.isEmpty) passwordBorderColor = Colors.red;
      message = "Please fill in all fields";
      notifyListeners();
      return;
    }

    if (password != confirmPassword) {
      passwordBorderColor = Colors.red;
      message = "Passwords do not match";
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
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    message = '';

    if (email.isEmpty || password.isEmpty) {
      if (email.isEmpty) emailBorderColor = Colors.red;
      if (password.isEmpty) passwordBorderColor = Colors.red;
      message = "Please fill in all fields";
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

        notifyListeners();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapPage()),
        );
      } else {
        emailBorderColor = Colors.red;
        passwordBorderColor = Colors.red;
        message = "Invalid email or password";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Database error: $e");
      message = "Error connecting to database";
      notifyListeners();
    } finally {
      await conn?.close();
    }
  }
}
