import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysoul/models/perfume.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get perfumesCollection =>
      _firestore.collection('perfumes');

  // Get all perfumes (LIVE)
  Stream<List<Perfume>> getPerfumes() {
    return perfumesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        Perfume.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Add new perfume
  Future<void> addPerfume(Perfume perfume) async {
    await perfumesCollection.add(perfume.toMap());
  }

  // Update perfume quantity
  Future<void> updatePerfumeQuantity(
      String perfumeId, int newQuantity) async {
    await perfumesCollection
        .doc(perfumeId)
        .update({'quantity': newQuantity});
  }

  // Decrement by 1 (old usage)
  Future<void> decrementQuantity(String perfumeId) async {
    await perfumesCollection.doc(perfumeId).update({
      'quantity': FieldValue.increment(-1),
    });
  }

  // ✅ NEW — Decrement by specific amount (USED BY SALES SCREEN)
  Future<void> decrementQuantityBy(String perfumeId, int amount) async {
    final docRef = perfumesCollection.doc(perfumeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Perfume not found');
      }

      final currentQuantity = snapshot['quantity'] ?? 0;

      if (currentQuantity < amount) {
        throw Exception('Not enough stock available');
      }

      transaction.update(docRef, {
        'quantity': currentQuantity - amount,
      });
    });
  }

  // Get perfume by ID
  Future<Perfume?> getPerfumeById(String perfumeId) async {
    final doc = await perfumesCollection.doc(perfumeId).get();
    if (doc.exists) {
      return Perfume.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get perfumes for dropdown
  Future<List<Perfume>> getPerfumesForDropdown() async {
    final snapshot = await perfumesCollection.orderBy('name').get();
    return snapshot.docs
        .map((doc) =>
        Perfume.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
