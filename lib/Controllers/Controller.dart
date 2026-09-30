import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class VehicleModel {
  final int id;
  final LatLng position;
  final String status;
  final String type;
  final int vehicleTypeId;
  final String model;
  final int batteryLevel;
  final double batteryCapacity;
  final double electricityConsumption;


  VehicleModel({
    required this.id,
    required this.position,
    required this.status,
    required this.type,
    required this.vehicleTypeId,
    required this.model,
    required this.batteryLevel,
    required this.batteryCapacity,
    required this.electricityConsumption,
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
      vehicleTypeId: json['vehicleType']?['id'] ,
      model: json['model'],
      batteryLevel: json['batteryLevel'] ?? 0,
      batteryCapacity: (json['batteryCapacity'] ?? 0).toDouble(),
      electricityConsumption: (json['electricityConsumption'] ?? 0).toDouble(),
    );
  }
}

class Controller extends ChangeNotifier {
  List<VehicleModel> vehicles = [];
  final Map<int, String> addressCache = {};
  final Set<int> _loadingAddresses = {};
  Timer? _vehicleTimer;
  String get serverApi => dotenv.env['SERVER']!;
  List<String> get vehicleTypes {
    return vehicles.map((v) => v.type).toSet().toList();
  }

  Future<void> fetchVehicles() async {
    final url = Uri.parse('$serverApi/api/Vehicle');
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

  Future<void> inRemont(int vehicleId, String token) async {
    final url = Uri.parse('$serverApi/api/Vehicle/inremont/$vehicleId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final updatedVehicle = VehicleModel.fromJson(
            json.decode(response.body));
        final index = vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) {
          vehicles[index] = updatedVehicle;
          notifyListeners();
        }
      } else {
        debugPrint('Failed to update vehicle in remont. Status code: ${response
            .statusCode}');
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  Future<void> EndRemont(int vehicleId, String token) async {
    final url = Uri.parse('$serverApi/api/Vehicle/endremont/$vehicleId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final updatedVehicle = VehicleModel.fromJson(
            json.decode(response.body));
        final index = vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) {
          vehicles[index] = updatedVehicle;
          notifyListeners();
        }
      } else {
        debugPrint('Failed to update vehicle end remont. Status code: ${response
            .statusCode}');
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }


  void startVehiclePolling() {
    _vehicleTimer?.cancel();
    _vehicleTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchVehicles());
  }


  double calculateRange(VehicleModel vehicle) {
    if (vehicle.electricityConsumption <= 0) return 0.0;
    double voltage = 36.0;
    double capacityWh = (vehicle.batteryCapacity * voltage) / 1000;
    double remainingWh = capacityWh * (vehicle.batteryLevel / 100);
    return remainingWh / vehicle.electricityConsumption;
  }

  Future<void> loadAddressesForVehicles(List<VehicleModel> vehicles) async {
    for (final vehicle in vehicles) {
      if (!addressCache.containsKey(vehicle.id) &&
          !_loadingAddresses.contains(vehicle.id)) {
        _loadingAddresses.add(vehicle.id);
        fetchAndCacheAddress(vehicle);
      }
    }
  }

  Future<void> fetchAndCacheAddress(VehicleModel vehicle) async {
    try {
      final lat = vehicle.position.latitude;
      final lon = vehicle.position.longitude;

      if (lat == 0.0 && lon == 0.0) {
        addressCache[vehicle.id] = "Coordinates missing";
        notifyListeners();
        return;
      }

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?format=json'
            '&lat=$lat'
            '&lon=$lon'
            '&zoom=18'
            '&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterRepairApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(
          utf8.decode(response.bodyBytes),
        );

        final address = data['address'];

        if (address != null) {
          final String street =
              address['road'] ??
                  address['pedestrian'] ??
                  address['suburb'] ??
                  address['neighbourhood'] ??
                  '';

          final String houseNumber =
              address['house_number'] ?? '';

          if (street.isNotEmpty) {
            final String formattedStreet =
            street.toLowerCase().startsWith('ul')
                ? street
                : "Str. $street";

            addressCache[vehicle.id] =
            "$formattedStreet"
                "${houseNumber.isNotEmpty ? ' $houseNumber' : ''}";
          } else {
            addressCache[vehicle.id] =
            "Lat: ${lat.toStringAsFixed(4)}, "
                "Lon: ${lon.toStringAsFixed(4)}";
          }
        } else {
          addressCache[vehicle.id] =
          "Lat: ${lat.toStringAsFixed(4)}, "
              "Lon: ${lon.toStringAsFixed(4)}";
        }
      } else {
        addressCache[vehicle.id] =
        "Lat: ${lat.toStringAsFixed(4)}, "
            "Lon: ${lon.toStringAsFixed(4)}";
      }
    } catch (e) {
      debugPrint(
        "Error fetching address from OpenStreetMap: $e",
      );

      addressCache[vehicle.id] =
      "Lat: ${vehicle.position.latitude.toStringAsFixed(4)}, "
          "Lon: ${vehicle.position.longitude.toStringAsFixed(4)}";
    } finally {
      _loadingAddresses.remove(vehicle.id);
      notifyListeners();
    }
  }
}