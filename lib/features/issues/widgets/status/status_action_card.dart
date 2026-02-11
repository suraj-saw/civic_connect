import 'package:flutter/material.dart';

class StatusActionCard extends StatelessWidget {
  final String currentStatus;
  final VoidCallback onMarkInProgress;
  final VoidCallback onReject;

  const StatusActionCard({
    super.key,
    required this.currentStatus,
    required this.onMarkInProgress,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (currentStatus == 'reported' || currentStatus == 'assigned') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Mark as In Progress"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onMarkInProgress,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  "Reject Issue",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: onReject,
              ),
            ),
          ],
        ),
      ),
    );
  }
}