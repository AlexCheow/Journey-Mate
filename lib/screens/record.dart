//lib/screens/record.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapCtl = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordSessionProvider>().initializeLocation();
    });
  }

  Future<void> _capturePhoto() async {
    final prov = context.read<RecordSessionProvider>();
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) prov.addLocalPhoto(File(x.path));
  }

  Future<void> _recordVideo() async {
    final prov = context.read<RecordSessionProvider>();
    final x = await _picker.pickVideo(source: ImageSource.camera);
    if (x != null) prov.addLocalVideo(File(x.path));
  }

  Future<void> _saveSession() async {
    final prov = context.read<RecordSessionProvider>();
    final photos = await prov.uploadAllPhotos();
    final videos = await prov.uploadAllVideos();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('sessions').add({
        'userId': user.uid,
        'title': prov.title ?? 'Untitled Session',
        'startTime': prov.startTime?.toIso8601String(),
        'duration': prov.formattedDuration,
        'distance': (prov.totalDistance / 1000).toStringAsFixed(2),
        'pace': prov.pace,
        'route': prov.routePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'photos': photos,
        'videos': videos,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save session: $e")),
      );
    }
  }

  Future<void> _stopAndSave() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Stop and Save'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Enter a title'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
          ],
        );
      },
    );

    if (title != null && title.isNotEmpty) {
      final prov = context.read<RecordSessionProvider>();
      prov.setTitle(title);
      prov.stopRecording();
      await _saveSession();
    }
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecordSessionProvider>();

    return Scaffold(
      body: Stack(
        children: [
          if (prov.currentLocation != null)
            FlutterMap(
              mapController: _mapCtl,
              options: MapOptions(
                center: prov.currentLocation,
                zoom: 20,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: prov.routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    )
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: prov.currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.red, size: 30),
                    ),
                    ...prov.localPhotos.map((p) => Marker(
                      point: p['location'],
                      width: 35,
                      height: 35,
                      child: GestureDetector(
                        onTap: () => _showPhoto(p['imageUrl']),
                        child: const Icon(Icons.camera_alt, color: Colors.purple),
                      ),
                    )),
                    ...prov.localVideos.map((v) => Marker(
                      point: v['location'],
                      width: 35,
                      height: 35,
                      child: const Icon(Icons.videocam, color: Colors.deepOrange),
                    )),
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
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: () {
                if (prov.currentLocation != null) {
                  _mapCtl.move(prov.currentLocation!, 16);
                }
              },
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
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prov.isRecording) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('⏱ Time', prov.formattedDuration),
                        _stat('📏 Dist', '${(prov.totalDistance / 1000).toStringAsFixed(2)} km'),
                        _stat('🏃 Pace', prov.pace),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: prov.isRecording ? Colors.red : Colors.green,
                        ),
                        onPressed: prov.isRecording ? _stopAndSave : prov.startRecording,
                        child: Icon(prov.isRecording ? Icons.stop : Icons.play_arrow, size: 28),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed: prov.isRecording ? _capturePhoto : null,
                        child: const Icon(Icons.camera_alt, size: 28),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed: prov.isRecording ? _recordVideo : null,
                        child: const Icon(Icons.videocam, size: 28),
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

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(value),
    ],
  );
}
