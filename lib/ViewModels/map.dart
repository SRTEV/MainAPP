import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:mainapp/Controllers/RentalController.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../Controllers/Controller.dart';
import 'Profile.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final String mapboxToken = dotenv.env['TOKEN_MAP'] ?? '';
  LatLng userLocation = const LatLng(51.23547305664311, 22.548898519702192);
  LatLng targetLocation = const LatLng(51.23547305664311, 22.548898519702192);
  double userHeading = 0.0;
  double targetHeading = 0.0;
  bool Fallow = true;

  // Стан для фільтрів
  bool _isFilterOpen = false;
  Set<String> _visibleTypes = {};
  bool _isInitialized = false;

  Timer? _resumeTimer;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  late Ticker _ticker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _ticker = createTicker((elapsed) => _updateSmoothElements());
    _ticker.start();

    _initLocation();
    _initCompass();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Controller>().fetchVehicles();
      context.read<Controller>().startVehiclePolling();
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

  void _updateSmoothElements() {
    const double lerpFactor = 0.08;
    userLocation = LatLng(
      userLocation.latitude + (targetLocation.latitude - userLocation.latitude) * lerpFactor,
      userLocation.longitude + (targetLocation.longitude - userLocation.longitude) * lerpFactor,
    );
    if (Fallow) _mapController.move(userLocation, _mapController.camera.zoom);

    const double rotationLerp = 0.15;
    double diff = targetHeading - userHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    userHeading += diff * rotationLerp;
    if (mounted) setState(() {});
  }

  void _startResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => Fallow = true);
    });
  }

  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
      targetLocation = userLocation;
    });
    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0)
    ).listen((p) => setState(() => targetLocation = LatLng(p.latitude, p.longitude)));
  }

  void _initCompass() {
    _compassStream = FlutterCompass.events?.listen((e) => targetHeading = e.heading ?? 0.0);
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
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

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 16.0,
              onMapEvent: (event) {
                if (event.source == MapEventSource.onDrag) {
                  setState(() => Fallow = false);
                  _startResumeTimer();
                }
              },
            ),
            children: [
              TileLayer(
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {'accessToken': mapboxToken}
              ),
              MarkerLayer(
                markers: vehicles
                    .where((v) => v.status == 'Available' && _visibleTypes.contains(v.type))
                    .map((v) => Marker(
                  point: v.position,
                  width: 40, height: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await context.read<RentalController>().fetchRentalPlans(v.vehicleTypeId);
                      _showVehicleDetails(context, v);
                    },
                    child: Center(child: Image.asset(getIconForVehicleType(v.type), width: 40, height: 40)),
                  ),
                )).toList(),
              ),
              MarkerLayer(markers: [Marker(point: userLocation, width: 120, height: 120, child: IgnorePointer( // <--- Це вимикає взаємодію з цим маркером
                child: _buildUserPointer(),
              ),)]),
            ],
          ),


          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка "Filter" - вужча і довша
                SizedBox(
                  width: 130, // Вужча
                  height: 30, // Довша (висота)
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => setState(() => _isFilterOpen = !_isFilterOpen),
                    child: const Text("Filter", style: TextStyle(fontSize: 14)),
                  ),
                ),
                if (_isFilterOpen)
                  Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: Column(
                      children: controller.vehicleTypes.map((type) => Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            fillColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected) ? Colors.black : Colors.grey[300]),
                            checkColor: WidgetStateProperty.all(Colors.white),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                          title: Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                          value: _visibleTypes.contains(type),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) => setState(() => val! ? _visibleTypes.add(type) : _visibleTypes.remove(type)),
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),


        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => setState(() => Fallow = true),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
        bottomNavigationBar: SizedBox(
            height: 90,
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
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.emoji_events)), label: 'Challenges'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)), label: 'History'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.camera_alt)), label: 'Scan'),
                  BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)), label: 'Account'),
                ],
              ),
            ),
        )
    );
  }

  Widget _buildUserPointer() {
    return Stack(alignment: Alignment.center, children: [
      Transform.rotate(angle: (userHeading * (math.pi / 180)), child: CustomPaint(size: const Size(120, 120), painter: Pointer())),
      AnimatedBuilder(animation: _pulseAnimation, builder: (c, _) => Container(width: 22 * _pulseAnimation.value, height: 22 * _pulseAnimation.value, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle))),
      Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))
    ]);
  }

  String getIconForVehicleType(String type) {
    switch (type.toLowerCase().trim()) {
      case 'electric scooter': return 'lib/assets/imgs/scooter.png';
      case 'monowheel': return 'lib/assets/imgs/monowheel.png';
      case 'bike': return 'lib/assets/imgs/bike.png';
      default: return 'lib/assets/imgs/scooter.png';
    }
  }

  void _showVehicleDetails(BuildContext context, dynamic vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Consumer<RentalController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
          return Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("${vehicle.type} ${vehicle.model} ${vehicle.batteryLevel}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: controller.plans.map((plan) => _buildPlanBox(plan)).toList()),
            const SizedBox(height: 20),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)), onPressed: () {}, child: const Text("Start", style: TextStyle(color: Colors.white))),
          ]));
        },
      ),
    );
  }

  Widget _buildPlanBox(RentalPlan plan) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(8)), child: Column(children: [
      Text(plan.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text("${plan.price} Zł/${plan.time > 60 ? 'hour' : 'min'}"),
    ]));
  }
}

class Pointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2; final centerY = size.height / 2; final radius = size.width / 2;
    final Paint paint = Paint()..shader = RadialGradient(colors: [Colors.blueAccent.withOpacity(0.6), Colors.blueAccent.withOpacity(0.0)], stops: const [0.3, 1.0]).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    const double angleWidth = 25.0 * (math.pi / 180);
    final Path path = Path()..moveTo(centerX, centerY)..lineTo(centerX + radius * math.sin(angleWidth), centerY - radius * math.cos(angleWidth))..arcToPoint(Offset(centerX - radius * math.sin(angleWidth), centerY - radius * math.cos(angleWidth)), radius: Radius.circular(radius), clockwise: false)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}