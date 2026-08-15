import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  // Add a new review and update worker rating summary
  Future<void> addReview(ReviewModel review) async {
    try {
      // 1. Add the review to the reviews collection
      await _db.collection('reviews').doc(review.id).set(review.toMap());

      // 2. Fetch all reviews for this worker to calculate new average
      QuerySnapshot reviewSnapshot = await _db
          .collection('reviews')
          .where('workerId', isEqualTo: review.workerId)
          .get();

      int count = reviewSnapshot.docs.length;
      double sum = 0;
      for (var doc in reviewSnapshot.docs) {
        sum += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
      }

      double average = count > 0 ? sum / count : 0.0;

      // 3. Update the worker\u0027s profile with the new summary
      await _db.collection('users').doc(review.workerId).update({
        'rating': average,
        'reviews': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error adding review: $e';
    }
  }

  // Get reviews for a specific worker
  Stream<List<ReviewModel>> getWorkerReviews(String workerId) {
    return _db
        .collection('reviews')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if a customer has already reviewed a worker
  Future<bool> hasUserReviewedWorker(String customerId, String workerId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .where('workerId', isEqualTo: workerId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
