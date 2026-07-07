import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mysql1/mysql1.dart';
import 'db.dart';
import 'map.dart';

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
}

class Controller extends ChangeNotifier {
  List<VehicleModel> vehicles = [];
  Timer? _vehicleTimer;

  // Запуск автоматичного оновлення кожні 10 секунд
  void startVehiclePolling() {
    _vehicleTimer?.cancel();
    _vehicleTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchVehicles();
    });
    debugPrint("Vehicle real-time updates started");
  }

  // Зупинка оновлення
  void stopVehiclePolling() {
    _vehicleTimer?.cancel();
    _vehicleTimer = null;
    debugPrint("Vehicle real-time updates stopped");
  }

  Future<void> fetchVehicles() async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(DatabaseHelper.settings);
      
      var results = await conn.query('''
        SELECT v.id, v.Position_X, v.Position_Y, t.Name as TypeName, s.Name as StatusName
        FROM Vehicle v
        JOIN Vechicle_Status s ON v.Vechicle_StatusID = s.id
        JOIN Vehicle_Type t ON v.Vehicle_TypeID = t.id
        WHERE v.Deleted = 0;
      ''');

      vehicles = results.map((row) {
        return VehicleModel(
          id: row[0],
          position: LatLng(double.parse(row[1].toString()), double.parse(row[2].toString())),
          status: row[4].toString(),
          type: row[3].toString(),
        );
      }).toList();

      debugPrint("Fetched ${vehicles.length} vehicles");
      for (var v in vehicles) {
        debugPrint("Vehicle ID: ${v.id}, Status: ${v.status}, Type: ${v.type}");
      }
    } catch (e) {
      debugPrint("Database error: $e");
    } finally {
      await conn?.close();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopVehiclePolling();
    super.dispose();
  }
}
