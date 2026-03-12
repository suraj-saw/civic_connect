import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
    VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    _controller?.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(videoUrl: widget.videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _initialized ? _controller!.value.aspectRatio : 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _initialized
                ? VideoPlayer(_controller!)
                : Container(color: Colors.black12),
            // Dark overlay for tap affordance
            Container(color: Colors.black.withOpacity(0.18)),
            // Centre play button
            Center(
              child: GestureDetector(
                onTap: _openFullscreen,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 34),
                ),
              ),
            ),
            // "Tap to play" hint badge
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Tap to play',
                        style:
                        TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen video page ─────────────────────────────────────────────────────

class _FullscreenVideoPage extends StatefulWidget {
  final String videoUrl;
  const _FullscreenVideoPage({required this.videoUrl});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _controller =
    VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _duration = _controller.value.duration;
          });
          _controller.play();
        }
      });
    _controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (mounted) setState(() => _position = _controller.value.position);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _seek(Duration delta) {
    final target = _position + delta;
    if (target < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (target > _duration) {
      _controller.seekTo(_duration);
    } else {
      _controller.seekTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _initialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            if (_showControls) ...[
              // Top bar
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // Bottom gradient + controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(_position),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          Text(_fmt(_duration),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10,
                                color: Colors.white, size: 30),
                            onPressed: () =>
                                _seek(const Duration(seconds: -10)),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            }),
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.forward_10,
                                color: Colors.white, size: 30),
                            onPressed: () =>
                                _seek(const Duration(seconds: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}