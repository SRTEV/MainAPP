import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'Register.dart';
import 'Controller.dart';
import 'db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await DatabaseHelper.connectToDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (_) => Controller(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Login(),
      ),
    ),
  );
}


