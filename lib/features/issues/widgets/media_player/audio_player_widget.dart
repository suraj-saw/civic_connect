import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _state = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPlaying = _state == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: scheme.onPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress + labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (v) {
                      final target = Duration(
                        milliseconds:
                        (v * _duration.inMilliseconds).toInt(),
                      );
                      _player.seek(target);
                    },
                    activeColor: scheme.primary,
                    inactiveColor: scheme.outlineVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position),
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant)),
                      Text(_fmt(_duration),
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stop button — only when playing
          if (isPlaying) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _player.stop(),
              child: Icon(Icons.stop_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}