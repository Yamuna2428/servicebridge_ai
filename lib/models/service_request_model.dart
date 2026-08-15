import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled
}

extension RequestStatusExtension on RequestStatus {
  String get name {
    switch (this) {
      case RequestStatus.pending: return 'Pending';
      case RequestStatus.accepted: return 'Accepted';
      case RequestStatus.rejected: return 'Rejected';
      case RequestStatus.completed: return 'Completed';
      case RequestStatus.cancelled: return 'Cancelled';
    }
  }

  static RequestStatus fromString(String name) {
    switch (name) {
      case 'Accepted': return RequestStatus.accepted;
      case 'Rejected': return RequestStatus.rejected;
      case 'Completed': return RequestStatus.completed;
      case 'Cancelled': return RequestStatus.cancelled;
      default: return RequestStatus.pending;
    }
  }
}

class ServiceRequestModel {
  final String requestId;
  final String customerId;
  final String customerName;
  final String workerId;
  final String serviceCategory;
  final String description;
  final String preferredDateTime;
  final String location;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequestModel({
    required this.requestId,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.serviceCategory,
    required this.description,
    required this.preferredDateTime,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'customerId': customerId,
      'customerName': customerName,
      'workerId': workerId,
      'serviceCategory': serviceCategory,
      'description': description,
      'preferredDateTime': preferredDateTime,
      'location': location,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceRequestModel(
      requestId: docId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      workerId: map['workerId'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      description: map['description'] ?? '',
      preferredDateTime: map['preferredDateTime'] ?? '',
      location: map['location'] ?? '',
      status: RequestStatusExtension.fromString(map['status'] ?? 'Pending'),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
