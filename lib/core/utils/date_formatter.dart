import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTimestamp(dynamic ts) {
    if (ts is Timestamp) return DateFormat('MMM dd, yyyy • hh:mm a').format(ts.toDate());
    return 'N/A';
  }
}
