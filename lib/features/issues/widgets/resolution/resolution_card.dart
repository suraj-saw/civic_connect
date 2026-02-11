import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class ResolutionCard extends StatelessWidget {
  final Map<String, dynamic> resolution;

  const ResolutionCard({super.key, required this.resolution});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.successBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolution['imageUrl'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resolution['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Failed to load image')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (resolution['notes'] != null &&
                resolution['notes'].toString().isNotEmpty) ...[
              const Text(
                "Resolution Notes:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(resolution['notes']),
              const SizedBox(height: 12),
            ],
            Text(
              "Resolved on: ${DateFormatter.formatTimestamp(resolution['resolvedAt'])}",
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}