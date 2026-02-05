import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../model/issue_category_model.dart';

class IssueCategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<IssueCategory> categories = <IssueCategory>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot = await _firestore
          .collection('issue_categories')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get();

      categories.value = snapshot.docs
          .map((doc) => IssueCategory.fromFirestore(
        doc.id,
        doc.data(),
      ))
          .toList();
    } finally {
      isLoading.value = false;
    }
  }
}

