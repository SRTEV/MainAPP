import 'package:mysql1/mysql1.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseHelper {
  static ConnectionSettings get settings {
    return ConnectionSettings(
      host: dotenv.env['HOST']!,
      port: int.parse(dotenv.env['PORT']!),
      user: dotenv.env['USER']!,
      password: dotenv.env['PASSWORD']!,
      db: dotenv.env['DB']!,
    );
  }

  static Future<void> connectToDatabase() async {
    try {
      final conn = await MySqlConnection.connect(settings);
      debugPrint("Connected successfully to MySQL!");
      await conn.close();
    } catch (e) {
      debugPrint("Database error (connect): $e");
    }
  }

}