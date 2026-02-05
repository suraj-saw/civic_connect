import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class IssuePermissionController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
  }

  /// Location (on page load)
  Future<void> _checkLocationPermission() async {
    if (kIsWeb) return;

    final status = await Permission.location.status;
    if (status.isGranted) return;

    final result = await Permission.location.request();
    if (!result.isGranted) {
      _denyAndExit("location");
    }
  }

  /// Camera
  Future<bool> requestCamera() async {
    return _request(Permission.camera, "camera");
  }

  /// Gallery
  Future<bool> requestGallery() async {
    return _request(Permission.photos, "gallery");
  }

  /// Microphone
  Future<bool> requestMic() async {
    return _request(Permission.microphone, "microphone");
  }

  /// Common handler
  Future<bool> _request(Permission permission, String name) async {
    if (kIsWeb) return true;

    final status = await permission.status;
    if (status.isGranted) return true;

    final result = await permission.request();
    if (result.isGranted) return true;

    _denyAndExit(name);
    return false;
  }

  void _denyAndExit(String permissionName) {
    Get.snackbar(
      "Permission Required",
      "Cannot report issue without enabling $permissionName permission",
      snackPosition: SnackPosition.BOTTOM,
    );
    Get.back();
  }
}
