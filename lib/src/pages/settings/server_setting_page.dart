// // lib/src/pages/settings/server_settings_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../services/media_upload_service.dart';
//
// class ServerSettingsPage extends StatefulWidget {
//   const ServerSettingsPage({super.key});
//
//   @override
//   State<ServerSettingsPage> createState() => _ServerSettingsPageState();
// }
//
// class _ServerSettingsPageState extends State<ServerSettingsPage> {
//   final _controller = TextEditingController();
//   String? _serverStatus;
//   Map<String, dynamic>? _serverInfo;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkServer();
//   }
//
//   Future<void> _checkServer() async {
//     setState(() => _serverStatus = 'Checking...');
//
//     final info = await MediaUploadService.getServerInfo();
//
//     setState(() {
//       _serverInfo = info;
//       if (info != null) {
//         _serverStatus = '✅ Connected';
//         _controller.text = info['baseUrl'];
//       } else {
//         _serverStatus = '❌ Not connected';
//       }
//     });
//   }
//
//   Future<void> _setCustomUrl() async {
//     final url = _controller.text.trim();
//     if (url.isEmpty) return;
//
//     MediaUploadService.setServerUrl(url);
//     await _checkServer();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Server Settings')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Media Server Configuration',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Configure the server for uploading images and audio',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             const SizedBox(height: 24),
//
//             // Status Card
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Server Status',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Text(_serverStatus ?? 'Unknown'),
//                       ],
//                     ),
//                     if (_serverInfo != null) ...[
//                       const SizedBox(height: 12),
//                       const Divider(),
//                       const SizedBox(height: 12),
//                       _buildInfoRow('IP Address', _serverInfo!['ip']),
//                       _buildInfoRow('Port', _serverInfo!['port'].toString()),
//                       _buildInfoRow('Base URL', _serverInfo!['baseUrl']),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Manual URL Input
//             TextField(
//               controller: _controller,
//               decoration: const InputDecoration(
//                 labelText: 'Server URL',
//                 hintText: 'http://10.10.51.143:3000',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Auto Discover'),
//                     onPressed: _checkServer,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.save),
//                     label: const Text('Set Manual'),
//                     onPressed: _setCustomUrl,
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 24),
//
//             // Instructions
//             Card(
//               color: Colors.blue.shade50,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.info_outline, color: Colors.blue.shade700),
//                         const SizedBox(width: 8),
//                         Text(
//                           'How to use',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     const Text('1. Start the Node server on your computer'),
//                     const SizedBox(height: 4),
//                     const Text('2. Make sure both devices are on same WiFi'),
//                     const SizedBox(height: 4),
//                     const Text('3. Click "Auto Discover" to find server'),
//                     const SizedBox(height: 4),
//                     const Text('4. Or enter URL manually and click "Set Manual"'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }