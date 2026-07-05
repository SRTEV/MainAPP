import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'Register.dart';
import 'package:provider/provider.dart';
import 'Controller.dart';
import 'db.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  await dotenv.load(fileName: ".env");
  await DatabaseHelper.connectToDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ScooterViewModel(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Login(),
      ),
    ),
  );
}


