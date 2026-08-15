import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/worker_model.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/custom_text_field.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  
  WorkerModel? _worker;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _serviceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _serviceController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final data = await _firestoreService.getUserProfile(uid);
        if (data != null) {
          setState(() {
            _worker = WorkerModel.fromMap(data, uid);
            _nameController.text = _worker!.name;
            _phoneController.text = _worker!.phoneNumber;
            _locationController.text = _worker!.location;
            _serviceController.text = _worker!.service;
            _experienceController.text = _worker!.experience;
            _descriptionController.text = _worker!.description;
            _latitude = _worker!.latitude;
            _longitude = _worker!.longitude;
          });
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coordinates updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_worker == null) return;
    
    setState(() => _isLoading = true);
    try {
      final updatedWorker = WorkerModel(
        id: _worker!.id,
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        name: _nameController.text.trim(),
        email: _worker!.email,
        phoneNumber: _phoneController.text.trim(),
        service: _serviceController.text.trim(),
        location: _locationController.text.trim(),
        rating: _worker!.rating,
        reviews: _worker!.reviews,
        isAvailable: _worker!.isAvailable,
        experience: _experienceController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _worker!.skills,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: _worker!.createdAt,
      );

      await _firestoreService.saveUserProfile(_worker!.id, updatedWorker.toMap());
      
      setState(() {
        _worker = updatedWorker;
        _isEditing = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_worker == null) {
      return const Center(child: Text('Profile not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 16),
          
          if (_isEditing) ...[
            CustomTextField(controller: _nameController, label: 'Name', icon: Icons.person_outline),
            const SizedBox(height: 12),
            CustomTextField(controller: _phoneController, label: 'Phone', icon: Icons.phone_outlined),
            const SizedBox(height: 12),
            CustomTextField(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            CustomTextField(controller: _serviceController, label: 'Service Category', icon: Icons.work_outline),
            const SizedBox(height: 12),
            CustomTextField(controller: _experienceController, label: 'Experience', icon: Icons.history),
            const SizedBox(height: 12),
            CustomTextField(controller: _descriptionController, label: 'Description', icon: Icons.description_outlined),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(_latitude != null ? 'Location Captured' : 'Use Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _latitude != null ? Colors.green[50] : Colors.blue[50],
                foregroundColor: _latitude != null ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(_worker!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(_worker!.service, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildProfileItem(Icons.phone, 'Phone', _worker!.phoneNumber),
            _buildProfileItem(Icons.email, 'Email', _worker!.email),
            _buildProfileItem(Icons.location_on, 'Location', _worker!.location),
            _buildProfileItem(Icons.work, 'Experience', _worker!.experience),
            _buildProfileItem(Icons.star, 'Rating', '${_worker!.rating} (${_worker!.reviews} Reviews)'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/user_type', (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
