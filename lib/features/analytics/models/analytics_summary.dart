import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsSummary {
  final int total;
  final int open;
  final int resolved;
  final int rejected;
  final int inProgress;
  final int reported;
  final int reopened;
  final int unresolvedHighPriority;
  final double averageResolutionHours;
  final double averageDuplicateCount;
  final double citizenRatingAverage;
  final Map<String, int> statusCounts;
  final Map<String, int> categoryCounts;
  final Map<String, int> areaCounts;

  const AnalyticsSummary({
    required this.total,
    required this.open,
    required this.resolved,
    required this.rejected,
    required this.inProgress,
    required this.reported,
    required this.reopened,
    required this.unresolvedHighPriority,
    required this.averageResolutionHours,
    required this.averageDuplicateCount,
    required this.citizenRatingAverage,
    required this.statusCounts,
    required this.categoryCounts,
    required this.areaCounts,
  });

  double get resolutionRate => total == 0 ? 0 : (resolved / total) * 100;

  List<MapEntry<String, int>> topCategories({int limit = 4}) =>
      _topEntries(categoryCounts, limit: limit);

  List<MapEntry<String, int>> topAreas({int limit = 4}) =>
      _topEntries(areaCounts, limit: limit);

  static AnalyticsSummary fromIssues(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var resolved = 0;
    var rejected = 0;
    var inProgress = 0;
    var reported = 0;
    var reopened = 0;
    var unresolvedHighPriority = 0;
    var duplicateTotal = 0;

    final statusCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final areaCounts = <String, int>{};

    var resolutionHoursTotal = 0.0;
    var resolutionSamples = 0;
    var ratingTotal = 0.0;
    var ratingSamples = 0;

    for (final doc in docs) {
      final data = doc.data();
      final status = _normalizedStatus(data['status']);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      if (status == 'resolved') resolved++;
      if (status == 'rejected') rejected++;
      if (status == 'in-progress') inProgress++;
      if (status == 'reported') reported++;
      if (status == 'reopened') reopened++;

      final duplicateCount = _toInt(data['duplicateReportCount'], fallback: 1);
      duplicateTotal += duplicateCount;

      final isOpen = status != 'resolved' && status != 'rejected';
      if (isOpen && duplicateCount >= 5) {
        unresolvedHighPriority++;
      }

      final category = _safeKey(data['categoryId'], fallback: 'unknown');
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      final area = _safeKey(
        data['locationName'] ?? data['address'],
        fallback: 'unspecified',
      );
      areaCounts[area] = (areaCounts[area] ?? 0) + 1;

      final createdAt = data['createdAt'];
      final resolvedAt = data['resolvedAt'];
      if (status == 'resolved' && createdAt is Timestamp && resolvedAt is Timestamp) {
        final hours = resolvedAt.toDate().difference(createdAt.toDate()).inMinutes / 60.0;
        if (hours >= 0) {
          resolutionHoursTotal += hours;
          resolutionSamples++;
        }
      }

      final rating = data['citizenOverallRating'];
      if (rating is num) {
        ratingTotal += rating.toDouble();
        ratingSamples++;
      }
    }

    final total = docs.length;
    final open = total - resolved - rejected;

    return AnalyticsSummary(
      total: total,
      open: open < 0 ? 0 : open,
      resolved: resolved,
      rejected: rejected,
      inProgress: inProgress,
      reported: reported,
      reopened: reopened,
      unresolvedHighPriority: unresolvedHighPriority,
      averageResolutionHours:
          resolutionSamples == 0 ? 0 : resolutionHoursTotal / resolutionSamples,
      averageDuplicateCount: total == 0 ? 0 : duplicateTotal / total,
      citizenRatingAverage: ratingSamples == 0 ? 0 : ratingTotal / ratingSamples,
      statusCounts: statusCounts,
      categoryCounts: categoryCounts,
      areaCounts: areaCounts,
    );
  }

  static List<MapEntry<String, int>> _topEntries(
    Map<String, int> source, {
    required int limit,
  }) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  static String _normalizedStatus(dynamic value) {
    final raw = (value ?? 'reported').toString().trim().toLowerCase();
    if (raw.isEmpty) return 'reported';
    return raw;
  }

  static String _safeKey(dynamic value, {required String fallback}) {
    final v = (value ?? '').toString().trim();
    if (v.isEmpty) return fallback;
    return v;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}