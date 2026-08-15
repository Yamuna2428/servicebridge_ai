import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/service_request_service.dart';
import '../services/review_service.dart';
import '../models/service_request_model.dart';
import '../models/review_model.dart';
import '../models/worker_model.dart';
import '../widgets/worker_performance_insights_widget.dart';
import 'worker_profile_screen.dart';
import 'worker_requests_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _selectedIndex = 0;
  bool _isAvailable = true;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _requestService = ServiceRequestService();
  final _reviewService = ReviewService();

  WorkerModel? _worker;
  List<ServiceRequestModel> _allRequests = [];
  List<ReviewModel> _allReviews = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    try {
      final profile = await _firestoreService.getUserProfile(uid);
      if (profile != null) {
        if (mounted) {
          setState(() {
            _worker = WorkerModel.fromMap(profile, uid);
            _isAvailable = _worker?.isAvailable ?? true;
          });
        }
      }

      // Fetch requests for analytics
      final requestsSnapshot = await _requestService.getWorkerRequests(uid).first;
      
      // Fetch reviews for analytics
      final reviewsSnapshot = await _reviewService.getWorkerReviews(uid).first;

      if (mounted) {
        setState(() {
          _allRequests = requestsSnapshot;
          _allReviews = reviewsSnapshot;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          const WorkerRequestsScreen(),
          const WorkerProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final completedJobs = _allRequests.where((r) => r.status == RequestStatus.completed).length;
    final totalEarnings = completedJobs * 50; // Mock calculation

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${_worker?.name.split(" ")[0] ?? "Pro"}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('${_worker?.service ?? "Professional"} • ${_worker?.location ?? "Local"}', style: TextStyle(color: Colors.blue[700])),
                ],
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, size: 35, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // AI Performance Insights
          WorkerPerformanceInsightsWidget(
            jobHistory: _allRequests.map((r) => {
              'category': r.serviceCategory,
              'status': r.status.name,
              'description': r.description,
            }).toList(),
            reviews: _allReviews.map((r) => r.comment).toList(),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blue.withAlpha(26), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('Available for work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                    // In a real app, update Firestore status here
                  },
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(_allRequests.length.toString(), 'Total Requests', Icons.pending_actions, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('\$$totalEarnings', 'Estimated Earnings', Icons.attach_money, Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_allRequests.isEmpty)
            const Text('No recent activity.', style: TextStyle(color: Colors.grey))
          else
            ..._allRequests.take(5).map((req) => _buildActivityItem(
              req.customerName,
              '${req.status.name} ${req.serviceCategory} request',
              'Recently',
            )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.blue.withAlpha(13), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String name, String action, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.history, color: Colors.blue)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(action, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
