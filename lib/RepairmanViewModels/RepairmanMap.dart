import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/ScanController.dart';
import 'package:provider/provider.dart';

import '../Controllers/Controller.dart';
import '../Controllers/UserController.dart';
import '../Controllers/ZoneController.dart';
import '../Modules/Notifications.dart';
import '../ViewModels/Blocked.dart';
import '../ViewModels/ContactSupport.dart';
import '../ViewModels/ScannerQr.dart';
import 'RepairmanProfilePage.dart';

class Repairmanmap extends StatefulWidget {
  const Repairmanmap({super.key});

  @override
  RepairmanmapState createState() => RepairmanmapState();
}

class RepairmanmapState extends State<Repairmanmap>
    with TickerProviderStateMixin {
  final String mapboxToken = dotenv.env['TOKEN_MAP']!;
  LatLng userLocation = const LatLng(51.23547305664311, 22.548898519702192);
  LatLng targetLocation = const LatLng(51.23547305664311, 22.548898519702192);
  double userHeading = 0.0;
  double targetHeading = 0.0;
  bool Fallow = true;
  bool _isFilterOpen = false;
  Set<String> _visibleTypes = {};
  bool _isInitialized = false;
  Timer? _resumeTimer;

  LatLng? _lastPosition;
  dynamic _selectedVehicle;
  dynamic _startedRepair;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  late Ticker _ticker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  IconData _getBatteryIcon(dynamic levelVal) {
    int level = levelVal is num ? levelVal.toInt() : int.tryParse(
        levelVal?.toString() ?? '0') ?? 0;
    if (level >= 80) return Icons.battery_full;
    if (level >= 60) return Icons.battery_6_bar;
    if (level >= 40) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_2_bar;
    return Icons.battery_0_bar;
  }

  @override
  void initState() {
    super.initState();
    _pulseController =
    AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _ticker = createTicker((elapsed) => _updateSmoothElements());
    _ticker.start();

    _initLocation();
    _initCompass();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkUserBlockStatus();

      if (mounted) {
        final vehicleController = Provider.of<Controller>(
            context, listen: false);
        await vehicleController.fetchVehicles();
        vehicleController.startVehiclePolling();
      }
    });
  }

  Future<void> _checkUserBlockStatus() async {
    if (!mounted) return;
    try {
      final userController = Provider.of<UserController>(
          context, listen: false);
      final authController = Provider.of<AuthController>(
          context, listen: false);

      final userid = authController.userId;
      final token = authController.token;

      if (userid != null && token != null) {
        await userController.fetchUserName(userid, token);
        if (userController.isBlocked == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Blocked()),
          );
        }
      }
    } catch (_) {}
  }

  void _ensureFiltersInitialized(List<dynamic> vehicles) {
    if (!_isInitialized && vehicles.isNotEmpty) {
      setState(() {
        _visibleTypes = vehicles.map((v) => v.type as String).toSet();
        _isInitialized = true;
      });
    }
  }

  void _updateSmoothElements() {
    const double lerpFactor = 0.1;

    double latDiff = targetLocation.latitude - userLocation.latitude;
    double lngDiff = targetLocation.longitude - userLocation.longitude;

    if (latDiff.abs() > 0.000001 || lngDiff.abs() > 0.000001) {
      userLocation = LatLng(
        userLocation.latitude + latDiff * lerpFactor,
        userLocation.longitude + lngDiff * lerpFactor,
      );

      if (Fallow) {
        _mapController.move(userLocation, _mapController.camera.zoom);
      }
      if (mounted) setState(() {});
    }

    const double rotationLerp = 0.15;
    double diff = targetHeading - userHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    if (diff.abs() > 0.5) {
      userHeading += diff * rotationLerp;
      if (mounted) setState(() {});
    }
  }

  void _startResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => Fallow = true);
    });
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    if (!mounted) return;

    final initialLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      userLocation = initialLatLng;
      targetLocation = initialLatLng;
      _lastPosition = initialLatLng;
    });

    _mapController.move(initialLatLng, 16.0);

    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 1)
    ).listen((p) {
      if (mounted) {
        final newLatLng = LatLng(p.latitude, p.longitude);

        if (_lastPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            newLatLng.latitude,
            newLatLng.longitude,
          );

          if (distanceInMeters < 0.5) {
            return;
          }
          _lastPosition = newLatLng;
        }

        setState(() {
          targetLocation = newLatLng;
        });
      }
    });
  }

  void _initCompass() {
    _compassStream = FlutterCompass.events?.listen((e) {
      if (mounted && e.heading != null) {
        targetHeading = e.heading!;
      }
    });
  }

  Future<void> _onItemTapped(int index, BuildContext context) async {
    await _checkUserBlockStatus();
    if (!mounted) return;

    if (index == 0) {
      debugPrint("Admin calls button clicked");
    } else if (index == 1) {
      final scannedCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerQr()),
      );

      if (scannedCode != null && mounted) {
        final authController = context.read<AuthController>();
        final token = authController.token;
        final vehicleController = context.read<Controller>();

        if (token != null) {
          final matchedVehicle = await context
              .read<ScanController>()
              .scanVehicle(scannedCode, token);

          if (matchedVehicle != null && mounted) {
            if (matchedVehicle.status == 'NeedCheck') {
              dynamic fullVehicle;
              try {
                fullVehicle = vehicleController.vehicles.firstWhere((v) =>
                v.id == matchedVehicle.id);
              } catch (_) {
                fullVehicle = matchedVehicle;
              }

              await vehicleController.inRemont(fullVehicle.id, token);

              final vehicleTypeId = fullVehicle.vehicleTypeId;
              if (vehicleTypeId != null) {
                await context.read<ZoneController>().fetchZones(
                    vehicleTypeId, token);
              }

              if (mounted) {
                setState(() {
                  _selectedVehicle = null;
                  _startedRepair = fullVehicle;
                });
              }
            } else {
              showTopNotification(
                context,
                "This vehicle does not need a check (Status: ${matchedVehicle
                    .status})",
              );
            }
          } else if (mounted) {
            showTopNotification(context, "Transport not found or deleted!");
          }
        }
      }
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RepairmanProfile(
                hasActiveRepair: _startedRepair !=
                    null, // Передаємо статус ремонту
              ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _resumeTimer?.cancel();
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<Controller>();
    final vehicles = controller.vehicles;
    _ensureFiltersInitialized(vehicles);

    if (_selectedVehicle != null) {
      try {
        _selectedVehicle =
            vehicles.firstWhere((v) => v.id == _selectedVehicle.id);
      } catch (_) {}
    }
    if (_startedRepair != null) {
      try {
        _startedRepair =
            vehicles.firstWhere((v) => v.id == _startedRepair.id);
      } catch (_) {}
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 16.0,
              onTap: (tapPosition, point) {
                if (_startedRepair != null) return;
                setState(() {
                  _selectedVehicle = null;
                });
                context.read<ZoneController>().clearZones();
              },
              onMapEvent: (event) {
                if (event.source == MapEventSource.onDrag) {
                  setState(() => Fallow = false);
                  _startResumeTimer();
                }
              },
            ),
            children: [
              TileLayer(
                  urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {'accessToken': mapboxToken}),
              Consumer<ZoneController>(
                builder: (context, zoneCtrl, child) {
                  return PolygonLayer(
                    polygons: zoneCtrl.zones.map((zone) {
                      final color = Colors.red.withOpacity(0.3);
                      final borderColor = Colors.red;

                      return Polygon(
                        points: zoneCtrl.parseCoordinates(zone.coordinates),
                        color: color,
                        borderColor: borderColor,
                        borderStrokeWidth: 2.0,
                        isFilled: true,
                      );
                    }).toList(),
                  );
                },
              ),
              MarkerLayer(
                markers: vehicles
                    .where((v) =>
                (v.status == 'Available' || v.status == 'NeedCheck') &&
                    _visibleTypes.contains(v.type))
                    .map((v) {
                  bool needsCheck = v.status == 'NeedCheck';
                  String pinAsset = _getVehicleAsset(v.type, needsCheck);

                  return Marker(
                    point: v.position,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (_startedRepair != null) return;

                        await _checkUserBlockStatus();
                        if (!mounted) return;

                        final token = context
                            .read<AuthController>()
                            .token;
                        if (token != null) {
                          await context.read<ZoneController>().fetchZones(
                              v.vehicleTypeId, token);
                        }

                        if (mounted) {
                          setState(() {
                            _startedRepair = null;
                            _selectedVehicle = v;
                          });
                        }
                      },
                      child: Center(
                        child: Image.asset(
                          pinAsset,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(markers: [
                Marker(
                  point: userLocation,
                  width: 120,
                  height: 120,
                  child: IgnorePointer(
                    child: _buildUserPointer(),
                  ),
                )
              ]),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () =>
                        setState(() => _isFilterOpen = !_isFilterOpen),
                    child: const Text("Filter",
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
                if (_isFilterOpen)
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      children: [
                        ...controller.vehicleTypes.map((type) =>
                            Theme(
                              data: Theme.of(context).copyWith(
                                checkboxTheme: CheckboxThemeData(
                                  fillColor: WidgetStateProperty.resolveWith(
                                          (states) =>
                                      states.contains(
                                          WidgetState.selected)
                                          ? Colors.black
                                          : Colors.grey[300]),
                                  checkColor:
                                  WidgetStateProperty.all(Colors.white),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 0),
                                  title: Text(type,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  value: _visibleTypes.contains(type),
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  onChanged: (val) =>
                                      setState(() =>
                                      val!
                                          ? _visibleTypes.add(type)
                                          : _visibleTypes.remove(type)),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedVehicle != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildVehicleInfoWidget(context, _selectedVehicle),
            ),
          if (_startedRepair != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStartedRepairWidget(context, _startedRepair),
            ),
        ],
      ),
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          bottom: (_selectedVehicle != null || _startedRepair != null)
              ? 260.0
              : 10.0,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () {
            setState(() {
              Fallow = true;
              targetLocation = userLocation;
            });
            _mapController.move(userLocation, _mapController.camera.zoom);
          },
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.black,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white,
            iconSize: 28,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.assignment_outlined)),
                  label: 'Admin calls'),
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.build)),
                  label: 'Start work'),
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.person)),
                  label: 'Account'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserPointer() {
    return Stack(alignment: Alignment.center, children: [
      Transform.rotate(
          angle: (userHeading * (math.pi / 180)),
          child: CustomPaint(size: const Size(120, 120), painter: Pointer())),
      AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (c, _) =>
              Container(
                  width: 22 * _pulseAnimation.value,
                  height: 22 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle))),
      Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3)))
    ]);
  }

  String _getVehicleAsset(String type, bool needsCheck) {
    String t = type.toLowerCase().trim();
    if (t.contains('bike')) {
      return needsCheck
          ? 'lib/assets/imgs/bikeRED.png'
          : 'lib/assets/imgs/bike.png';
    } else if (t.contains('monowheel')) {
      return needsCheck
          ? 'lib/assets/imgs/monowheelRED.png'
          : 'lib/assets/imgs/monowheel.png';
    } else {
      return needsCheck
          ? 'lib/assets/imgs/scooterRED.png'
          : 'lib/assets/imgs/scooter.png';
    }
  }

  Widget _buildStartedRepairWidget(BuildContext context, dynamic vehicle) {
    num batteryLevel = vehicle.batteryLevel is num
        ? vehicle.batteryLevel
        : num.tryParse(vehicle.batteryLevel?.toString() ?? '0') ?? 0;

    return Consumer<Controller>(
      builder: (context, vehicleController, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(color: Colors.black),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "${vehicle.type} ${vehicle.model ?? vehicle.id}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getBatteryIcon(batteryLevel), size: 40),
                              const SizedBox(width: 8),
                              Text(
                                "$batteryLevel%",
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Battery life ${(batteryLevel * 0.21)
                                .toStringAsFixed(0)} KM",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Status : In remont",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 75,
                        height: 75,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Image.asset(
                            _getVehicleAsset(vehicle.type, false),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          side: const BorderSide(
                              color: Colors.black, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          debugPrint(
                              "Long-term repair clicked for vehicle ${vehicle
                                  .id}");
                        },
                        child: const Text(
                          "long-term repair",
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          side: const BorderSide(
                              color: Colors.black, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final authController = context.read<AuthController>();
                          final token = authController.token;

                          if (token != null) {
                            await vehicleController.EndRemont(
                                vehicle.id, token);
                          }

                          if (mounted) {
                            setState(() {
                              _startedRepair = null;
                            });
                            context.read<Controller>().fetchVehicles();
                            context.read<ZoneController>().clearZones();
                            showTopNotification(
                                context, "Remont ended successfully!");
                          }
                        },
                        child: const Text(
                          "End remont",
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleInfoWidget(BuildContext context, dynamic vehicle) {
    bool needsCheck = vehicle.status == 'NeedCheck';

    num batteryLevel = vehicle.batteryLevel is num
        ? vehicle.batteryLevel
        : num.tryParse(vehicle.batteryLevel?.toString() ?? '0') ?? 0;

    return Consumer<Controller>(
      builder: (context, vehicleController, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(color: Colors.black),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: needsCheck ? const Color(0xFFFF8A8A) : const Color(
                    0xFFD9D9D9),
                borderRadius: BorderRadius.circular(20),
                border: needsCheck
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "${vehicle.type} ${vehicle.model ?? vehicle.id}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getBatteryIcon(batteryLevel), size: 40),
                              const SizedBox(width: 8),
                              Text(
                                "$batteryLevel%",
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          if (needsCheck) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Battery life ${(batteryLevel * 0.21)
                                  .toStringAsFixed(0)} KM",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            needsCheck
                                ? "Status: Needs to be checked"
                                : "Status: ${vehicle.status}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 75,
                        height: 75,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Image.asset(
                            _getVehicleAsset(vehicle.type, needsCheck),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (needsCheck) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            side: const BorderSide(
                                color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await _checkUserBlockStatus();
                            if (!mounted) return;

                            final scannedCode = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScannerQr(),
                              ),
                            );

                            if (scannedCode != null && mounted) {
                              final authController = context.read<
                                  AuthController>();
                              final token = authController.token;
                              if (token != null) {
                                final matchedVehicle = await context
                                    .read<ScanController>()
                                    .scanVehicle(scannedCode, token);

                                if (matchedVehicle != null && mounted) {
                                  if (matchedVehicle.status == 'NeedCheck') {
                                    dynamic fullVehicle;
                                    try {
                                      fullVehicle = vehicleController.vehicles
                                          .firstWhere((v) =>
                                      v.id == matchedVehicle.id);
                                    } catch (_) {
                                      fullVehicle = matchedVehicle;
                                    }

                                    await vehicleController.inRemont(
                                        fullVehicle.id, token);

                                    final vehicleTypeId = fullVehicle
                                        .vehicleTypeId;
                                    if (vehicleTypeId != null) {
                                      await context
                                          .read<ZoneController>()
                                          .fetchZones(vehicleTypeId, token);
                                    }

                                    if (mounted) {
                                      setState(() {
                                        _selectedVehicle = null;
                                        _startedRepair = fullVehicle;
                                      });
                                    }
                                  } else {
                                    showTopNotification(
                                      context,
                                      "This vehicle does not need a check (Status: ${matchedVehicle
                                          .status})",
                                    );
                                  }
                                } else if (mounted) {
                                  showTopNotification(context,
                                      "Transport not found or deleted!");
                                }
                              }
                            }
                          },
                          child: const Text(
                            "Start the repair",
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            side: const BorderSide(
                                color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await _checkUserBlockStatus();
                            if (!mounted) return;

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Contactsupport(
                                      vehicleId: vehicle.id,
                                      email: Provider
                                          .of<UserController>(
                                          context, listen: false)
                                          .userEmail,
                                    ),
                              ),
                            );
                            if (result != null && mounted) {
                              showTopNotification(context, result.toString());
                            }
                          },
                          child: const Text(
                            "Report problem",
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Pointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    final Paint paint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.blueAccent.withOpacity(0.6),
        Colors.blueAccent.withOpacity(0.0)
      ], stops: const [
        0.3,
        1.0
      ]).createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    const double angleWidth = 25.0 * (math.pi / 180);
    final Path path = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(centerX + radius * math.sin(angleWidth),
          centerY - radius * math.cos(angleWidth))
      ..arcToPoint(
          Offset(centerX - radius * math.sin(angleWidth),
              centerY - radius * math.cos(angleWidth)),
          radius: Radius.circular(radius),
          clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}