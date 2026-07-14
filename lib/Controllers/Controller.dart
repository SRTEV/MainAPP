import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class VehicleModel {
  final int id;
  final LatLng position;
  final String status;
  final String type;

  VehicleModel({
    required this.id,
    required this.position,
    required this.status,
    required this.type,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      String strValue = value.toString().replaceAll(',', '.');
      return double.tryParse(strValue) ?? 0.0;
    }

    return VehicleModel(
      id: json['id'] ?? 0,
      position: LatLng(
        parseDouble(json['positionX']),
        parseDouble(json['positionY']),
      ),
      status: json['vehicleStatus']?['name'] ,
      type: json['vehicleType']?['name'] ,
    );
  }
}

class Controller extends ChangeNotifier {
  List<VehicleModel> vehicles = [];
  Timer? _vehicleTimer;
  String get serverApi => dotenv.env['SERVER']!;

  Future<void> fetchVehicles() async {
    final url = Uri.parse('http://$serverApi:5194/api/Vehicle');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);


        vehicles = data.map((item) => VehicleModel.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  void startVehiclePolling() {
    _vehicleTimer?.cancel();
    _vehicleTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchVehicles());
  }
}