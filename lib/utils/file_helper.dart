import 'dart:io';
import 'package:path/path.dart' as p;

class FileHelper {
  static Future<File> createHexFile(String txtPath) async {
    // Use the user-specified documents directory.
    final directory = Directory('/storage/emulated/0/Documents');

    // Create the directory if it doesn't exist. This is crucial.
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final filename = p.basenameWithoutExtension(txtPath);
    final hexPath = p.join(directory.path, '$filename.hex');
    final file = File(hexPath);
    
    return file;
  }
}