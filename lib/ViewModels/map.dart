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
import 'package:mainapp/Controllers/RentalController.dart';
import 'package:mainapp/Controllers/ScanController.dart';
import 'package:provider/provider.dart';

import '../Controllers/ChallangeController.dart';
import '../Controllers/Controller.dart';
import '../Controllers/UserController.dart';
import '../Controllers/ZoneController.dart';
import 'Blocked.dart';
import 'Challanges.dart';
import 'ContactSupport.dart';
import 'History.dart';
import 'Profile.dart';
import 'ScannerQr.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
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
  Timer? _timerRent;
  Duration _timerRentDuration = Duration.zero;

  LatLng? _lastPosition;
  dynamic _selectedVehicle;
  dynamic _startedRental;
  dynamic _activeRental;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  late Ticker _ticker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  IconData _getBatteryIcon(int level) {
    if (level >= 80) return Icons.battery_full;
    if (level >= 60) return Icons.battery_6_bar;
    if (level >= 40) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_2_bar;
    return Icons.battery_0_bar;
  }

  void _showTopNotification(BuildContext context, String message) {
    if (!mounted) return;
    bool isSuccess = message.toLowerCase().contains("success");

    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 10,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.shade600 : Colors.red
                        .shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  @override
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
      final userController = Provider.of<UserController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);
      final compCon = Provider.of<Challangecontroller>(context, listen: false);
      final vehicleController = Provider.of<Controller>(context, listen: false);

      final userid = authController.userId;
      final token = authController.token;

      if (userid != null && token != null) {
        await userController.fetchUserName(userid, token);
        if (userController.isBlocked == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Blocked()),
          );
          return;
        }
      }

      if (mounted) {
        // Спочатку завантажуємо список транспортних засобів
        await vehicleController.fetchVehicles();
        vehicleController.startVehiclePolling();

        // Якщо є доступні типи транспорту, автоматично фечимо останній челендж для першого типу
        if (vehicleController.vehicles.isNotEmpty && token != null) {
          final firstVehicleTypeId = vehicleController.vehicles.first
              .vehicleTypeId;
          await compCon.fetchLatestChallenge(firstVehicleTypeId, token);

          // Якщо після цього з'явився competitionId, одразу підтягуємо результат користувача
          if (compCon.competitionId != null && userid != null) {
            await compCon.fetchUserResult(
                token, userid, compCon.competitionId!);
          }
        }
      }
    });
  }

  void _startRentalTimer() {
    _timerRentDuration = Duration.zero;
    _timerRent?.cancel();

    _timerRent = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timerRentDuration =
            Duration(seconds: _timerRentDuration.inSeconds + 1);
      });
    });
  }

  void _ensureFiltersInitialized(List<dynamic> vehicles) {
    if (!_isInitialized && vehicles.isNotEmpty) {
      setState(() {
        _visibleTypes = vehicles.map((v) => v.type as String).toSet();
        _isInitialized = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  /// Плавний рух позиції маркера та камери за користувачем під час переміщення
  void _updateSmoothElements() {
    const double lerpFactor = 0.1;

    double latDiff = targetLocation.latitude - userLocation.latitude;
    double lngDiff = targetLocation.longitude - userLocation.longitude;

    if (latDiff.abs() > 0.000001 || lngDiff.abs() > 0.000001) {
      userLocation = LatLng(
        userLocation.latitude + latDiff * lerpFactor,
        userLocation.longitude + lngDiff * lerpFactor,
      );

      // Плавний рух камери за користувачем під час руху, якщо увімкнено Fallow
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

    // Отримуємо первинну позицію і робимо різкий телепорт на старті
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    if (!mounted) return;

    final initialLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      userLocation = initialLatLng;
      targetLocation = initialLatLng;
      _lastPosition = initialLatLng;
    });

    // Одноразовий телепорт камери на старті
    _mapController.move(initialLatLng, 16.0);

    // Стрім оновлення координат у реальному часі для руху та слідування
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

          // Ігноруємо мікроколивання GPS на місці (якщо зміна менше ніж 0.5 метра)
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
    if (index == 0) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Challanges()));
    }
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const History()));
    }
    if (index == 2) {
      final scannedCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerQr()),
      );

      if (scannedCode != null && mounted) {
        final token = context
            .read<AuthController>()
            .token;
        if (token != null) {
          final matchedVehicle = await context
              .read<ScanController>()
              .scanVehicle(scannedCode, token);

          if (matchedVehicle != null && mounted) {
            await context.read<ZoneController>().fetchZones(
                matchedVehicle.vehicleTypeId, token);
            await context.read<RentalController>().fetchRentalPlans(
                matchedVehicle.vehicleTypeId);

            context.read<RentalController>().clearselectedPlan();
            setState(() {
              _selectedVehicle = null;
              _startedRental = matchedVehicle;
            });
          } else if (mounted) {
            _showTopNotification(context, "Transport not found or deleted!");
          }
        }
      }
    }

    if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Profile()));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _resumeTimer?.cancel();
    _timerRent?.cancel();
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<Controller>();
    final vehicles = controller.vehicles;
    _ensureFiltersInitialized(vehicles);

    if (_activeRental != null) {
      try {
        _activeRental = vehicles.firstWhere((v) => v.id == _activeRental.id);
      } catch (_) {}
    }
    if (_selectedVehicle != null) {
      try {
        _selectedVehicle =
            vehicles.firstWhere((v) => v.id == _selectedVehicle.id);
      } catch (_) {}
    }
    if (_startedRental != null) {
      try {
        _startedRental = vehicles.firstWhere((v) => v.id == _startedRental.id);
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
                if (_activeRental != null) return;
                setState(() {
                  _selectedVehicle = null;
                  _startedRental = null;
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
                v.status == 'Available' &&
                    _visibleTypes.contains(v.type))
                    .map((v) =>
                    Marker(
                      point: v.position,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final token =
                              context
                                  .read<AuthController>()
                                  .token;
                          if (token != null) {
                            await context
                                .read<ZoneController>()
                                .fetchZones(v.vehicleTypeId, token);
                          }

                          await context
                              .read<RentalController>()
                              .fetchRentalPlans(v.vehicleTypeId);

                          if (mounted) {
                            setState(() {
                              _startedRental = null;
                              _selectedVehicle = v;
                            });
                          }
                        },
                        child: Center(
                            child: Image.asset(
                                getIconForVehicleType(v.type),
                                width: 40,
                                height: 40)),
                      ),
                    ))
                    .toList(),
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
              child: _buildVehicleDetailsWidget(context, _selectedVehicle),
            ),
          if (_startedRental != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStartRentalWidget(context, _startedRental),
            ),
          if (_activeRental != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildVehicleRentActiveWidget(context, _activeRental),
            ),
        ],
      ),
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          bottom: (_selectedVehicle != null ||
              _startedRental != null ||
              _activeRental != null)
              ? 310.0
              : 10.0,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () {
            setState(() {
              Fallow = true;
              targetLocation = userLocation;
            });
            // Примусовий миттєвий телепорт при натисканні на кнопку геолокації
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
            iconSize: 32,
            selectedFontSize: 14,
            unselectedFontSize: 14,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.emoji_events)),
                  label: 'Challenges'),
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.history)),
                  label: 'History'),
              BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.camera_alt)),
                  label: 'Scan'),
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

  String getIconForVehicleType(String type) {
    switch (type.toLowerCase().trim()) {
      case 'electric scooter':
        return 'lib/assets/imgs/scooter.png';
      case 'monowheel':
        return 'lib/assets/imgs/monowheel.png';
      case 'bike':
        return 'lib/assets/imgs/bike.png';
      default:
        return 'lib/assets/imgs/scooter.png';
    }
  }

  Widget _buildVehicleRentActiveWidget(BuildContext context, dynamic vehicle) {
    final BuildContext scaffoldContext = context;

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
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "${vehicle.type} ${vehicle.model ?? vehicle.id}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 14,
                            icon: const Icon(Icons.question_mark,
                                color: Colors.white),
                            onPressed: () async {
                              final result = await Navigator.push(
                                scaffoldContext,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Contactsupport(
                                        vehicleId: vehicle.id,
                                        email: Provider
                                            .of<UserController>(
                                            scaffoldContext,
                                            listen: false)
                                            .userEmail,
                                      ),
                                ),
                              );
                              if (result != null && result is String) {
                                _showTopNotification(scaffoldContext, result);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getBatteryIcon(vehicle.batteryLevel),
                                  size: 40),
                              const SizedBox(width: 8),
                              Text(
                                "${vehicle.batteryLevel}%",
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Battery life ${vehicleController.calculateRange(
                                vehicle).toStringAsFixed(0)} KM",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                      Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            getIconForVehicleType(vehicle.type),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Travel time",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  ),
                  Text(
                    _formatDuration(_timerRentDuration),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final token = context
                            .read<AuthController>()
                            .token;

                        if (token == null) {
                          _showTopNotification(
                              scaffoldContext, "Authorization error!");
                          return;
                        }

                        final rentalId =
                            context
                                .read<RentalController>()
                                .RentalId;

                        if (rentalId == null) {
                          _showTopNotification(
                              scaffoldContext, "Active rental ID not found!");
                          return;
                        }

                        String? errorMessage = await context
                            .read<RentalController>()
                            .endRental(
                          rentalId: rentalId,

                          token: token,
                        );

                        if (errorMessage == null) {
                          if (mounted) {
                            setState(() {
                              _activeRental = null;
                            });
                          }

                          context.read<Controller>().fetchVehicles();
                          context.read<ZoneController>().clearZones();

                          _showTopNotification(
                              scaffoldContext, "Trip ended successfully!");
                        } else {
                          _showTopNotification(scaffoldContext, errorMessage);
                        }
                      },
                      child: const Text(
                        "End the trip",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildVehicleDetailsWidget(BuildContext context, dynamic vehicle) {
    final BuildContext scaffoldContext = context;

    return Consumer<RentalController>(
      builder: (context, rentalCtrl, child) {
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
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text("${vehicle.type} ${vehicle.model}",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.red, width: 2)),
                              child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 14,
                                  icon: const Icon(Icons.question_mark,
                                      color: Colors.white),
                                  onPressed: () async {
                                    setState(() {
                                      _selectedVehicle = null;
                                    });
                                    context.read<ZoneController>().clearZones();

                                    final result = await Navigator.push(
                                      scaffoldContext,
                                      MaterialPageRoute(
                                        builder: (context) => Contactsupport(
                                          vehicleId: vehicle.id,
                                          email: Provider
                                              .of<UserController>(
                                              scaffoldContext,
                                              listen: false)
                                              .userEmail,
                                        ),
                                      ),
                                    );
                                    if (result != null && result is String) {
                                      _showTopNotification(
                                          scaffoldContext, result);
                                    }
                                  }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(_getBatteryIcon(vehicle.batteryLevel), size: 45),
                        Text("${vehicle.batteryLevel}%",
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                      ]),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            "Battery life ${vehicleController.calculateRange(
                                vehicle).toStringAsFixed(0)} KM",
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                          "The most popular plans for this type of transport",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        height: 85,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: rentalCtrl.isLoading
                            ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.black))
                            : rentalCtrl.plans.isEmpty
                            ? const Center(
                            child: Text("No plans available"))
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: rentalCtrl.plans.length,
                          itemBuilder: (context, index) {
                            final plan = rentalCtrl.plans[index];
                            final isSelected =
                                rentalCtrl.selectedPlan?.id ==
                                    plan.id;

                            return GestureDetector(
                              onTap: () =>
                                  rentalCtrl.selectPlan(plan),
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFE6FF94),
                                  border: Border.all(
                                      color: Colors.black),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4),
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color:
                                                  Colors.black))),
                                      child: Center(
                                          child: Text(plan.planName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 12))),
                                    ),
                                    Padding(
                                      padding:
                                      const EdgeInsets.all(4.0),
                                      child: Text(
                                          "${plan.price.toStringAsFixed(
                                              1)} Zł\n/${plan.time} min",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Text(
                          "You can hire this vehicle, just scan the QR code on it",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStartRentalWidget(BuildContext context, dynamic vehicle) {
    final BuildContext scaffoldContext = context;

    return Consumer<RentalController>(
      builder: (context, rentalCtrl, child) {
        return Consumer<Controller>(
          builder: (context, vehicleController, child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(color: Colors.black),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text("${vehicle.type} ${vehicle.model}",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.red, width: 2)),
                              child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 14,
                                  icon: const Icon(Icons.question_mark,
                                      color: Colors.white),
                                  onPressed: () async {
                                    setState(() {
                                      _startedRental = null;
                                    });
                                    context.read<ZoneController>().clearZones();

                                    final result = await Navigator.push(
                                      scaffoldContext,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            Contactsupport(
                                              vehicleId: vehicle.id,
                                              email: Provider
                                                  .of<UserController>(
                                                  scaffoldContext,
                                                  listen: false)
                                                  .userEmail,
                                            ),
                                      ),
                                    );
                                    if (result != null && result is String) {
                                      _showTopNotification(
                                          scaffoldContext, result);
                                    }
                                  }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Choose your plan:",
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 13)),
                      ),
                      Container(
                        height: 85,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: rentalCtrl.isLoading
                            ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.black))
                            : rentalCtrl.plans.isEmpty
                            ? const Center(
                            child: Text("No plans available"))
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: rentalCtrl.plans.length,
                          itemBuilder: (context, index) {
                            final plan = rentalCtrl.plans[index];
                            final isSelected =
                                rentalCtrl.selectedPlan?.id ==
                                    plan.id;

                            return GestureDetector(
                              onTap: () =>
                                  rentalCtrl.selectPlan(plan),
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFE6FF94),
                                  border: Border.all(
                                      color: Colors.black),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4),
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color:
                                                  Colors.black))),
                                      child: Center(
                                          child: Text(plan.planName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 12))),
                                    ),
                                    Padding(
                                      padding:
                                      const EdgeInsets.all(4.0),
                                      child: Text(
                                          "${plan.price.toStringAsFixed(
                                              1)} Zł\n/${plan.time} min",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getBatteryIcon(vehicle.batteryLevel),
                                      size: 38),
                                  const SizedBox(width: 4),
                                  Text("${vehicle.batteryLevel}%",
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(
                                  "Battery life ${vehicleController
                                      .calculateRange(vehicle).toStringAsFixed(
                                      0)} KM",
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (rentalCtrl.selectedPlan == null) {
                                  _showTopNotification(
                                      context, "Please select a rental plan!");
                                  return;
                                }

                                final authController =
                                context.read<AuthController>();
                                final token = authController.token;
                                final userId = authController.userId;

                                if (token == null || userId == null) {
                                  _showTopNotification(
                                      context, "Authorization error!");
                                  return;
                                }

                                String? errorMessage = await context
                                    .read<RentalController>()
                                    .startRental(
                                  vehicleId: vehicle.id,
                                  planId: rentalCtrl.selectedPlan!.id,
                                  userId: userId,
                                  token: token,
                                );

                                if (errorMessage == null) {
                                  if (mounted) {
                                    setState(() {
                                      _startRentalTimer();
                                      _startedRental = null;
                                      _activeRental = vehicle;
                                    });
                                  }
                                  context.read<Controller>().fetchVehicles();
                                  _showTopNotification(
                                      context, "Rental started successfully!");
                                } else {
                                  _showTopNotification(context, errorMessage);
                                }
                              },
                              child: const Text(
                                "Start",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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