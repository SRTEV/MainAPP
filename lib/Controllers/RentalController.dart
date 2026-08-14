import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RentalPlan {
  final int id;
  final String planName;
  final double price;
  final int time;
  final int vehicleTypeId;
  final int RentalId;

  RentalPlan({
    required this.id,
    required this.planName,
    required this.price,
    required this.time,
    required this.vehicleTypeId,
    required this.RentalId,
  });

  factory RentalPlan.fromJson(Map<String, dynamic> json) {
    return RentalPlan(
      id: json['id'] ?? json['ID'] ?? 0,
      planName: json['plan'] ?? json['Plan'] ?? '',
      price: (json['price'] ?? json['Price'] ?? 0.0).toDouble(),
      time: json['time'] ?? json['Time'] ?? 0,
      vehicleTypeId: json['vehicleTypeId'] ?? json['Vehicle_TypeID'] ?? 0,
      RentalId: json['id'] ?? 0,
    );
  }
}

class RentalController extends ChangeNotifier {
  final String _serverApi = dotenv.env['SERVER'] ?? '10.0.2.2';

  List<RentalPlan> _plans = [];
  List<RentalPlan> get plans => _plans;
  RentalPlan? _selectedPlan;
  RentalPlan? get selectedPlan => _selectedPlan;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int? _RentalId;

  int? get RentalId => _RentalId;

  Future<void> fetchRentalPlans(int vehicleTypeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://$_serverApi:5194/api/RentalPlan/VehicleType/$vehicleTypeId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _plans = decoded.map((item) => RentalPlan.fromJson(item)).toList();
        } else if (decoded is Map<String, dynamic>) {
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

  Future<String?> startRental({
    required int vehicleId,
    required int planId,
    required int userId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('http://$_serverApi:5194/api/Rental/start');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "vehicleId": vehicleId,
          "rentalPlanId": planId,
          "userId": userId,
        }),
      );

      if (response.statusCode == 201) { {
        final data = jsonDecode(response.body);
        _RentalId = data['id'];
        notifyListeners();
        return null} else {
        final data = jsonDecode(response.body);
        return data['message'] ?? "Failed to start rental.";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  Future<String?> endRental({
    required int rentalId,
    required double distance,
    required String token,
  }) async {
    try {
      final url = Uri.parse('http://$_serverApi:5194/api/Rental/end');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "rentalId": rentalId,
          "distance": distance,
        }),
      );

      if (response.statusCode == 200) {
        _RentalId = null;
        notifyListeners();
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? "Failed to end rental.";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  void selectPlan(RentalPlan? plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  void clearselectedPlan() {
    _selectedPlan = null;
    notifyListeners();
  }
}