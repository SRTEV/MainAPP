import 'package:mainapp/ChangePasswordReset.dart' hide changePasswordReset, ChangePasswordReset;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'Register.dart';
import 'Controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AuthController.dart';
import 'ChangePasswordReset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Controller()),
        ChangeNotifierProvider(create: (_) => AuthController()),
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
              builder: (context) => ChangePasswordReset(token: token ?? ""),
            );
          }
          return null;
        },
      ),
    ),
  );
}