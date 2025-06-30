//lib/screens/history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Sessions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final data = sessions[index].data() as Map<String, dynamic>;
              final route = (data['route'] as List)
                  .map((p) => LatLng(p['lat'], p['lng']))
                  .toList();
              final photos = (data['photos'] as List?) ?? [];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ExpansionTile(
                  title: Text('Session on ${data['startTime']?.substring(0, 16)}'),
                  children: [
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          center: route.isNotEmpty ? route.first : LatLng(0, 0),
                          zoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.example.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: route,
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              ...photos.map((photo) {
                                final location = LatLng(photo['lat'], photo['lng']);
                                return Marker(
                                  point: location,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.camera_alt, color: Colors.purple),
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('Duration: ${data['duration'] ?? '--'}'),
                      subtitle: Text('Distance: ${data['distance']?.toStringAsFixed(2)} km\nPace: ${data['pace'] ?? '--'}'),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
