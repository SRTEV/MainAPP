import 'package:mainapp/changePasswordReset.dart' hide changePasswordReset;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'Register.dart';
import 'Controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AuthController.dart';
import 'changePasswordReset.dart';

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
          // Отримуємо назву маршруту
          final name = settings.name;

          // Перевіряємо, чи містить посилання слово "token" (це універсально)
          if (name != null && name.contains('token=')) {
            // Створюємо повний URI, щоб парсер коректно витягнув параметр
            // Якщо посилання починається з "/", додаємо фейковий хост
            final uri = Uri.parse(name.startsWith('/') ? 'https://app.local$name' : name);
            final token = uri.queryParameters['token'];

            return MaterialPageRoute(
              builder: (context) => changePasswordReset(token: token ?? ""),
            );
          }
          return null; // Якщо це не посилання на скидання, працюємо як зазвичай
        },
      ),
    ),
  );
}