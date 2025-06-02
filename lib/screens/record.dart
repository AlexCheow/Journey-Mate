import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/record_session_provider.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordSessionProvider>().initializeLocation();
    });
  }

  Future<void> _capturePhoto() async {
    final provider = context.read<RecordSessionProvider>();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && provider.currentLocation != null) {
      provider.addPhoto(File(image.path));
    }
  }

  Future<void> _saveSessionToFirestore() async {
    final provider = context.read<RecordSessionProvider>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionData = {
      'userId': user.uid,
      'startTime': provider.startTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'duration': provider.formattedDuration,
      'distance_km': (provider.totalDistance / 1000).toStringAsFixed(2),
      'pace': provider.pace,
      'route': provider.routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'photos': provider.photos
          .map((p) => {
        'lat': p['location'].latitude,
        'lng': p['location'].longitude,
        'path': p['image'].path,
      })
          .toList(),
    };

    await FirebaseFirestore.instance.collection('sessions').add(sessionData);
  }

  void _handleStopRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording'),
        content: const Text('Are you sure you want to stop and save this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      context.read<RecordSessionProvider>().stopRecording();
      await _saveSessionToFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordSessionProvider>();

    return Scaffold(
      body: Stack(
        children: [
          if (provider.currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: provider.currentLocation,
                zoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: provider.routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: provider.currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.red, size: 30),
                    ),
                    ...provider.photos.map(
                          (photo) => Marker(
                        point: photo['location'],
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.camera_alt, color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            top: 30,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (provider.currentLocation != null) {
                  _mapController.move(provider.currentLocation!, 16.0);
                }
              },
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            const Text('⏱ Time'),
                            Text(provider.formattedDuration),
                          ]),
                          Column(children: [
                            const Text('📏 Distance'),
                            Text('${(provider.totalDistance / 1000).toStringAsFixed(2)} km'),
                          ]),
                          Column(children: [
                            const Text('🏃 Pace'),
                            Text(provider.pace),
                          ]),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: provider.isRecording ? _handleStopRecording : provider.startRecording,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: provider.isRecording ? Colors.red : Colors.green,
                        ),
                        child: Icon(provider.isRecording ? Icons.stop : Icons.play_arrow, size: 30),
                      ),
                      ElevatedButton(
                        onPressed: provider.isRecording ? _capturePhoto : null,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Icon(Icons.camera_alt, size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
