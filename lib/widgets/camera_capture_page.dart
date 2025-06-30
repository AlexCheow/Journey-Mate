//lib/widgets/camera_capture_page.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  /// Returns a `File` (image) when the user taps ✓, or `null` on cancel.
  static Future<File?> open(BuildContext context) {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
  }

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _cam;
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    _cam = CameraController(cams.first, ResolutionPreset.medium);
    await _cam.initialize();
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _ready,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              CameraPreview(_cam),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () async {
                      final file = await _cam.takePicture();
                      if (context.mounted) Navigator.pop(context, File(file.path));
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
