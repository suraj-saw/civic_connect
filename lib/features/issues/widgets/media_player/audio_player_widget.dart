import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/utils/date_formatter.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.onPlayerStateChanged,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data == PlayerState.playing;

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                      iconSize: 48,
                      color: Theme.of(context).primaryColor,
                      onPressed: () async {
                        if (isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.play(UrlSource(widget.audioUrl));
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Voice Description",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          StreamBuilder<Duration>(
                            stream: _audioPlayer.onPositionChanged,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              return Text(
                                DateFormatter.formatDuration(position),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () async {
                        await _audioPlayer.stop();
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.onPositionChanged,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: _audioPlayer.onDurationChanged,
          builder: (context, durSnapshot) {
            final duration = durSnapshot.data ?? Duration.zero;

            return LinearProgressIndicator(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0,
            );
          },
        );
      },
    );
  }
}