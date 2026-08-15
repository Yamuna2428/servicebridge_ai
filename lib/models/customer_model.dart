class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final DateTime? createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'location': location,
      'userType': 'Customer',
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone'] ?? '',
      location: map['location'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : null,
    );
  }

  static CustomerModel getMockCustomer() {
    return CustomerModel(
      id: 'c1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      phoneNumber: '+1555666777',
      location: 'City Center',
    );
  }
}
