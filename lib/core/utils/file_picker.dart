// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';

// class FilePickerController extends GetxController {
//   final ImagePicker _imagePicker = ImagePicker();

//   File? selectedFile;

//   /// Public method
//   Future<File?> pickFile({required bool isImage}) async {
//     if (isImage) {
//       return await _showImageSourceSheet();
//     } else {
//       return await _pickOtherFiles();
//     }
//   }

//   /// Image → Camera / Gallery
//   Future<File?> _showImageSourceSheet() async {
//     return await Get.bottomSheet<File?>(
//       SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () async {
//                 final file = await _pickImage(ImageSource.camera);
//                 Get.back(result: file);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () async {
//                 final file = await _pickImage(ImageSource.gallery);
//                 Get.back(result: file);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<File?> _pickImage(ImageSource source) async {
//     final XFile? image = await _imagePicker.pickImage(
//       source: source,
//       imageQuality: 80,
//     );

//     if (image == null) return null;

//     selectedFile = File(image.path);
//     update();
//     return selectedFile;
//   }

//   /// Non-image files → File Explorer
//   Future<File?> _pickOtherFiles() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: false);

//     if (result == null || result.files.single.path == null) return null;

//     selectedFile = File(result.files.single.path!);
//     update();
//     return selectedFile;
//   }
// }
