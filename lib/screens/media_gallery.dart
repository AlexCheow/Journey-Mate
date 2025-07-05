import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'media_viewer_page.dart';

class MediaGalleryPage extends StatelessWidget {
  const MediaGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Media'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: uid == null
          ? const Center(child: Text('User not logged in'))
          : FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('sessions')
            .where('userId', isEqualTo: uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No media found'));
          }

          final photos = <String>[];
          final videos = <String>[];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            final photoList = (data['photos'] as List?) ?? [];
            for (var item in photoList) {
              if (item is Map && item['imageUrl'] != null) {
                photos.add(item['imageUrl']);
              }
            }

            final videoList = (data['videos'] as List?) ?? [];
            for (var item in videoList) {
              if (item is Map && item['videoUrl'] != null) {
                videos.add(item['videoUrl']);
              }
            }
          }

          final allMedia = [
            ...photos.map((url) => {'type': 'photo', 'url': url}),
            ...videos.map((url) => {'type': 'video', 'url': url}),
          ];

          if (allMedia.isEmpty) {
            return const Center(child: Text('No media found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: allMedia.length,
            itemBuilder: (context, index) {
              final item = allMedia[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaViewerPage(
                        type: item['type']!,
                        url: item['url']!,
                      ),
                    ),
                  );
                },
                child: item['type'] == 'photo'
                    ? Image.network(item['url']!, fit: BoxFit.cover)
                    : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/video_placeholder.png', fit: BoxFit.cover),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                    ),
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
