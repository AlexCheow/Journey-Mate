import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Sessions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
              final docId = sessions[index].id;
              final data = sessions[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final description = data['description'] ?? '';
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              final dateStr = time != null ? DateFormat.yMMMd().add_jm().format(time) : 'Unknown';
              final photos = (data['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final videos = (data['videos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final route = (data['route'] as List?)?.map((p) => LatLng(p['lat'], p['lng'])).toList() ?? [];
              final duration = data['duration'] ?? '--';
              final distance = data['distance'] ?? '--';
              final pace = data['pace'] ?? '--';

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
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('JourneyMate')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircleAvatar(
                                  child: Icon(Icons.person),
                                );
                              }
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                final photoUrl = userData['photoUrl'] ?? '';

                                if (photoUrl.isNotEmpty) {
                                  return CircleAvatar(
                                    backgroundImage: NetworkImage(photoUrl),
                                  );
                                }
                              }
                              // fallback if no photoUrl
                              return const CircleAvatar(
                                child: Icon(Icons.person),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(dateStr, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      if (route.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              center: route.first,
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
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(description, style: const TextStyle(color: Colors.black87)),
                        ),
                      const SizedBox(height: 4),
                      Text('Duration: $duration  |  Distance: $distance km  |  Pace: $pace'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _showEditDialog(context, sessions[index].id, title, description),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, docId),
                            icon: const Icon(Icons.delete),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share),
                          ),
                        ],
                      ),
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

  void _confirmDelete(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('sessions').doc(sessionId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMediaDialog(BuildContext context, List<String> urls, bool isVideo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: PageView(
            children: urls.map((url) => isVideo ? _VideoPreview(url: url) : Image.network(url, fit: BoxFit.cover)).toList(),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String sessionId, String currentTitle, String currentDescription) {
    final titleController = TextEditingController(text: currentTitle);
    final descController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Session'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 6,
                maxLength: 63206,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
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
}
