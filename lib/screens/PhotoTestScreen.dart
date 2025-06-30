//lib/screens/PhotoTestScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoTestScreen extends StatefulWidget {
  const PhotoTestScreen({super.key});

  @override
  State<PhotoTestScreen> createState() => _PhotoTestScreenState();
}

class _PhotoTestScreenState extends State<PhotoTestScreen> {
  File? _imageFile;
  bool _uploading = false;
  String? _downloadUrl;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _downloadUrl = null;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      setState(() => _uploading = true);

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(user.uid)
          .child(fileName);

      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user_photos')
          .doc(user.uid)
          .collection('photos')
          .add({
        'url': url,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _downloadUrl = url;
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful")),
      );
    } catch (e) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photo Upload Test")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_imageFile != null)
                Image.file(_imageFile!, height: 300)
              else
                const Text("No photo taken"),

              const SizedBox(height: 20),

              if (_uploading) const CircularProgressIndicator(),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Photo"),
                onPressed: _takePhoto,
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload to Firebase"),
                onPressed: _uploadPhoto,
              ),

              const SizedBox(height: 20),

              if (_downloadUrl != null)
                SelectableText(
                  "Download URL:\n$_downloadUrl",
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
