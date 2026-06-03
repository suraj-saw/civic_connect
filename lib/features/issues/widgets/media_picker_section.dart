import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'audio_picker_section.dart';
import 'image_picker_section.dart';
import 'video_picker_section.dart';

class MediaPickerSection extends StatelessWidget {
  const MediaPickerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.perm_media_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text('Media Attachments', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        const ImagePickerSection(),
        const SizedBox(height: 12),
        const VideoPickerSection(),
        const SizedBox(height: 12),
        const AudioPickerSection(),
      ],
    );
  }
}
