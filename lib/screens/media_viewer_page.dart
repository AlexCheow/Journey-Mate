import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaViewerPage extends StatefulWidget {
  final String type;
  final String url;

  const MediaViewerPage({super.key, required this.type, required this.url});

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoController = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'photo' ? 'Photo' : 'Video'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: widget.type == 'photo'
            ? Image.network(widget.url)
            : (_videoController != null && _videoController!.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        )
            : const CircularProgressIndicator()),
      ),
      floatingActionButton: widget.type == 'video' && _videoController != null
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _videoController!.value.isPlaying
                ? _videoController!.pause()
                : _videoController!.play();
          });
        },
        child: Icon(
          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}
