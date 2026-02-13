import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_permission.dart';
import '../../data/app_data.dart';
import 'package:path/path.dart' as p; // Import path package

Future<String?> saveTextFile(
  BuildContext context,
  String content, {
  bool showSnackBar = true,
  String? directoryPath, // New optional parameter
  String? fileName, // New optional parameter
}) async {
  try {
    String finalDirectoryPath;
    String finalFileName;

    if (directoryPath != null && fileName != null) {
      finalDirectoryPath = directoryPath;
      finalFileName = fileName;
    } else {
      // Use the user-specified documents directory.
      final directory = Directory('/storage/emulated/0/Documents');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      finalDirectoryPath = directory.path;
      finalFileName = AppDataManager().customerName?.isNotEmpty == true
          ? '${AppDataManager().customerName}.txt'
          : 'Configuration.txt';
    }

    final fullFilePath = p.join(finalDirectoryPath, finalFileName);
    final file = File(fullFilePath);

    // Ensure the directory exists
    await file.parent.create(recursive: true);

    await file.writeAsString(content);

    // 4. Show Success Message
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success! File saved to: $fullFilePath"),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    return fullFilePath;
  } catch (e) {
    // 5. Catch and Show Any Errors
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving file: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
    return null;
  }
}
