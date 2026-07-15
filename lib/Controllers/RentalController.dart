import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RentalPlan {
  final int id;
  final String planName;
  final double price;
  final int time;
  final int vehicleTypeId;

  RentalPlan({
    required this.id,
    required this.planName,
    required this.price,
    required this.time,
    required this.vehicleTypeId,
  });

  factory RentalPlan.fromJson(Map<String, dynamic> json) {
    return RentalPlan(
      id: json['id'] ?? json['ID'] ?? 0,
      planName: json['plan'] ?? json['Plan'] ?? '',
      price: (json['price'] ?? json['Price'] ?? 0.0).toDouble(),
      time: json['time'] ?? json['Time'] ?? 0,
      vehicleTypeId: json['vehicleTypeId'] ?? json['Vehicle_TypeID'] ?? 0,
    );
  }
}

class RentalController extends ChangeNotifier {
  final String _serverApi = dotenv.env['SERVER'] ?? '10.0.2.2';

  List<RentalPlan> _plans = [];
  List<RentalPlan> get plans => _plans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchRentalPlans(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://$_serverApi:5194/api/VehicleType/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Безпечна обробка: API може повернути як List, так і Map
        if (decoded is List) {
          _plans = decoded.map((item) => RentalPlan.fromJson(item)).toList();
        } else if (decoded is Map<String, dynamic>) {
          // Якщо сервер повертає об'єкт, шукаємо в ньому список або перетворюємо його
          if (decoded.containsKey('rentalPlans')) {
            _plans = (decoded['rentalPlans'] as List).map((i) => RentalPlan.fromJson(i)).toList();
          } else {
            _plans = [RentalPlan.fromJson(decoded)];
          }
        }
      } else {
        debugPrint("Server error: ${response.statusCode} - ${response.body}");
        _plans = [];
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}