import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MyIssuesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs;
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> myIssues =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyIssues();
  }

  Future<void> fetchMyIssues() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not logged in");
      }

      final snapshot = await _firestore
          .collection('issues')
          .where('reporterEmail', isEqualTo: user.email)
          .orderBy('createdAt', descending: true)
          .get();

      myIssues.assignAll(snapshot.docs);
    } catch (e) {
      // VERY IMPORTANT: print real error
      print("MY ISSUES FETCH ERROR: $e");

      Get.snackbar(
        "Error",
        "Failed to load your issues",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
