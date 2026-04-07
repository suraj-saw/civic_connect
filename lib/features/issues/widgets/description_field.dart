import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/report_issue_controller.dart';

class DescriptionField extends GetView<ReportIssueController> {
  const DescriptionField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Description', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(' *', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.descriptionTextController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (v) {
            controller.description.value = v;
            controller.isFormDirty.value = true;
          },
          decoration: const InputDecoration(
            hintText: 'Describe the issue clearly — what you see, where it is, and any relevant details...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
