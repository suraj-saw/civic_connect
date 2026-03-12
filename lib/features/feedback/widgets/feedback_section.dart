import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/feedback_controller.dart';
import '../models/citizen_model_feedback.dart';
import 'reopen_section.dart';

class FeedbackSection extends StatelessWidget {
  final String issueId;

  const FeedbackSection({super.key, required this.issueId});

  FeedbackController _controller() {
    if (!Get.isRegistered<FeedbackController>(tag: issueId)) {
      Get.put(FeedbackController(issueId: issueId), tag: issueId);
    }
    return Get.find<FeedbackController>(tag: issueId);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller();

    return Obx(() {
      if (ctrl.isCheckingExisting.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (ctrl.alreadySubmitted.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubmittedCard(feedback: ctrl.existingFeedback.value),

            // If citizen said not fixed → show reopen section below.
            if (ctrl.existingFeedback.value != null &&
                !ctrl.existingFeedback.value!.issueActuallyFixed)
              ReopenSection(ctrl: ctrl),
          ],
        );
      }

      return _FeedbackForm(ctrl: ctrl);
    });
  }
}

// ── Submitted summary card ────────────────────────────────────────────────────

class _SubmittedCard extends StatelessWidget {
  final CitizenFeedbackModel? feedback;

  const _SubmittedCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Feedback Submitted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (feedback != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _row('Overall Satisfaction', _stars(feedback!.overallRating)),
            _row('Work Quality', _stars(feedback!.workQualityScore)),
            _row('Response Timeliness', _stars(feedback!.timelinessScore)),
            _row(
              'Issue actually fixed?',
              feedback!.issueActuallyFixed ? '✅ Yes' : '❌ No',
            ),
            if (feedback!.comments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${feedback!.comments}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Submitted on ${DateFormat('dd MMM yyyy').format(feedback!.submittedAt)}',
              style:
              TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 5,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(
            flex: 4,
            child: Text(value,
                style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  String _stars(int count) => '${'⭐' * count}  ($count/5)';
}

// ── Pending form — unchanged from previous implementation ─────────────────────

class _FeedbackForm extends StatelessWidget {
  final FeedbackController ctrl;

  const _FeedbackForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Rate the Resolution',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Accountability Record',
                    style:
                    TextStyle(fontSize: 10, color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your honest feedback holds authorities accountable.',
            style:
            TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          _StarRow(
              label: 'Overall Satisfaction',
              value: ctrl.overallRating,
              color: Colors.amber),
          const SizedBox(height: 14),
          _StarRow(
              label: 'Work Quality',
              value: ctrl.workQualityScore,
              color: Colors.blue),
          const SizedBox(height: 14),
          _StarRow(
              label: 'Response Timeliness',
              value: ctrl.timelinessScore,
              color: Colors.purple),
          const SizedBox(height: 20),
          const Text('Is the issue actually fixed on the ground?',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Obx(() => Row(
            children: [
              _FixedToggle(
                label: 'Yes, fixed',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
                selected: ctrl.issueActuallyFixed.value,
                onTap: () => ctrl.issueActuallyFixed.value = true,
              ),
              const SizedBox(width: 10),
              _FixedToggle(
                label: 'No, still a problem',
                icon: Icons.cancel_outlined,
                color: Colors.red,
                selected: !ctrl.issueActuallyFixed.value,
                onTap: () => ctrl.issueActuallyFixed.value = false,
              ),
            ],
          )),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => ctrl.comments.value = v,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Comments *',
              hintText:
              'Describe the work done, what was good, or what could be improved...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              ctrl.isSubmitting.value ? null : ctrl.submit,
              icon: ctrl.isSubmitting.value
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(ctrl.isSubmitting.value
                  ? 'Submitting...'
                  : 'Submit Feedback'),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final String label;
  final RxInt value;
  final Color color;

  const _StarRow(
      {required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => value.value = star,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  star <= value.value
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: star <= value.value
                      ? color
                      : Colors.grey.shade300,
                  size: 26,
                ),
              ),
            );
          }),
        )),
      ],
    );
  }
}

class _FixedToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FixedToggle(
      {required this.label,
        required this.icon,
        required this.color,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : Colors.grey.shade400,
                  size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    selected ? color : Colors.grey.shade500,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}