import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin  {
  final String mapboxToken = dotenv.env['TOKEN_MAP']!;
  
  LatLng userLocation = const LatLng(51.23547305664311, 22.548898519702192);
  double userHeading = 0.0;
  double userAccuracy = 50.0;
  
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;


  late AnimationController _animationController;
  Animation<LatLng>? _latLngAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), 
      vsync: this,
    );
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;


    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
        );
      }
      return;
    }


    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in settings.')),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    _updateState(position, animate: false);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2, 
      ),
    ).listen((Position position) {
      _updateState(position, animate: true);
    });
  }

  void _updateState(Position position, {bool animate = true}) {
    if (position.accuracy > 80) return; 

    LatLng newLocation = LatLng(position.latitude, position.longitude);

    if (animate) {
      _animateMarker(newLocation);
    } else {
      setState(() {
        userLocation = newLocation;
      });
    }

    setState(() {
      userAccuracy = position.accuracy;
      if (position.heading >= 0) userHeading = position.heading;
    });
  }

  void _animateMarker(LatLng destination) {
    final start = userLocation;
    
    if (start.latitude == destination.latitude && start.longitude == destination.longitude) return;

    _latLngAnimation = LatLngTween(
      begin: start,
      end: destination,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ))
      ..addListener(() {
        setState(() {
          userLocation = _latLngAnimation!.value;
        });
      });

    _animationController.forward(from: 0);
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

          // Коло точності
          CircleLayer(
            circles: [
              CircleMarker(
                point: userLocation,
                radius: userAccuracy,
                useRadiusInMeter: true,
                color: Colors.blueAccent.withOpacity(0.15),
                borderColor: Colors.blueAccent.withOpacity(0.3),
                borderStrokeWidth: 1,
              ),
            ],
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: userLocation,
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: (userHeading * (math.pi / 180)),
                      child: CustomPaint(
                        size: const Size(100, 100),
                        painter: DirectionBeamPainter(),
                      ),
                    ),

                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))
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
        onPressed: () {
          _initLocation(); // Перевіряємо права при натисканні
          _animatedMapMove(userLocation, 17.0);
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
     );
  }
}

class DirectionBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blueAccent.withOpacity(0.4), Colors.blueAccent.withOpacity(0.0)],
        stops: const [0.1, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2));

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;
    final double angleWidth = 30.0 * (math.pi / 180);

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
