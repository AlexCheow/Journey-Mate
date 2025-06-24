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
  final ImagePicker _picker   = ImagePicker();
  final MapController _mapCtl = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordSessionProvider>().initializeLocation();
    });
  }

  // ───────── photo capture ───────────────────────────────────
  Future<void> _capturePhoto() async {
    //  Ⓐ  inside _capturePhoto()
    final prov = context.read<RecordSessionProvider>();
    final x    = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) prov.addLocalPhoto(File(x.path));      // use new name

  }

  // ───────── save session to Firestore ───────────────────────
  Future<void> _saveSession() async {
    final prov = context.read<RecordSessionProvider>();
    final photos = await prov.uploadAllPhotos();
    final user = FirebaseAuth.instance.currentUser; // ✅ get current user

    if (user == null) return;

    await FirebaseFirestore.instance.collection('sessions').add({
      'userId': user.uid,
      'startTime': prov.startTime?.toIso8601String(),
      'duration': prov.formattedDuration,
      'distance': (prov.totalDistance / 1000).toStringAsFixed(2),
      'pace': prov.pace,
      'route': prov.routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'photos': photos,
    });
  }


  // ───────── stop & confirm ──────────────────────────────────
  Future<void> _stopAndSave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title   : const Text('Stop recording?'),
        content : const Text('Save this session to history?'),
        actions : [
          TextButton(onPressed: () => Navigator.pop(context,false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context,true ), child: const Text('Save')),
        ],
      ),
    );
    if (ok ?? false) {
      context.read<RecordSessionProvider>().stopRecording();
      await _saveSession();
    }
  }

  // ───────── view photo dialog ───────────────────────────────
  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }

  // ────────── UI ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecordSessionProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // ---------- map ------------
          if (prov.currentLocation != null)
            FlutterMap(
              mapController: _mapCtl,
              options: MapOptions(
                center: prov.currentLocation,
                zoom  : 16,
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
                      color : Colors.blue,
                      strokeWidth: 4,
                    )
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // live position
                    Marker(
                      point : prov.currentLocation!,
                      width : 40,
                      height: 40,
                      child : const Icon(Icons.my_location,
                          color: Colors.red, size: 30),
                    ),
                    // photo markers
                    ...prov.localPhotos.map((p) => Marker(
                      point : p['location'],
                      width : 35,
                      height: 35,
                      child : GestureDetector(
                        onTap: () => _showPhoto(p['imageUrl']),
                        child: const Icon(Icons.camera_alt, color: Colors.purple),
                      ),
                    )),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // ---------- recenter button -----------
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

          // ---------- control panel --------------
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
                      // start / stop
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: prov.isRecording ? Colors.red : Colors.green,
                        ),
                        onPressed: prov.isRecording ? _stopAndSave : prov.startRecording,
                        child: Icon(prov.isRecording ? Icons.stop : Icons.play_arrow, size: 28),
                      ),
                      // photo
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed: prov.isRecording ? _capturePhoto : null,
                        child: const Icon(Icons.camera_alt, size: 28),
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
