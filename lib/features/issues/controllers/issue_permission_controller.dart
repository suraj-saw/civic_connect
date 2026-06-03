import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/widgets/app_snackbar.dart';

class IssuePermissionController extends GetxController {
  final isCheckingLocationPermission = true.obs;
  final locationPermissionStatus = PermissionStatus.denied.obs;

  @override
  void onInit() { super.onInit(); ensureLocationPermissionOnLoad(); }

  Future<void> ensureLocationPermissionOnLoad() async {
    if (kIsWeb) { locationPermissionStatus.value = PermissionStatus.granted; isCheckingLocationPermission.value = false; return; }
    isCheckingLocationPermission.value = true;
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) status = await Permission.locationWhenInUse.request();
      locationPermissionStatus.value = status;
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _showSettingsDialog('location');
        } else {
          AppSnackbar.show('Location Required', 'Please enable location to report an issue.', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } finally { isCheckingLocationPermission.value = false; }
  }

  bool get hasLocationPermission => kIsWeb || locationPermissionStatus.value.isGranted;

  Future<bool> requestCamera() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied) {
      _showSettingsDialog('camera');
    } else {
      AppSnackbar.show('Permission Denied', 'Camera permission is required.', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> requestMic() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied) {
      _showSettingsDialog('microphone');
    } else {
      AppSnackbar.show('Permission Denied', 'Microphone permission is required.', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  void _showSettingsDialog(String name) {
    Get.defaultDialog(
      title: 'Permission Required',
      middleText: 'Please enable $name permission in app settings.',
      textConfirm: 'Open Settings',
      textCancel: 'Cancel',
      onConfirm: () { Get.back(); openAppSettings(); },
    );
  }
}
