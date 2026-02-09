import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/report_issue/report_issue_controller.dart';
import '../../controllers/report_issue/issue_category_controller.dart';

class ReportIssuePage extends StatelessWidget {
  const ReportIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final issueController = Get.find<ReportIssueController>();
    final categoryController = Get.find<IssueCategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /* ===================== PHOTO ===================== */

              Text(
                "Capture Photo",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Obx(() {
                final path = issueController.selectedImagePath.value;

                if (path == null) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Take Photo"),
                      onPressed: issueController.pickImage,
                    ),
                  );
                }

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon:
                          const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                          issueController.selectedImagePath.value = null,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              /* ===================== VIDEO ===================== */

              Text(
                "Or Record Video",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Obx(() {
                final path = issueController.selectedVideoPath.value;

                if (path == null) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text("Record Video"),
                      onPressed: issueController.pickVideo,
                    ),
                  );
                }

                return VideoPreviewWidget(
                  videoFile: File(path),
                  onRemove: () =>
                  issueController.selectedVideoPath.value = null,
                );
              }),

              const SizedBox(height: 24),

              /* ===================== DESCRIPTION ===================== */

              Text(
                "Description",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              TextField(
                maxLines: 4,
                onChanged: (value) =>
                issueController.description.value = value,
                decoration: InputDecoration(
                  hintText: "Describe the issue...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /* ===================== AUDIO ===================== */

              Obx(() {
                final isRecording = issueController.isRecording.value;
                final hasAudio =
                    issueController.recordedAudioPath.value != null;

                return OutlinedButton.icon(
                  icon: Icon(
                    isRecording
                        ? Icons.stop
                        : hasAudio
                        ? Icons.check_circle
                        : Icons.mic,
                    color: isRecording
                        ? Colors.red
                        : hasAudio
                        ? Colors.green
                        : null,
                  ),
                  label: Text(
                    isRecording
                        ? "Stop Recording"
                        : hasAudio
                        ? "Voice Description Added"
                        : "Add Voice Description",
                  ),
                  onPressed: () async {
                    if (isRecording) {
                      await issueController.stopRecording();
                    } else {
                      await issueController.startRecording();
                    }
                  },
                );
              }),

              const SizedBox(height: 24),

              /* ===================== CATEGORY ===================== */

              Text(
                "Category",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Obx(() {
                if (categoryController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  hint: const Text("Select category"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: issueController.selectedCategory.value,
                  items: categoryController.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                      .toList(),
                  onChanged: (value) =>
                  issueController.selectedCategory.value = value,
                );
              }),

              const SizedBox(height: 36),

              /* ===================== SUBMIT ===================== */

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: issueController.isSubmitting.value
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.report),
                    label: const Text("Report Issue"),
                    onPressed: issueController.isSubmitting.value
                        ? null
                        : issueController.submitIssue,
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== VIDEO PREVIEW ===================== */

class VideoPreviewWidget extends StatefulWidget {
  final File videoFile;
  final VoidCallback onRemove;

  const VideoPreviewWidget({
    super.key,
    required this.videoFile,
    required this.onRemove,
  });

  @override
  State<VideoPreviewWidget> createState() =>
      _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon:
              const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onRemove,
            ),
          ),
        ),
      ],
    );
  }
}
