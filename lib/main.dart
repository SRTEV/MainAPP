import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'ViewModels/Login.dart';
import 'ViewModels/Register.dart';
import 'Controllers/Controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Controllers/AuthController.dart';
import 'ViewModels/ChangePasswordReset.dart';
import 'Controllers/UserController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Controller()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Login(),
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name != null && name.contains('token=')) {
            // Парсимо URL, щоб дістати лише токен
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