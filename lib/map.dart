import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

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
  double userAccuracy = 20.0;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  late Ticker _ticker;

  // Анімація пульсації
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Тікер для 60fps плавності всього
    _ticker = createTicker((elapsed) {
      _updateSmoothElements();
    });
    _ticker.start();

    _initLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initCompass() {
    try {
      _compassStream = FlutterCompass.events?.listen((event) {
        if (mounted && event.heading != null) {
          targetHeading = event.heading!;
        }
      });
    } catch (e) {
      debugPrint("Compass error: $e");
    }
  }

  void _updateSmoothElements() {
    const double lerpFactor = 0.04;
    //1.
    // 0.01 – 0.05 (Ідеально): Ефект «тягучості». Маркер ніби пливе по маслу. Дуже приємно для ока, але при великих значеннях може здаватися, що він трохи «запізнюється» за вами.
    // 2.
    // 0.06 – 0.15 (Швидко, але плавно): Баланс. Маркер рухається впевнено, наздоганяє вас швидко, але все ще без ривків. Це «золота середина».
    // 3.
    // 0.2 – 0.3 (Межа): Тут «масло» закінчується. Рух стає «нервовим». Людське око починає помічати, що точка дуже швидко «приліпає» до цілі, і виникає ефект мікро-ривків.
    // 4.
    // Вище 0.5: Це вже виглядає як «роботизований» рух. Точка просто дуже швидко смикається в нову позицію.


    double latDiff = targetLocation.latitude - userLocation.latitude;
    double lngDiff = targetLocation.longitude - userLocation.longitude;
    if (latDiff.abs() < 0.000001 && lngDiff.abs() < 0.000001) {
      userLocation = targetLocation;
    } else {
      userLocation = LatLng(
        userLocation.latitude + latDiff * lerpFactor,
        userLocation.longitude + lngDiff * lerpFactor,
      );
    }

    const double rotationLerp = 0.1;
    double diff = targetHeading - userHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    userHeading += diff * rotationLerp;

    if (mounted) setState(() {});
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
      targetLocation = userLocation;
      userAccuracy = position.accuracy;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (position.accuracy < 40) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        double dist = Geolocator.distanceBetween(
          targetLocation.latitude, targetLocation.longitude,
          newPos.latitude, newPos.longitude
        );

        if (dist > 0.5) {
          targetLocation = newPos;
        }

        setState(() {
          userAccuracy = position.accuracy;
        });
      }
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: userLocation,
          initialZoom: 16.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {'accessToken': mapboxToken},
          ),

          CircleLayer(
            circles: [
              CircleMarker(
                point: userLocation,
                radius: userAccuracy,
                useRadiusInMeter: true,
                color: Colors.blueAccent.withOpacity(0.08),
                borderColor: Colors.blueAccent.withOpacity(0.15),
                borderStrokeWidth: 1,
              ),
            ],
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: userLocation,
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: (userHeading * (math.pi / 180)),
                      child: CustomPaint(
                        size: const Size(120, 120),
                        painter: GoogleDirectionPainter(),
                      ),
                    ),
                    //ря
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 22 * _pulseAnimation.value,
                          height: 22 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),

                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _animatedMapMove(userLocation, 17.0),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

class GoogleDirectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.4),
          Colors.blueAccent.withOpacity(0.0)
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;
    const double angleWidth = 20.0 * (math.pi / 180);

    final Path path = Path()
      ..moveTo(centerX, centerY)
      ..relativeLineTo(radius * math.sin(angleWidth), -radius * math.cos(angleWidth))
      ..arcToPoint(
        Offset(centerX - radius * math.sin(angleWidth), centerY - radius * math.cos(angleWidth)),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
