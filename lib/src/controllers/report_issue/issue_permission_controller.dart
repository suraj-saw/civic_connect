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
      Get.snackbar(
        "Location Permission Required",
        "Location permission is needed to report issues",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Camera (for photo AND video)
  Future<bool> requestCamera() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();

    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      _showSettingsDialog("camera");
      return false;
    } else {
      Get.snackbar(
        "Permission Denied",
        "Camera permission is required",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Gallery (for photos AND videos)
  Future<bool> requestGallery() async {
    if (kIsWeb) return true;

    // Try photos permission first
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted) return true;

    final photosResult = await Permission.photos.request();

    if (photosResult.isGranted) {
      return true;
    } else if (photosResult.isPermanentlyDenied) {
      _showSettingsDialog("gallery");
      return false;
    } else {
      Get.snackbar(
        "Permission Denied",
        "Gallery permission is required",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Microphone
  Future<bool> requestMic() async {
    if (kIsWeb) return true;

    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();

    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      _showSettingsDialog("microphone");
      return false;
    } else {
      Get.snackbar(
        "Permission Denied",
        "Microphone permission is required",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  void _showSettingsDialog(String permissionName) {
    Get.defaultDialog(
      title: "Permission Required",
      middleText: "Please enable $permissionName permission in settings",
      textConfirm: "Open Settings",
      textCancel: "Cancel",
      onConfirm: () {
        openAppSettings();
        Get.back();
      },
    );
  }
}