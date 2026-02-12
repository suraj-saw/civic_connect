// import 'package:flutter/material.dart';
// import 'package:http/http.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:civic_connect/features/issues/bloc/issue_bloc.dart';
//
// class IssueForm extends StatefulWidget {
//   const IssueForm({Key? key}) : super(key: key);
//
//   @override
//   State<IssueForm> createState() => _IssueFormState();
// }
//
// class _IssueFormState extends State<IssueForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _locationController = TextEditingController();
//
//   String _selectedCategory = 'Infrastructure';
//   String _selectedPriority = 'Medium';
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//
//   final List<String> _categories = [
//     'Infrastructure',
//     'Public Safety',
//     'Sanitation',
//     'Transportation',
//     'Environment',
//     'Health',
//     'Education',
//     'Other',
//   ];
//
//   final List<String> _priorities = [
//     'Low',
//     'Medium',
//     'High',
//     'Critical',
//   ];
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//
//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error picking image: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _takePicture() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//
//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error taking picture: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   void _showImageSourceOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Take a Photo'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _takePicture();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       final issue = Issue(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         title: _titleController.text.trim(),
//         description: _descriptionController.text.trim(),
//         category: _selectedCategory,
//         location: _locationController.text.trim(),
//         priority: _selectedPriority,
//         status: 'Pending',
//         createdAt: DateTime.now(),
//         citizenId: 'current_user_id', // Replace with actual user ID from auth
//         imagePath: _selectedImage?.path,
//       );
//
//       context.read<IssueBloc>().add(SubmitIssueEvent(issue));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextFormField(
//             controller: _titleController,
//             decoration: const InputDecoration(
//               labelText: 'Issue Title',
//               hintText: 'Brief description of the issue',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.title),
//             ),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) {
//                 return 'Please enter a title';
//               }
//               if (value.trim().length < 5) {
//                 return 'Title must be at least 5 characters';
//               }
//               return null;
//             },
//             maxLength: 100,
//           ),
//           const SizedBox(height: 16),
//
//           DropdownButtonFormField<String>(
//             value: _selectedCategory,
//             decoration: const InputDecoration(
//               labelText: 'Category',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.category),
//             ),
//             items: _categories.map((category) {
//               return DropdownMenuItem(
//                 value: category,
//                 child: Text(category),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _selectedCategory = value!;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//
//           TextFormField(
//             controller: _descriptionController,
//             decoration: const InputDecoration(
//               labelText: 'Description',
//               hintText: 'Provide detailed information about the issue',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.description),
//               alignLabelWithHint: true,
//             ),
//             maxLines: 5,
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) {
//                 return 'Please enter a description';
//               }
//               if (value.trim().length < 20) {
//                 return 'Description must be at least 20 characters';
//               }
//               return null;
//             },
//             maxLength: 500,
//           ),
//           const SizedBox(height: 16),
//
//           TextFormField(
//             controller: _locationController,
//             decoration: const InputDecoration(
//               labelText: 'Location',
//               hintText: 'Where is this issue located?',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.location_on),
//             ),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) {
//                 return 'Please enter a location';
//               }
//               return null;
//             },
//             maxLength: 150,
//           ),
//           const SizedBox(height: 16),
//
//           DropdownButtonFormField<String>(
//             value: _selectedPriority,
//             decoration: const InputDecoration(
//               labelText: 'Priority',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.priority_high),
//             ),
//             items: _priorities.map((priority) {
//               return DropdownMenuItem(
//                 value: priority,
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.flag,
//                       color: _getPriorityColor(priority),
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(priority),
//                   ],
//                 ),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _selectedPriority = value!;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//
//           if (_selectedImage != null)
//             Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(
//                       _selectedImage!,
//                       width: double.infinity,
//                       height: 200,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: IconButton(
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.black54,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _selectedImage = null;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           const SizedBox(height: 16),
//
//           OutlinedButton.icon(
//             onPressed: _showImageSourceOptions,
//             icon: const Icon(Icons.add_photo_alternate),
//             label: Text(_selectedImage == null ? 'Add Photo' : 'Change Photo'),
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//             ),
//           ),
//           const SizedBox(height: 24),
//
//           ElevatedButton(
//             onPressed: _submitForm,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//             ),
//             child: const Text(
//               'Submit Report',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getPriorityColor(String priority) {
//     switch (priority) {
//       case 'Low':
//         return Colors.green;
//       case 'Medium':
//         return Colors.orange;
//       case 'High':
//         return Colors.red;
//       case 'Critical':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }
// }