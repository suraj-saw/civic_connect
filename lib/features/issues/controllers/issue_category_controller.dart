import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/issue_category_model.dart';

class IssueCategoryController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final categories = <IssueCategory>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() { super.onInit(); fetchCategories(); }

  Future<void> fetchCategories() async {
    try {
      final snap = await _firestore.collection('issue_categories')
          .where('active', isEqualTo: true).orderBy('order').get();
      categories.value = snap.docs.map((d) => IssueCategory.fromFirestore(d.id, d.data())).toList();
    } catch (e) {
      // fallback without orderBy
      try {
        final snap = await _firestore.collection('issue_categories').where('active', isEqualTo: true).get();
        categories.value = snap.docs.map((d) => IssueCategory.fromFirestore(d.id, d.data())).toList();
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }
}
