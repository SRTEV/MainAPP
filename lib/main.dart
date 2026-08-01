import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mainapp/Controllers/RentalController.dart';
import 'package:mainapp/Controllers/ZoneController.dart';
import 'package:provider/provider.dart';

import 'Controllers/AuthController.dart';
import 'Controllers/Controller.dart';
import 'Controllers/UserController.dart';
import 'Controllers/ZoneController.dart';
import 'ViewModels/ChangePasswordReset.dart';
import 'ViewModels/Login.dart';
import 'ViewModels/Register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Controller()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => RentalController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ZoneController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Login(),
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name != null && name.contains('token=')) {
            final uri = Uri.parse(name.startsWith('/') ? 'https://app.local$name' : name);
            final token = uri.queryParameters['token'];

            return MaterialPageRoute(
              builder: (context) => ChangePasswordReset(
                  token: token ?? "",
              ),
            );
          }
          return null;
        },
      ),
    ),
  );
}