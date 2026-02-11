import 'package:flutter/material.dart';
import 'description_field.dart';
import 'category_dropdown.dart';

class ReportIssueForm extends StatelessWidget {
  const ReportIssueForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DescriptionField(),
        const SizedBox(height: 24),
        const CategoryDropdown(),
      ],
    );
  }
}