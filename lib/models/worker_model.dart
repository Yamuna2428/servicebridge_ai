class WorkerModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String service;
  final String location;
  final double rating;
  final int reviews;
  final bool isAvailable;
  final String experience;
  final int experienceYears;
  final String description;
  final List<String> skills;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  WorkerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.service,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.isAvailable,
    required this.experience,
    required this.experienceYears,
    required this.description,
    required this.skills,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'serviceCategory': service,
      'location': location,
      'rating': rating,
      'reviews': reviews,
      'availability': isAvailable,
      'experience': experience,
      'experienceYears': experienceYears,
      'description': description,
      'skills': skills,
      'latitude': latitude,
      'longitude': longitude,
      'userType': 'Worker',
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map, String docId) {
    return WorkerModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone'] ?? '',
      service: map['serviceCategory'] ?? '',
      location: map['location'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviews: map['reviews'] ?? 0,
      isAvailable: map['availability'] ?? false,
      experience: map['experience'] ?? '',
      experienceYears: map['experienceYears'] ?? 0,
      description: map['description'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : null,
    );
  }

  static List<WorkerModel> getMockWorkers() {
    return [
      WorkerModel(
        id: 'w1',
        name: 'John Doe',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
        service: 'Plumber',
        location: 'Downtown',
        rating: 4.8,
        reviews: 24,
        isAvailable: true,
        experience: '8 Years',
        experienceYears: 8,
        description: 'Professional plumbing services for all your home needs.',
        skills: ['Leak Repair', 'Pipe Installation', 'Drain Cleaning'],
      ),
      WorkerModel(
        id: 'w2',
        name: 'Mike Smith',
        email: 'mike@example.com',
        phoneNumber: '+1987654321',
        service: 'Electrician',
        location: 'Uptown',
        rating: 4.5,
        reviews: 15,
        isAvailable: true,
        experience: '5 Years',
        experienceYears: 5,
        description: 'Licensed electrician specializing in residential wiring.',
        skills: ['Wiring', 'Panel Upgrades', 'Lighting'],
      ),
      WorkerModel(
        id: 'w3',
        name: 'Sarah Wilson',
        email: 'sarah@example.com',
        phoneNumber: '+1122334455',
        service: 'Painter',
        location: 'Westside',
        rating: 4.9,
        reviews: 42,
        isAvailable: false,
        experience: '10 Years',
        experienceYears: 10,
        description: 'High-quality interior and exterior painting.',
        skills: ['Wall Painting', 'Texture Painting', 'Wood Polishing'],
      ),
    ];
  }
}
