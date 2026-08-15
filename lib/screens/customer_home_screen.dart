import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/worker_model.dart';
import '../widgets/service_category_card.dart';
import '../widgets/worker_card.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'worker_list_screen.dart';
import 'worker_details_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_requests_screen.dart';
import 'ai_issue_analyzer_screen.dart';
import 'ai_service_assistant_screen.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  
  final List<ServiceModel> _services = ServiceModel.getMockServices();
  List<WorkerModel> _nearbyWorkers = [];
  bool _isLoadingWorkers = true;
  String _customerName = 'Customer';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _findWorkersNearMe() async {
    try {
      Position position = await _locationService.getCurrentPosition();
      setState(() => _userPosition = position);
      
      // Re-sort current list if we already have it
      if (_nearbyWorkers.isNotEmpty) {
        setState(() {
          _nearbyWorkers.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;
            
            double distA = _locationService.getDistanceInKm(
              _userPosition!.latitude,
              _userPosition!.longitude,
              a.latitude!,
              a.longitude!,
            );
            double distB = _locationService.getDistanceInKm(
              _userPosition!.latitude,
              _userPosition!.longitude,
              b.latitude!,
              b.longitude!,
            );
            return distA.compareTo(distB);
          });
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location found! Showing nearest workers.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final profile = await _firestoreService.getUserProfile(uid);
        if (profile != null) {
          if (mounted) {
            setState(() => _customerName = profile['name'] ?? 'Customer');
          }
        }
      }
      
      final workersData = await _firestoreService.getWorkers();
      if (mounted) {
        setState(() {
          _nearbyWorkers = workersData.map((data) => WorkerModel.fromMap(data, data['uid'] ?? '')).toList();
          
          if (_userPosition != null) {
            _nearbyWorkers.sort((a, b) {
              if (a.latitude == null || a.longitude == null) return 1;
              if (b.latitude == null || b.longitude == null) return -1;
              
              double distA = _locationService.getDistanceInKm(
                _userPosition!.latitude,
                _userPosition!.longitude,
                a.latitude!,
                a.longitude!,
              );
              double distB = _locationService.getDistanceInKm(
                _userPosition!.latitude,
                _userPosition!.longitude,
                b.latitude!,
                b.longitude!,
              );
              return distA.compareTo(distB);
            });
          }
          
          _isLoadingWorkers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWorkers = false);
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
          const Center(child: Text('Search Screen')),
          const CustomerRequestsScreen(),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Colors.blue,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('ServiceBridge AI', style: TextStyle(fontWeight: FontWeight.bold)),
            background: Container(color: Colors.blue),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_customerName!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                const Text(
                  'What service do you need today?',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for services...',
                          prefixIcon: const Icon(Icons.search, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _findWorkersNearMe,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _userPosition != null ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.blue.withAlpha(26), blurRadius: 5)],
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: _userPosition != null ? Colors.white : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // AI Diagnostic Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiIssueAnalyzerScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.white, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Issue Analyzer',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Describe your problem and let Gemini AI diagnose it for you.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Assistant Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiServiceAssistantScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Service Assistant',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ask anything about home services and get safe guidance.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('See All', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _services.length > 8 ? 8 : _services.length,
                  itemBuilder: (context, index) {
                    return ServiceCategoryCard(
                      service: _services[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkerListScreen(
                              serviceName: _services[index].name,
                              userPosition: _userPosition,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                // AI Diagnostic Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiIssueAnalyzerScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.white, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Issue Analyzer',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Describe your problem and let Gemini AI diagnose it for you.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Assistant Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiServiceAssistantScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Service Assistant',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ask anything about home services and get safe guidance.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Nearby Workers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_isLoadingWorkers)
                  const Center(child: CircularProgressIndicator())
                else if (_nearbyWorkers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No workers found nearby.', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ),
        if (!_isLoadingWorkers && _nearbyWorkers.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final worker = _nearbyWorkers[index];
                  String? distanceStr;
                  
                  if (_userPosition != null && worker.latitude != null && worker.longitude != null) {
                    distanceStr = _locationService.getDistanceString(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                      worker.latitude!,
                      worker.longitude!,
                    );
                  }

                  return WorkerCard(
                    worker: worker,
                    distance: distanceStr,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerDetailsScreen(worker: worker),
                        ),
                      );
                    },
                    onCallPressed: () {
                      // Logic handled in Details screen
                    },
                  );
                },
                childCount: _nearbyWorkers.length,
              ),
            ),
          ),
      ],
    );
  }
}
