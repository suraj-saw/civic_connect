import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class HomeAdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString adminDept = ''.obs;
  final RxString adminEmail = ''.obs;
  final RxString adminName = ''.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      isLoading.value = true;

      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        adminDept.value = data['departmentId'] ?? '';
        adminEmail.value = data['email'] ?? '';
        adminName.value = data['name'] ?? '';
      }
    } catch (e) {
      print('Error loading admin info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out');
    }
  }
}
