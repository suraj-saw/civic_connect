import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? videoUrl;
  final String? filePath;
  final double? previewAspectRatio;

  const VideoPlayerWidget({
    super.key,
    this.videoUrl,
    this.filePath,
    this.previewAspectRatio,
  }) : assert(videoUrl != null || filePath != null);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.filePath != null
        ? VideoPlayerController.file(File(widget.filePath!))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
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
    if (!_initialized) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final sourceSize = _ctrl.value.size;
    final sourceWidth = sourceSize.width <= 0 ? 16.0 : sourceSize.width;
    final sourceHeight = sourceSize.height <= 0 ? 9.0 : sourceSize.height;
    final effectiveAspectRatio =
        widget.previewAspectRatio ?? _ctrl.value.aspectRatio;
    final previewFit =
        widget.previewAspectRatio != null ? BoxFit.cover : BoxFit.contain;
    final isPlaying = _ctrl.value.isPlaying;

    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: effectiveAspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => isPlaying ? _ctrl.pause() : _ctrl.play(),
              child: FittedBox(
                fit: previewFit,
                child: SizedBox(
                  width: sourceWidth,
                  height: sourceHeight,
                  child: VideoPlayer(_ctrl),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: isPlaying,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 22, 8, 6),
                child: Row(
                  children: [
                    IconButton(
                      splashRadius: 18,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => isPlaying ? _ctrl.pause() : _ctrl.play(),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _ctrl,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_fmt(_ctrl.value.position)} / ${_fmt(_ctrl.value.duration)}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                    ),
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
