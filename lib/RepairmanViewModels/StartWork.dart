import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Controllers/Controller.dart';

class Startwork extends StatefulWidget {
  const Startwork({super.key});

  @override
  State<Startwork> createState() => _StartworkState();
}

class _StartworkState extends State<Startwork> {
  int _selectedTab = 0; // 0 - Charging (< 15%), 1 - Remont / Other NeedCheck
  bool _isLoading = true;

  final Map<int, String> _addressCache = {};
  final Set<int> _loadingAddresses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<Controller>();
      await controller.fetchVehicles();
      controller.startVehiclePolling();

      await _loadAddressesForVehicles(controller.vehicles);

      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _loadAddressesForVehicles(List<VehicleModel> vehicles) async {
    for (var vehicle in vehicles) {
      if (!_addressCache.containsKey(vehicle.id) &&
          !_loadingAddresses.contains(vehicle.id)) {
        _loadingAddresses.add(vehicle.id);
        _fetchAndCacheAddress(vehicle);
      }
    }
  }

  Future<void> _fetchAndCacheAddress(VehicleModel vehicle) async {
    try {
      final lat = vehicle.position.latitude;
      final lon = vehicle.position.longitude;

      if (lat == 0.0 && lon == 0.0) {
        _addressCache[vehicle.id] = "Coordinates missing";
        return;
      }

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterRepairApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final address = data['address'];

        if (address != null) {
          String street =
              address['road'] ??
              address['pedestrian'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              '';
          String houseNumber = address['house_number'] ?? '';

          if (street.isNotEmpty) {
            String formattedStreet = street.toLowerCase().startsWith('ul')
                ? street
                : "Str. $street";
            _addressCache[vehicle.id] =
                "$formattedStreet${houseNumber.isNotEmpty ? ' $houseNumber' : ''}";
          } else {
            _addressCache[vehicle.id] =
                "Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}";
          }
        } else {
          _addressCache[vehicle.id] =
              "Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}";
        }
      } else {
        _addressCache[vehicle.id] =
            "Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}";
      }
    } catch (e) {
      print("Error fetching address from OpenStreetMap: $e");
      _addressCache[vehicle.id] =
          "Lat: ${vehicle.position.latitude.toStringAsFixed(4)}, Lon: ${vehicle.position.longitude.toStringAsFixed(4)}";
    } finally {
      _loadingAddresses.remove(vehicle.id);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Controller>(
      builder: (context, vehicleController, child) {
        if (!_isLoading) {
          _loadAddressesForVehicles(vehicleController.vehicles);
        }

        // 1. Вкладка Charging: суто NeedCheck ТА заряд акумулятора < 15
        final chargingList = vehicleController.vehicles.where((v) {
          final statusLower = v.status.toLowerCase();
          final battery = v.batteryLevel;
          return statusLower.contains('needcheck') && battery < 15;
        }).toList();

        // 2. Вкладка Remont: всі інші NeedCheck (де заряд >= 15) + стандартні репорти/поломки
        final remontList = vehicleController.vehicles.where((v) {
          final statusLower = v.status.toLowerCase();
          final battery = v.batteryLevel;

          bool isNeedCheckHighBattery =
              statusLower.contains('needcheck') && battery >= 15;
          bool isRemontStatus =
              statusLower.contains('remont') ||
              statusLower.contains('broken') ||
              statusLower.contains('repair') ||
              statusLower.contains('damaged') ||
              statusLower.contains('malfunction');

          return isNeedCheckHighBattery || isRemontStatus;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_circle_left_outlined,
                          size: 36,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Start work",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedTab = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Charging (${chargingList.length})",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedTab = 1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Remont (${remontList.length})",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                    ),
                                  )
                                : _selectedTab == 0
                                ? _buildVehicleList(chargingList, context)
                                : _buildVehicleList(remontList, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleList(List<VehicleModel> items, BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "There are no vehicles in this category",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final vehicle = items[index];
        final address = _addressCache[vehicle.id] ?? "Loading address...";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${vehicle.type} ${vehicle.model ?? vehicle.id}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(vehicle);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "GO",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
