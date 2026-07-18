import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:mainapp/Controllers/RentalController.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../Controllers/Controller.dart';
import 'Profile.dart';
import 'ContactSupport.dart';
import '../Controllers/UserController.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final String mapboxToken = dotenv.env['TOKEN_MAP'] !;
  LatLng userLocation = const LatLng(51.23547305664311, 22.548898519702192);
  LatLng targetLocation = const LatLng(51.23547305664311, 22.548898519702192);
  double userHeading = 0.0;
  double targetHeading = 0.0;
  bool Fallow = true;
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



  void _showTopNotification(BuildContext context, String result) {
    if (!mounted) return;
    bool isSuccess = result.toLowerCase().contains("success") || result.toLowerCase().contains("created");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.startToEnd,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height-250,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = Provider.of<UserController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);

      context.read<Controller>().fetchVehicles();
      context.read<Controller>().startVehiclePolling();
      final id = authController.userId!;
      final token = authController.token!;
      if (authController.userId != null && authController.token != null) {
        userController.fetchUserName(id, token);
      }


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
      userLocation.latitude +
          (targetLocation.latitude - userLocation.latitude) * lerpFactor,
      userLocation.longitude +
          (targetLocation.longitude - userLocation.longitude) * lerpFactor,
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
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
      targetLocation = userLocation;
    });
    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0)
    ).listen((p) =>
        setState(() => targetLocation = LatLng(p.latitude, p.longitude)));
  }

  void _initCompass() {
    _compassStream =
        FlutterCompass.events?.listen((e) => targetHeading = e.heading ?? 0.0);
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 3) Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Profile()));
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
                      .where((v) =>
                  v.status == 'Available' && _visibleTypes.contains(v.type))
                      .map((v) =>
                      Marker(
                        point: v.position,
                        width: 40, height: 40,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await context.read<RentalController>().fetchRentalPlans(v.vehicleTypeId);
                            _showVehicleDetails(context, v);
                          },
                          child: Center(
                              child: Image.asset(getIconForVehicleType(v.type),
                                  width: 40, height: 40)),
                        ),
                      )).toList(),
                ),
                MarkerLayer(markers: [
                  Marker(point: userLocation,
                    width: 120,
                    height: 120,
                    child: IgnorePointer(
                      child: _buildUserPointer(),
                    ),)
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
                      child: const Text(
                          "Filter", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  if (_isFilterOpen)
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                            color: Colors.black, width: 2),
                      ),
                      child: Column(
                        children: [

                          ...controller.vehicleTypes.map((type) =>
                              Theme(
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: CheckboxThemeData(
                                    fillColor: WidgetStateProperty.resolveWith((
                                        states) =>
                                    states.contains(WidgetState.selected)
                                        ? Colors.black
                                        : Colors.grey[300]),
                                    checkColor: WidgetStateProperty.all(
                                        Colors.white),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: CheckboxListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 0),

                                    title: Text(type, style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                    value: _visibleTypes.contains(type),
                                    controlAffinity: ListTileControlAffinity
                                        .leading,
                                    onChanged: (val) =>
                                        setState(() =>
                                        val!
                                            ? _visibleTypes.add(type)
                                            : _visibleTypes.remove(type)),
                                  ),
                                ),
                              )).toList(),
                        ],
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
                BottomNavigationBarItem(icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.emoji_events)), label: 'Challenges'),
                BottomNavigationBarItem(icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.history)), label: 'History'),
                BottomNavigationBarItem(icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.camera_alt)), label: 'Scan'),
                BottomNavigationBarItem(icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person)), label: 'Account'),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildUserPointer() {
    return Stack(alignment: Alignment.center, children: [
      Transform.rotate(angle: (userHeading * (math.pi / 180)),
          child: CustomPaint(size: const Size(120, 120), painter: Pointer())),
      AnimatedBuilder(animation: _pulseAnimation,
          builder: (c, _) =>
              Container(width: 22 * _pulseAnimation.value,
                  height: 22 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle))),
      Container(width: 18,
          height: 18,
          decoration: BoxDecoration(color: Colors.blueAccent,
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
  }void _showVehicleDetails(BuildContext context, dynamic vehicle) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalController>(context, listen: false).fetchRentalPlans(vehicle.vehicleTypeId);
    });

    final BuildContext scaffoldContext = context;

    IconData getBatteryIcon(int level) {
      if (level >= 80) return Icons.battery_full;
      if (level >= 60) return Icons.battery_6_bar;
      if (level >= 40) return Icons.battery_4_bar;
      if (level >= 20) return Icons.battery_2_bar;
      return Icons.battery_0_bar;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<RentalController>(
        builder: (context, rentalCtrl, child) {
          return Consumer<Controller>(
            builder: (context, vehicleController, child) {
              return Container(
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
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 2)),
                              child: IconButton(
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(), iconSize: 14,
                                icon: const Icon(Icons.question_mark, color: Colors.white),
                                  onPressed: () async {
                                  Navigator.pop(context);



                                    final result = await Navigator.push(
                                      scaffoldContext,
                                      MaterialPageRoute(
                                        builder: (context) => Contactsupport(
                                          vehicleId: vehicle.id,
                                          email: Provider.of<UserController>(scaffoldContext, listen: false).userEmail,
                                        ),
                                      ),
                                    );
                                    if (result != null && result is String) {
                                      _showTopNotification(scaffoldContext,result);
                                    }
                                  }
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(getBatteryIcon(vehicle.batteryLevel), size: 45),
                        Text("${vehicle.batteryLevel}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ]),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Battery life ${vehicleController.calculateRange(vehicle).toStringAsFixed(0)} KM",
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 15),
                      const Text("The most popular plans for this type of transport", style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        height: 85,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: rentalCtrl.isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.black))
                            : rentalCtrl.plans.isEmpty
                            ? const Center(child: Text("No plans available"))
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: rentalCtrl.plans.length,
                          itemBuilder: (context, index) {
                            final plan = rentalCtrl.plans[index];
                            final isSelected = rentalCtrl.selectedPlan?.id == plan.id;

                            return GestureDetector(
                              onTap: () => rentalCtrl.selectPlan(plan),
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFE6FF94),
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      width: double.infinity,
                                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black))),
                                      child: Center(child: Text(plan.planName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text("${plan.price.toStringAsFixed(1)} Zł\n/${plan.time} min",
                                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Text("You can hire this vehicle, just scan the QR code on it",
                          textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanBox(RentalPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(plan.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("\$${plan.price.toStringAsFixed(0)}"),
        ],
      ),
    );
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