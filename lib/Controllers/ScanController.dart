import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mainapp/Controllers/Controller.dart';

class ScanController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  bool isLoading = false;

  Future<VehicleModel?> scanVehicle(String scannedCode, String token) async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse('$serverApi/api/Vehicle/scan/$scannedCode');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return VehicleModel.fromJson(data);
      } else {
        debugPrint("Failed to scan vehicle: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error scanning vehicle: $e");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
