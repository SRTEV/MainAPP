import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'db.dart';
import 'Register.dart';
class ScooterViewModel extends ChangeNotifier {
  Color nameBorderColor = Colors.black;
  Color emailBorderColor = Colors.black;
  Color passwordBorderColor = Colors.black;
  String message = '';

  void Register(String name, String email, String password, String confirmPassword) {
    nameBorderColor = Colors.black;
    emailBorderColor = Colors.black;
    passwordBorderColor = Colors.black;
    message = '';


    if (name.isEmpty || email.isEmpty || password.isEmpty|| confirmPassword.isEmpty) {
      if (name.isEmpty) nameBorderColor = Colors.red;
      if (email.isEmpty) emailBorderColor = Colors.red;
      if (password.isEmpty) passwordBorderColor = Colors.red;
      if (confirmPassword.isEmpty) passwordBorderColor = Colors.red;
      message = "Please fill in all fields" ;
    }
    else if (password != confirmPassword) {
      passwordBorderColor = Colors.red;
      message = "Passwords do not match" ;
    }

    notifyListeners();
  }
}