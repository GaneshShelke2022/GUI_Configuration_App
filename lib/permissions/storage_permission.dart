import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus status;
    if (sdkInt >= 30) { // Android 11 (API 30) or higher
      status = await Permission.manageExternalStorage.request();
    } else { // Android 10 (API 29) or lower
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    } else {
      return false;
    }
  } else {
    // For non-Android platforms
    return true;
  }
}
