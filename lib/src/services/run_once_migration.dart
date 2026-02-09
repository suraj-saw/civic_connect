// // run_once_migration.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'media_upload_service.dart';
//
// Future<void> migrateOldUrls() async {
//   final firestore = FirebaseFirestore.instance;
//
//   // Get current server URL
//   final serverInfo = await MediaUploadService.getServerInfo();
//   if (serverInfo == null) {
//     print('❌ Server not available');
//     return;
//   }
//
//   final currentBaseUrl = serverInfo['baseUrl'];
//   print('🔄 Migrating URLs to: $currentBaseUrl');
//
//   // Get all issues
//   final issuesSnapshot = await firestore.collection('issues').get();
//
//   int updated = 0;
//
//   for (final doc in issuesSnapshot.docs) {
//     final data = doc.data();
//     bool needsUpdate = false;
//     final updates = <String, dynamic>{};
//
//     // Update imageUrl
//     if (data['imageUrl'] != null) {
//       final oldUrl = data['imageUrl'] as String;
//       if (!oldUrl.startsWith(currentBaseUrl)) {
//         // Extract filename
//         final filename = oldUrl.split('/').last;
//         final newUrl = '$currentBaseUrl/uploads/images/$filename';
//         updates['imageUrl'] = newUrl;
//         needsUpdate = true;
//       }
//     }
//
//     // Update audioUrl
//     if (data['audioUrl'] != null) {
//       final oldUrl = data['audioUrl'] as String;
//       if (!oldUrl.startsWith(currentBaseUrl)) {
//         final filename = oldUrl.split('/').last;
//         final newUrl = '$currentBaseUrl/uploads/audio/$filename';
//         updates['audioUrl'] = newUrl;
//         needsUpdate = true;
//       }
//     }
//
//     if (needsUpdate) {
//       await doc.reference.update(updates);
//       updated++;
//       print('✅ Updated: ${doc.id}');
//     }
//   }
//
//   print('\n🎉 Migration complete! Updated $updated issues');
// }