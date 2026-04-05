import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  final String? filePath;

  const AudioPlayerWidget({
    super.key,
    this.audioUrl,
    this.filePath,
  }) : assert(audioUrl != null || filePath != null);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _state = s); });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying = _state == PlayerState.playing;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (isPlaying) { await _player.pause(); }
              else {
                if (widget.filePath != null) {
                  await _player.play(DeviceFileSource(widget.filePath!));
                } else {
                  await _player.play(UrlSource(widget.audioUrl!));
                }
              }
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: cs.onPrimary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
                  onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                  activeColor: cs.primary,
                  inactiveColor: cs.primary.withOpacity(0.2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position), style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                    Text(_fmt(_duration), style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
