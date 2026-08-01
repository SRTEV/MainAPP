import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ZoneModel {
  final int id;
  final String? name;
  final String coordinates;
  final bool isRestrictedArea;
  final int? vehicleTypeId;

  ZoneModel({
    required this.id,
    this.name,
    required this.coordinates,
    required this.isRestrictedArea,
    this.vehicleTypeId,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] ?? 0,
      name: json['name'],
      coordinates: json['coordinates'] ?? '',
      isRestrictedArea:
          json['is_Restricted_area'] ?? json['isRestrictedArea'] ?? false,
      vehicleTypeId: json['vehicle_TypeId'] ?? json['vehicleTypeId'],
    );
  }
}

class ZoneController extends ChangeNotifier {
  String get serverApi => dotenv.env['SERVER']!;

  List<ZoneModel> zones = [];
  bool isLoading = false;

  Future<void> fetchZones(int vehicleTypeId, String token) async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse(
      'http://$serverApi:5194/api/Zone/VehicleType/$vehicleTypeId',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        zones = body.map((item) => ZoneModel.fromJson(item)).toList();
      } else {
        debugPrint("Failed to load zones: ${response.statusCode}");
        zones = [];
      }
    } catch (e) {
      debugPrint("Error fetching zones: $e");
      zones = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ДОДАНИЙ МЕТОД ДЛЯ ПЕРЕТВОРЕННЯ РЯДКА КООРДИНАТ У ТОЧКИ ПОЛІГОНУ
  List<LatLng> parseCoordinates(String coordsString) {
    List<LatLng> points = [];
    try {
      final pairs = coordsString.split(';');
      for (var pair in pairs) {
        if (pair.trim().isEmpty) continue;
        final latLng = pair.split(',');
        if (latLng.length == 2) {
          double lat = double.parse(latLng[0].trim());
          double lng = double.parse(latLng[1].trim());
          points.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      debugPrint("Coordinate parse error: $e");
    }
    return points;
  }

  void clearZones() {
    zones = [];
    notifyListeners();
  }
}
