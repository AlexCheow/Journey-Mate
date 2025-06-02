import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RecordSessionProvider with ChangeNotifier {
  bool isRecording = false;
  List<LatLng> routePoints = [];
  List<Map<String, dynamic>> photos = [];
  LatLng? currentLocation;
  double totalDistance = 0.0;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  DateTime? get startTime => _startTime;

  String get formattedDuration {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get pace {
    if (totalDistance == 0) return '--';
    final pace = _elapsed.inSeconds / 60 / (totalDistance / 1000);
    return '${pace.toStringAsFixed(2)} min/km';
  }

  Future<void> initializeLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition();
    currentLocation = LatLng(position.latitude, position.longitude);
    notifyListeners();
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission != LocationPermission.deniedForever;
  }

  void startRecording() {
    isRecording = true;
    routePoints.clear();
    totalDistance = 0.0;
    _elapsed = Duration.zero;
    _startTime = DateTime.now();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      if (routePoints.isNotEmpty) {
        totalDistance += const Distance().as(LengthUnit.Meter, routePoints.last, newPoint);
      }

      currentLocation = newPoint;
      routePoints.add(newPoint);
      notifyListeners();
    });
  }

  void stopRecording() {
    isRecording = false;
    _timer?.cancel();
    _positionStream?.cancel();
    notifyListeners();
  }

  void addPhoto(File image) {
    if (currentLocation != null) {
      photos.add({'image': image, 'location': currentLocation!});
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
