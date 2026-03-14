import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) { if (mounted) setState(() => _initialized = true); });
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_initialized) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play(),
            child: AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_ctrl.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: () => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play(),
                ),
                Expanded(
                  child: VideoProgressIndicator(_ctrl, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white38, backgroundColor: Colors.white24)),
                ),
                const SizedBox(width: 8),
                Text('${_fmt(_ctrl.value.position)} / ${_fmt(_ctrl.value.duration)}',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
