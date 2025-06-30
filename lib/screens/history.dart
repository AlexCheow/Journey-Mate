<<<<<<< HEAD
//lib/screens/history.dart
=======
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
<<<<<<< HEAD
import 'dart:io';
=======
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
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
=======
      appBar: AppBar(title: const Text('Your Sessions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No sessions recorded yet.'));
          }

          final sessions = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final data = sessions[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              final dateStr = time != null ? DateFormat.yMMMd().add_jm().format(time) : 'Unknown';
              final photos = (data['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final videos = (data['videos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final route = (data['route'] as List?)?.map((p) => LatLng(p['lat'], p['lng'])).toList() ?? [];
              final duration = data['duration'] ?? '--';
              final distance = data['distance'] ?? '--';
              final pace = data['pace'] ?? '--';

              final mediaWidgets = [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
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
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.journeymate',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: route,
                                  color: Colors.blue,
                                  strokeWidth: 4,
                                )
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                ...photos.map((p) => Marker(
                                  point: LatLng(p['lat'], p['lng']),
                                  width: 30,
                                  height: 30,
                                  child: GestureDetector(
                                    onTap: () => _showMediaDialog(context, [p['imageUrl']], false),
                                    child: const Icon(Icons.photo, color: Colors.purple),
                                  ),
                                )),
                                ...videos.map((v) => Marker(
                                  point: LatLng(v['lat'], v['lng']),
                                  width: 30,
                                  height: 30,
                                  child: GestureDetector(
                                    onTap: () => _showMediaDialog(context, [v['videoUrl']], true),
                                    child: const Icon(Icons.videocam, color: Colors.red),
                                  ),
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Row(
                          children: [
                            if (photos.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.photo, color: Colors.white, size: 30),
                                onPressed: () {
                                  _showMediaDialog(context, photos.map((e) => e['imageUrl'].toString()).toList(), false);
                                },
                              ),
                            if (videos.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.videocam, color: Colors.white, size: 30),
                                onPressed: () {
                                  _showMediaDialog(context, videos.map((e) => e['videoUrl'].toString()).toList(), true);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...photos.map((p) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(p['imageUrl'], height: 200, fit: BoxFit.cover),
                )),
                ...videos.map((v) => SizedBox(height: 200, child: _VideoPreview(url: v['videoUrl'])))
              ];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(dateStr, style: const TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (mediaWidgets.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: PageView(
                            children: mediaWidgets,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Duration: $duration  |  Distance: $distance km  |  Pace: $pace'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
                        ],
                      ),
                    ],
                  ),
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
                ),
              );
            },
          );
        },
      ),
    );
  }
<<<<<<< HEAD
=======

  void _showMediaDialog(BuildContext context, List<String> urls, bool isVideo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: PageView(
            children: urls.map((url) => Stack(
              alignment: Alignment.topRight,
              children: [
                isVideo ? _VideoPreview(url: url) : Image.network(url),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadFile(context, url),
                ),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied.')),
        );
        return;
      }
      final dir = await getExternalStorageDirectory();
      final fileName = url.split('/').last.split('?').first;
      final savePath = '${dir!.path}/$fileName';
      await Dio().download(url, savePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
          ],
        ),
      ),
    )
        : const Center(child: CircularProgressIndicator());
  }
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
}
