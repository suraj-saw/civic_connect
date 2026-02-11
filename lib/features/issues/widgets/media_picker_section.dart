import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'image_picker_section.dart';
import 'video_picker_section.dart';
import 'audio_picker_section.dart';

class MediaPickerSection extends StatelessWidget {
  const MediaPickerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 12),
        const ImagePickerSection(),
        const SizedBox(height: 12),
        const VideoPickerSection(),
        const SizedBox(height: 12),
        const AudioPickerSection(),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Add Media (Optional)',
        style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}