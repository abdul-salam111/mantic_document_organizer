import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

void run(HookContext context) async {
  final progress = context.logger.progress('Scanning assets');
  
  try {
    // Get the current directory
    final currentDir = Directory.current;
    final assetsDir = Directory(path.join(currentDir.path, 'assets'));
    
    if (!assetsDir.existsSync()) {
      progress.fail('Assets folder not found');
      throw Exception('Please create an assets folder in your project root');
    }
    
    // Scan images
    final imagesDir = Directory(path.join(assetsDir.path, 'images'));
    final images = <Map<String, String>>[];
    
    if (imagesDir.existsSync()) {
      final imageFiles = imagesDir
          .listSync()
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
      
      for (var file in imageFiles) {
        final fileName = path.basenameWithoutExtension(file.path);
        final constName = _toConstName(fileName);
        final assetPath = 'assets/images/${path.basename(file.path)}';
        
        images.add({
          'const_name': constName,
          'asset_path': assetPath,
          'original_name': fileName,
        });
      }
    }
    
    // Scan icons
    final iconsDir = Directory(path.join(assetsDir.path, 'icons'));
    final icons = <Map<String, String>>[];
    
    if (iconsDir.existsSync()) {
      final iconFiles = iconsDir
          .listSync()
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
      
      for (var file in iconFiles) {
        final fileName = path.basenameWithoutExtension(file.path);
        final constName = _toConstName(fileName);
        final assetPath = 'assets/icons/${path.basename(file.path)}';
        
        icons.add({
          'const_name': constName,
          'asset_path': assetPath,
          'original_name': fileName,
        });
      }
    }
    
    // Set variables for templates
    context.vars = {
      ...context.vars,
      'images': images,
      'icons': icons,
      'images_count': images.length,
      'icons_count': icons.length,
    };
    
    progress.complete('Found ${images.length} images and ${icons.length} icons');
    
  } catch (e) {
    progress.fail('Error scanning assets: $e');
    rethrow;
  }
}

bool _isImageFile(String filePath) {
  final ext = path.extension(filePath).toLowerCase();
  return ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'].contains(ext);
}

String _toConstName(String fileName) {
  // Convert file name to camelCase constant name
  // e.g., "app_logo" -> "appLogo", "my-icon" -> "myIcon"
  
  final parts = fileName
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
      .split('_')
      .where((part) => part.isNotEmpty)
      .toList();
  
  if (parts.isEmpty) return 'asset';
  
  final result = parts.first.toLowerCase() +
      parts.skip(1).map((part) {
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      }).join();
  
  return result;
}