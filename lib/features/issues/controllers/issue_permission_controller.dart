import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class IssuePermissionController extends GetxController {
  final RxBool isCheckingLocationPermission = true.obs;
  final Rx<PermissionStatus> locationPermissionStatus =
      PermissionStatus.denied.obs;

  @override
  void onInit() {
    super.onInit();
    ensureLocationPermissionOnLoad();
  }

  /// Location check triggered when report page opens.
  Future<void> ensureLocationPermissionOnLoad() async {
    if (kIsWeb) {
      locationPermissionStatus.value = PermissionStatus.granted;
      isCheckingLocationPermission.value = false;
      return;
    }

    isCheckingLocationPermission.value = true;

    try {
      var status = await Permission.locationWhenInUse.status;

      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
      }

      locationPermissionStatus.value = status;

      if (!status.isGranted) {
        _showLocationPermissionMessage(status);
      }
    } finally {
      isCheckingLocationPermission.value = false;
    }
  }

  bool get hasLocationPermission =>
      kIsWeb || locationPermissionStatus.value.isGranted;

  /// Camera (for photo and video capture)
  Future<bool> requestCamera() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();

    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied) {
      _showSettingsDialog('camera');
    } else {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required to capture photo/video.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return false;
  }

  /// Microphone for voice note recording
  Future<bool> requestMic() async {
    if (kIsWeb) return true;

    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();

    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied) {
      _showSettingsDialog('microphone');
    } else {
      Get.snackbar(
        'Permission Denied',
        'Microphone permission is required to record audio.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return false;
  }

  void _showLocationPermissionMessage(PermissionStatus status) {
    if (status.isPermanentlyDenied) {
      _showSettingsDialog('location');
      return;
    }

    Get.snackbar(
      'Location Permission Required',
      'Please enable location permission to report an issue with location context.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSettingsDialog(String permissionName) {
    Get.defaultDialog(
      title: 'Permission Required',
      middleText: 'Please enable $permissionName permission in app settings.',
      textConfirm: 'Open Settings',
      textCancel: 'Cancel',
      onConfirm: () {
        openAppSettings();
        Get.back();
      },
    );
  }
}
