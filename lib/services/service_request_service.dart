import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';

class ServiceRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final ServiceRequestService _instance = ServiceRequestService._internal();
  factory ServiceRequestService() => _instance;
  ServiceRequestService._internal();

  // Create a new service request
  Future<void> createRequest(ServiceRequestModel request) async {
    try {
      await _db.collection('service_requests').doc(request.requestId).set({
        ...request.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error creating service request: $e';
    }
  }

  // Get requests for a customer
  Stream<List<ServiceRequestModel>> getCustomerRequests(String customerId) {
    return _db
        .collection('service_requests')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get requests for a worker
  Stream<List<ServiceRequestModel>> getWorkerRequests(String workerId) {
    return _db
        .collection('service_requests')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, RequestStatus newStatus) async {
    try {
      await _db.collection('service_requests').doc(requestId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error updating request status: $e';
    }
  }
}
