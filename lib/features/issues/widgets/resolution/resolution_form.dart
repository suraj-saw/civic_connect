import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ResolutionForm extends StatefulWidget {
  final Function(File image, String notes) onSubmit;
  final bool isSubmitting;

  const ResolutionForm({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<ResolutionForm> createState() => _ResolutionFormState();
}

class _ResolutionFormState extends State<ResolutionForm> {
  File? _resolutionImage;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Resolution Evidence",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_resolutionImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _resolutionImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _resolutionImage = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text("Camera"),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text("Gallery"),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: "Resolution Notes (Optional)",
        border: OutlineInputBorder(),
        hintText: "Describe the actions taken...",
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: widget.isSubmitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.check_circle),
        label: Text(widget.isSubmitting ? "Submitting..." : "Mark as Resolved"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        onPressed: widget.isSubmitting || _resolutionImage == null
            ? null
            : () => widget.onSubmit(_resolutionImage!, _notesController.text.trim()),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _resolutionImage = File(image.path);
      });
    }
  }
}