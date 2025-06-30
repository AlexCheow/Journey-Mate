<<<<<<< HEAD
//lib/provider/record_session_provider.dart
import 'dart:async';

=======
import 'dart:async';
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RecordSessionProvider with ChangeNotifier {
  bool isRecording = false;
  List<LatLng> routePoints = [];
  List<Map<String, dynamic>> _pendingPhotos = [];
<<<<<<< HEAD
=======
  List<Map<String, dynamic>> _pendingVideos = []; // ✅ New
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
  LatLng? currentLocation;
  double totalDistance = 0.0;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
<<<<<<< HEAD

  DateTime? get startTime => _startTime;
=======
  String? _title; // ✅ Added

  DateTime? get startTime => _startTime;
  String? get title => _title; // ✅ Getter

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99

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
    _pendingPhotos.clear();
<<<<<<< HEAD
=======
    _pendingVideos.clear();
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
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

  void addLocalPhoto(File image) {
    if (currentLocation != null) {
      _pendingPhotos.add({'file': image, 'location': currentLocation!});
      notifyListeners();
    }
  }

<<<<<<< HEAD
  List<Map<String, dynamic>> get localPhotos => _pendingPhotos;
=======
  void addLocalVideo(File video) { // ✅ New
    if (currentLocation != null) {
      _pendingVideos.add({'file': video, 'location': currentLocation!});
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get localPhotos => _pendingPhotos;
  List<Map<String, dynamic>> get localVideos => _pendingVideos; // ✅ New
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99

  Future<List<Map<String, dynamic>>> uploadAllPhotos() async {
    final List<Map<String, dynamic>> result = [];
    final storage = FirebaseStorage.instance;

    for (final p in _pendingPhotos) {
      final file = p['file'] as File;
      final loc = p['location'] as LatLng;
      final ref = storage.ref('session_photos/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      result.add({
        'lat': loc.latitude,
        'lng': loc.longitude,
        'imageUrl': url,
      });
    }

    return result;
  }

<<<<<<< HEAD
=======
  Future<List<Map<String, dynamic>>> uploadAllVideos() async { // ✅ New
    final List<Map<String, dynamic>> result = [];
    final storage = FirebaseStorage.instance;

    for (final v in _pendingVideos) {
      final file = v['file'] as File;
      final loc = v['location'] as LatLng;
      final ref = storage.ref('session_videos/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      result.add({
        'lat': loc.latitude,
        'lng': loc.longitude,
        'videoUrl': url,
      });
    }

    return result;
  }

>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
