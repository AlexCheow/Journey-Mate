import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalSessions = 0;
  double totalDistance = 0;
  Duration totalDuration = Duration.zero;
  int totalPhotos = 0;
  int totalVideos = 0;
  double averagePace = 0;

  @override
  void initState() {
    super.initState();
    _calculateSummary();
  }

  Future<void> _calculateSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('userId', isEqualTo: uid)
          .get();

      double paceSum = 0;
      int paceCount = 0;

      setState(() {
        totalSessions = snapshot.docs.length;

        totalDistance = snapshot.docs.fold(0.0, (sum, doc) {
          final distanceStr = doc['distance']?.toString() ?? '0';
          return sum + (double.tryParse(distanceStr) ?? 0.0);
        });

        totalDuration = snapshot.docs.fold(Duration.zero, (sum, doc) {
          final durationStr = doc['duration'] ?? '00:00:00';
          final parts = durationStr.split(':').map(int.parse).toList();
          return sum + Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
        });

        totalPhotos = snapshot.docs.fold(0, (sum, doc) => sum + ((doc['photos'] as List?)?.length ?? 0));
        totalVideos = snapshot.docs.fold(0, (sum, doc) => sum + ((doc['videos'] as List?)?.length ?? 0));

        for (var doc in snapshot.docs) {
          final paceStr = doc['pace']?.toString() ?? '0';
          final paceValue = double.tryParse(paceStr) ?? 0;
          if (paceValue > 0) {
            paceSum += paceValue;
            paceCount++;
          }
        }

        averagePace = paceCount > 0 ? paceSum / paceCount : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JOURNEYMATE"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummarySection(),
          const SizedBox(height: 16),
          _buildUpcomingEventsSection(),
          const SizedBox(height: 16),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final formattedDuration = totalDuration.inHours.toString().padLeft(2, '0') +
        ':' +
        (totalDuration.inMinutes % 60).toString().padLeft(2, '0') +
        ':' +
        (totalDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.directions_run, "Total Sessions", "$totalSessions"),
          _buildSummaryRow(Icons.map, "Total Distance", "${totalDistance.toStringAsFixed(2)} km"),
          _buildSummaryRow(Icons.timer, "Total Duration", formattedDuration),
          _buildSummaryRow(Icons.photo, "Photos", "$totalPhotos"),
          _buildSummaryRow(Icons.videocam, "Videos", "$totalVideos"),
          _buildSummaryRow(Icons.speed, "Avg Pace", "${averagePace.toStringAsFixed(2)} min/km"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    final events = [
      {
        'title': 'Hiking Event',
        'date': 'Aug 20, 2025',
        'description': 'Join us for a fun hiking trip!',
        'image': 'assets/hiking.png'
      },
      {
        'title': 'Cycling Marathon',
        'date': 'Sep 12, 2025',
        'description': 'Test your endurance with fellow cyclists.',
        'image': 'assets/cycling.png'
      },
      {
        'title': 'Photography Walk',
        'date': 'Oct 5, 2025',
        'description': 'Capture nature\'s beauty.',
        'image': 'assets/photography.png'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Events",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/upcoming-events', arguments: event);
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.asset(event['image']!, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(event['date']!, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(event['description']!, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Sessions",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final data = sessions[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled';
                final description = data['description'] ?? '';
                final time = (data['timestamp'] as Timestamp?)?.toDate();
                final dateStr = time != null
                    ? DateFormat.yMMMd().add_jm().format(time)
                    : 'Unknown';
                final route = (data['route'] as List?)
                    ?.map((p) => LatLng(p['lat'], p['lng']))
                    .toList() ??
                    [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(dateStr, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: FlutterMap(
                            options: MapOptions(
                              center: route.isNotEmpty ? route.first : LatLng(0, 0),
                              zoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.journeymate',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(points: route, color: Colors.blue, strokeWidth: 4),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (description.isNotEmpty)
                          Text(description, style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
