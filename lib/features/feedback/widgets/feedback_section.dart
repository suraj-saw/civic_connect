import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../controllers/feedback_controller.dart';
import '../models/citizen_model_feedback.dart';
import 'reopen_section.dart';

class FeedbackSection extends StatelessWidget {
  final String issueId;
  const FeedbackSection({super.key, required this.issueId});

  FeedbackController _ctrl() {
    if (!Get.isRegistered<FeedbackController>(tag: issueId)) {
      Get.put(FeedbackController(issueId: issueId), tag: issueId);
    }
    return Get.find<FeedbackController>(tag: issueId);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl();
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
            _SubmittedCard(
              feedback: ctrl.existingFeedback.value,
            ).animate().fadeIn(),
            if (ctrl.existingFeedback.value != null &&
                !ctrl.existingFeedback.value!.issueActuallyFixed)
              ReopenSection(ctrl: ctrl).animate().fadeIn(delay: 100.ms),
          ],
        );
      }
      return _FeedbackForm(ctrl: ctrl).animate().fadeIn();
    });
  }
}

class _SubmittedCard extends StatelessWidget {
  final CitizenFeedbackModel? feedback;
  const _SubmittedCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      constraints: const BoxConstraints(
        minHeight: AppDimensions.actionCardMinHeight,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
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
            Divider(color: Colors.green.shade200),
            const SizedBox(height: 8),
            _row('Overall Satisfaction', _stars(feedback!.overallRating)),
            _row('Work Quality', _stars(feedback!.workQualityScore)),
            _row('Response Timeliness', _stars(feedback!.timelinessScore)),
            _row(
              'Issue fixed?',
              feedback!.issueActuallyFixed ? '✅ Yes' : '❌ No',
            ),
            if (feedback!.comments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${feedback!.comments}"',
                  style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    ),
  );

  String _stars(int n) => '${'⭐' * n} ($n/5)';
}

class _FeedbackForm extends StatelessWidget {
  final FeedbackController ctrl;
  const _FeedbackForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      constraints: const BoxConstraints(
        minHeight: AppDimensions.actionCardMinHeight,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rate the Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Accountability',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your honest feedback holds authorities accountable.',
            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          Divider(height: 24, color: cs.outline.withValues(alpha: 0.15)),
          _StarRow(
            label: 'Overall Satisfaction',
            value: ctrl.overallRating,
            color: Colors.amber,
          ),
          const SizedBox(height: 14),
          _StarRow(
            label: 'Work Quality',
            value: ctrl.workQualityScore,
            color: Colors.blue,
          ),
          const SizedBox(height: 14),
          _StarRow(
            label: 'Response Timeliness',
            value: ctrl.timelinessScore,
            color: Colors.purple,
          ),
          const SizedBox(height: 20),
          Text(
            'Is the issue actually fixed on the ground?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
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
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => ctrl.comments.value = v,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Comments *',
              hintText:
                  'Describe the work done, what was good or could be improved...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: ctrl.isSubmitting.value ? null : ctrl.submit,
                icon:
                    ctrl.isSubmitting.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  ctrl.isSubmitting.value ? 'Submitting...' : 'Submit Feedback',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final String label;
  final RxInt value;
  final Color color;
  const _StarRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => value.value = i + 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i + 1 <= value.value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i + 1 <= value.value ? color : Colors.grey.shade300,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
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
  const _FixedToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : Colors.grey.shade400,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? color : Colors.grey.shade500,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
