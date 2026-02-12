// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../controllers/issue_category_controller.dart';
// import '../widgets/media_player/audio_player_widget.dart';
// import '../widgets/media_player/video_player_widget.dart';
// import 'reassignment_timeline_page.dart';
//
// class IssueDetailAdminPage extends StatelessWidget {
//   final String issueId;
//   final String adminDept;
//   final String adminEmail;
//
//   const IssueDetailAdminPage({
//     super.key,
//     required this.issueId,
//     required this.adminDept,
//     required this.adminEmail,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final categoryController = Get.isRegistered<IssueCategoryController>()
//         ? Get.find<IssueCategoryController>()
//         : Get.put(IssueCategoryController());
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Issue Details'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history),
//             onPressed: () {
//               Get.to(() => ReassignmentTimelinePage(issueId: issueId));
//             },
//             tooltip: 'Reassignment History',
//           ),
//         ],
//       ),
//       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: FirebaseFirestore.instance
//             .collection('issues')
//             .doc(issueId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final doc = snapshot.data;
//           if (doc == null || !doc.exists || doc.data() == null) {
//             return const Center(child: Text('Issue not found'));
//           }
//
//           final data = doc.data()!;
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Column(
//               children: [
//                 _buildHeader(data),
//                 _buildLocationSection(data),
//                 _buildMediaSection(data),
//                 _buildAddUpdateButton(context),
//                 _buildTimeline(data),
//                 _buildActions(context, data, categoryController),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHeader(Map<String, dynamic> data) {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     data['categoryId']?.toUpperCase() ?? 'UNKNOWN',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 _buildStatusChip(data['status']),
//               ],
//             ),
//             const Divider(height: 24),
//             Text(
//               data['description'] ?? 'No description',
//               style: const TextStyle(fontSize: 15),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow('Reporter', data['reporterEmail'] ?? 'Unknown'),
//             _buildInfoRow(
//               'Department',
//               data['assignedToDept']?.toUpperCase() ?? 'N/A',
//             ),
//             _buildInfoRow('Reported', _formatTimestamp(data['createdAt'])),
//             if (data['lastReassignedAt'] != null)
//               _buildInfoRow(
//                 'Last Reassigned',
//                 _formatTimestamp(data['lastReassignedAt']),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(String? status) {
//     Color chipColor;
//     switch (status?.toLowerCase()) {
//       case 'resolved':
//         chipColor = Colors.green;
//         break;
//       case 'in_progress':
//       case 'in-progress':
//         chipColor = Colors.orange;
//         break;
//       case 'assigned':
//         chipColor = Colors.blue;
//         break;
//       case 'rejected':
//         chipColor = Colors.red;
//         break;
//       default:
//         chipColor = Colors.grey;
//     }
//
//     return Chip(
//       label: Text(
//         status?.toUpperCase() ?? 'UNKNOWN',
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//       backgroundColor: chipColor,
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationSection(Map<String, dynamic> data) {
//     final location = data['location'];
//     if (location is! Map<String, dynamic>) return const SizedBox.shrink();
//
//     final lat = (location['latitude'] as num?)?.toDouble();
//     final lng = (location['longitude'] as num?)?.toDouble();
//     if (lat == null || lng == null) return const SizedBox.shrink();
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Location',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Text('Latitude: ${lat.toStringAsFixed(6)}'),
//             Text('Longitude: ${lng.toStringAsFixed(6)}'),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 icon: const Icon(Icons.map),
//                 label: const Text('Open in Maps'),
//                 onPressed: () => _openMap(lat, lng),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMediaSection(Map<String, dynamic> data) {
//     final imageUrl = data['imageUrl'] as String?;
//     final imageUrls = (data['imageUrls'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList();
//     final videoUrl = data['videoUrl'] as String?;
//     final audioUrl = data['audioUrl'] as String?;
//
//     final effectiveImages = <String>[];
//     if (imageUrls.isNotEmpty) {
//       effectiveImages.addAll(imageUrls);
//     } else if (imageUrl != null && imageUrl.isNotEmpty) {
//       effectiveImages.add(imageUrl);
//     }
//
//     final hasMedia =
//         effectiveImages.isNotEmpty || audioUrl != null || videoUrl != null;
//     if (!hasMedia) return const SizedBox.shrink();
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Evidence',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             if (effectiveImages.isNotEmpty) ...[
//               const Text(
//                 'Photos',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: 220,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: effectiveImages.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 12),
//                   itemBuilder: (context, index) {
//                     final url = effectiveImages[index];
//                     return ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: AspectRatio(
//                         aspectRatio: 1,
//                         child: Image.network(
//                           url,
//                           fit: BoxFit.cover,
//                           loadingBuilder: (context, child, progress) {
//                             if (progress == null) return child;
//                             return const SizedBox(
//                               width: 220,
//                               child: Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                             );
//                           },
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               width: 220,
//                               color: Colors.grey[300],
//                               child: const Icon(
//                                 Icons.broken_image,
//                                 color: Colors.grey,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             if (audioUrl != null) ...[
//               const Text(
//                 'Audio',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               AudioPlayerWidget(audioUrl: audioUrl),
//               const SizedBox(height: 12),
//             ],
//             if (videoUrl != null) ...[
//               const Text(
//                 'Video',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               VideoPlayerWidget(videoUrl: videoUrl),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddUpdateButton(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           icon: const Icon(Icons.add),
//           label: const Text('Add Status Update'),
//           onPressed: () => _showAddUpdateDialog(context),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimeline(Map<String, dynamic> data) {
//     final timeline = data['timeline'] as List<dynamic>? ?? [];
//
//     if (timeline.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Status Timeline',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             ...timeline
//                 .whereType<Map<String, dynamic>>()
//                 .toList()
//                 .reversed
//                 .map(_buildTimelineItem),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimelineItem(Map<String, dynamic> item) {
//     final statusColor = _getStatusColor(item['status']?.toString());
//     final timestamp = item['timestamp'] as Timestamp?;
//     final dateStr = timestamp != null
//         ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
//         : 'N/A';
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             margin: const EdgeInsets.only(top: 4),
//             decoration: BoxDecoration(
//               color: statusColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item['status']?.toString().toUpperCase() ?? 'UNKNOWN',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: statusColor,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(item['message']?.toString() ?? ''),
//                 const SizedBox(height: 4),
//                 Text(
//                   'By: ${item['updatedByEmail'] ?? 'Unknown'}',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 Text(
//                   dateStr,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActions(
//       BuildContext context,
//       Map<String, dynamic> data,
//       IssueCategoryController categoryController,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: SizedBox(
//         width: double.infinity,
//         child: OutlinedButton.icon(
//           icon: const Icon(Icons.swap_horiz),
//           label: const Text('Reassign Issue'),
//           onPressed: () {
//             _showReassignDialog(
//               context,
//               data['assignedToDept']?.toString() ?? 'unassigned',
//               categoryController,
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'resolved':
//         return Colors.green;
//       case 'in_progress':
//       case 'in-progress':
//         return Colors.orange;
//       case 'assigned':
//         return Colors.blue;
//       case 'reassigned':
//         return Colors.purple;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
//     }
//     return 'N/A';
//   }
//
//   Future<void> _openMap(double lat, double lng) async {
//     final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
//
//   void _showAddUpdateDialog(BuildContext context) {
//     String selectedStatus = 'in_progress';
//     final messageCtrl = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Add Status Update'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButtonFormField<String>(
//               value: selectedStatus,
//               decoration: const InputDecoration(labelText: 'Status'),
//               items: const [
//                 DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
//                 DropdownMenuItem(
//                   value: 'in_progress',
//                   child: Text('In Progress'),
//                 ),
//                 DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
//                 DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
//               ],
//               onChanged: (v) => selectedStatus = v ?? 'in_progress',
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: messageCtrl,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 labelText: 'Message',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             child: const Text('Add'),
//             onPressed: () async {
//               if (messageCtrl.text.trim().isEmpty) {
//                 Get.snackbar('Error', 'Message is required');
//                 return;
//               }
//
//               await _addStatusUpdate(selectedStatus, messageCtrl.text.trim());
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _addStatusUpdate(String status, String message) async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       Get.snackbar('Error', 'User not logged in');
//       return;
//     }
//
//     await FirebaseFirestore.instance.collection('issues').doc(issueId).update({
//       'status': status,
//       'statusUpdatedAt': FieldValue.serverTimestamp(),
//       'statusUpdatedBy': uid,
//       'timeline': FieldValue.arrayUnion([
//         {
//           'status': status,
//           'message': message,
//           'updatedBy': uid,
//           'updatedByEmail': adminEmail,
//           'timestamp': Timestamp.now(),
//         }
//       ]),
//     });
//
//     Get.snackbar('Success', 'Status updated successfully');
//   }
//
//   void _showReassignDialog(
//       BuildContext context,
//       String fromDept,
//       IssueCategoryController categoryController,
//       ) {
//     String selectedDept = fromDept;
//     final reasonCtrl = TextEditingController();
//
//     if (categoryController.categories.isEmpty) {
//       categoryController.fetchCategories();
//     }
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Reassign Issue'),
//         content: Obx(() {
//           final categories = categoryController.categories;
//
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 value: categories.any((c) => c.id == selectedDept)
//                     ? selectedDept
//                     : (categories.isNotEmpty ? categories.first.id : null),
//                 decoration: const InputDecoration(labelText: 'New Department'),
//                 items: categories
//                     .map(
//                       (cat) => DropdownMenuItem(
//                     value: cat.id,
//                     child: Text(cat.name),
//                   ),
//                 )
//                     .toList(),
//                 onChanged: (v) => selectedDept = v ?? selectedDept,
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: reasonCtrl,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: 'Reason',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           );
//         }),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             child: const Text('Reassign'),
//             onPressed: () async {
//               if (selectedDept == fromDept) {
//                 Get.snackbar('Error', 'Select a different department');
//                 return;
//               }
//               if (reasonCtrl.text.trim().isEmpty) {
//                 Get.snackbar('Error', 'Reason is required');
//                 return;
//               }
//
//               await _reassignIssue(fromDept, selectedDept, reasonCtrl.text.trim());
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _reassignIssue(String fromDept, String toDept, String reason) async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       Get.snackbar('Error', 'User not logged in');
//       return;
//     }
//
//     final issueRef = FirebaseFirestore.instance.collection('issues').doc(issueId);
//
//     await FirebaseFirestore.instance.runTransaction((txn) async {
//       txn.update(issueRef, {
//         'assignedToDept': toDept,
//         'status': 'assigned',
//         'statusUpdatedAt': FieldValue.serverTimestamp(),
//         'statusUpdatedBy': uid,
//         'lastReassignedAt': FieldValue.serverTimestamp(),
//         'lastReassignedBy': uid,
//         'timeline': FieldValue.arrayUnion([
//           {
//             'status': 'assigned',
//             'message': 'Issue reassigned from $fromDept to $toDept. Reason: $reason',
//             'updatedBy': uid,
//             'updatedByEmail': adminEmail,
//             'timestamp': Timestamp.now(),
//           }
//         ]),
//       });
//
//       txn.set(issueRef.collection('reassignments').doc(), {
//         'fromDept': fromDept,
//         'toDept': toDept,
//         'reason': reason,
//         'reassignedByUid': uid,
//         'reassignedByEmail': adminEmail,
//         'reassignedAt': FieldValue.serverTimestamp(),
//       });
//     });
//
//     Get.snackbar('Success', 'Issue reassigned to ${toDept.toUpperCase()}');
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/issue_category_controller.dart';
import '../widgets/admin_issue_detail_section.dart';
import 'reassignment_timeline_page.dart';

class IssueDetailAdminPage extends StatelessWidget {
  final String issueId;
  final String adminDept;
  final String adminEmail;

  const IssueDetailAdminPage({
    super.key,
    required this.issueId,
    required this.adminDept,
    required this.adminEmail,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.isRegistered<IssueCategoryController>()
        ? Get.find<IssueCategoryController>()
        : Get.put(IssueCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => ReassignmentTimelinePage(issueId: issueId));
            },
            tooltip: 'Reassignment History',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const Center(child: Text('Issue not found'));
          }

          final data = doc.data()!;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                AdminIssueHeaderSection(data: data),
                AdminIssueLocationSection(
                  data: data,
                  onOpenMap: _openMap,
                ),
                AdminIssueMediaSection(data: data),
                _buildAddUpdateButton(context),
                AdminIssueTimelineSection(data: data),
                _buildActions(context, data, categoryController),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddUpdateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Status Update'),
          onPressed: () => _showAddUpdateDialog(context),
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context,
      Map<String, dynamic> data,
      IssueCategoryController categoryController,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Reassign Issue'),
          onPressed: () {
            _showReassignDialog(
              context,
              data['assignedToDept']?.toString() ?? 'unassigned',
              categoryController,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddUpdateDialog(BuildContext context) {
    String selectedStatus = 'in_progress';
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Status Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (v) => selectedStatus = v ?? 'in_progress',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () async {
              if (messageCtrl.text.trim().isEmpty) {
                Get.snackbar('Error', 'Message is required');
                return;
              }

              await _addStatusUpdate(selectedStatus, messageCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addStatusUpdate(String status, String message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    await FirebaseFirestore.instance.collection('issues').doc(issueId).update({
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedBy': uid,
      'timeline': FieldValue.arrayUnion([
        {
          'status': status,
          'message': message,
          'updatedBy': uid,
          'updatedByEmail': adminEmail,
          'timestamp': Timestamp.now(),
        }
      ]),
    });

    Get.snackbar('Success', 'Status updated successfully');
  }

  void _showReassignDialog(
      BuildContext context,
      String fromDept,
      IssueCategoryController categoryController,
      ) {
    String selectedDept = fromDept;
    final reasonCtrl = TextEditingController();

    if (categoryController.categories.isEmpty) {
      categoryController.fetchCategories();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reassign Issue'),
        content: Obx(() {
          final categories = categoryController.categories;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categories.any((c) => c.id == selectedDept)
                    ? selectedDept
                    : (categories.isNotEmpty ? categories.first.id : null),
                decoration: const InputDecoration(labelText: 'New Department'),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                    .toList(),
                onChanged: (v) => selectedDept = v ?? selectedDept,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Reassign'),
            onPressed: () async {
              if (selectedDept == fromDept) {
                Get.snackbar('Error', 'Select a different department');
                return;
              }
              if (reasonCtrl.text.trim().isEmpty) {
                Get.snackbar('Error', 'Reason is required');
                return;
              }

              await _reassignIssue(fromDept, selectedDept, reasonCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reassignIssue(String fromDept, String toDept, String reason) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    final issueRef = FirebaseFirestore.instance.collection('issues').doc(issueId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.update(issueRef, {
        'assignedToDept': toDept,
        'status': 'assigned',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': uid,
        'lastReassignedAt': FieldValue.serverTimestamp(),
        'lastReassignedBy': uid,
        'timeline': FieldValue.arrayUnion([
          {
            'status': 'assigned',
            'message': 'Issue reassigned from $fromDept to $toDept. Reason: $reason',
            'updatedBy': uid,
            'updatedByEmail': adminEmail,
            'timestamp': Timestamp.now(),
          }
        ]),
      });

      txn.set(issueRef.collection('reassignments').doc(), {
        'fromDept': fromDept,
        'toDept': toDept,
        'reason': reason,
        'reassignedByUid': uid,
        'reassignedByEmail': adminEmail,
        'reassignedAt': FieldValue.serverTimestamp(),
      });
    });

    Get.snackbar('Success', 'Issue reassigned to ${toDept.toUpperCase()}');
  }
}
