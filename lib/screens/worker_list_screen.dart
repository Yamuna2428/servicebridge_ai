import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../widgets/worker_card.dart';
import '../models/ai_worker_recommendation_model.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import 'worker_details_screen.dart';
import '../services/location_service.dart';
import '../services/call_service.dart';
import 'package:geolocator/geolocator.dart';

class WorkerListScreen extends StatefulWidget {
  final String serviceName;
  final Position? userPosition;
  final bool isFromAiAnalyzer;
  final String? problemDescription;

  const WorkerListScreen({
    super.key,
    required this.serviceName,
    this.userPosition,
    this.isFromAiAnalyzer = false,
    this.problemDescription,
  });

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _callService = CallService();
  final _aiService = AiService();
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  
  List<WorkerModel> _allWorkers = [];
  List<WorkerModel> _filteredWorkers = [];
  List<AiWorkerRecommendation> _aiRecommendations = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isAiRanking = false;
  bool _isLocating = false;
  String _errorMessage = '';
  String _sortBy = 'Name';
  double? _maxDistance; // in km

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleUseMyLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLocating = false;
        _sortBy = 'Distance'; // Auto-sort by distance when location is enabled
      });
      _applyFilters();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 Location updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _firestoreService.getWorkers(category: widget.serviceName);
      setState(() {
        _allWorkers = data.map((d) => WorkerModel.fromMap(d, d['uid'] ?? '')).toList();
        _applyFilters();
        _isLoading = false;
      });

      // Trigger AI recommendation if requested
      if (widget.isFromAiAnalyzer && widget.problemDescription != null && _allWorkers.isNotEmpty) {
        _fetchAiRecommendations();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAiRecommendations() async {
    setState(() => _isAiRanking = true);
    try {
      final recommendations = await _aiService.recommendWorkers(
        problemDescription: widget.problemDescription!,
        serviceCategory: widget.serviceName,
        customerLocation: _currentPosition != null 
            ? 'Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}' 
            : null,
        candidates: _allWorkers,
      );
      setState(() {
        _aiRecommendations = recommendations;
        _isAiRanking = false;
      });
    } catch (e) {
      setState(() => _isAiRanking = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final locationQuery = _locationController.text.toLowerCase();

    setState(() {
      _filteredWorkers = _allWorkers.where((w) {
        final matchesName = w.name.toLowerCase().contains(query);
        final matchesCategory = w.service.toLowerCase().contains(query);
        final matchesLocation = w.location.toLowerCase().contains(locationQuery);
        
        bool matchesDistance = true;
        if (_currentPosition != null && _maxDistance != null) {
          if (w.latitude != null && w.longitude != null) {
            double dist = _locationService.getDistanceInKm(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              w.latitude!,
              w.longitude!,
            );
            matchesDistance = dist <= _maxDistance!;
          } else {
            matchesDistance = false;
          }
        }

        return (matchesName || matchesCategory) && matchesLocation && matchesDistance;
      }).toList();

      if (_sortBy == 'Name') {
        _filteredWorkers.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortBy == 'Experience') {
        _filteredWorkers.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
      } else if (_sortBy == 'Rating') {
        _filteredWorkers.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (_sortBy == 'Distance' && _currentPosition != null) {
        _filteredWorkers.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          
          double distA = _locationService.getDistanceInKm(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            a.latitude!,
            a.longitude!,
          );
          double distB = _locationService.getDistanceInKm(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text('${widget.serviceName}s', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Search by name or skill...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Filter by city...',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: IconButton(
                      icon: _isLocating 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.my_location, color: _currentPosition != null ? Colors.green : Colors.blue),
                      onPressed: _isLocating ? null : _handleUseMyLocation,
                      tooltip: 'Use My Location',
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading ? 'Searching...' : '${_filteredWorkers.length} Workers found',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  items: [
                    'Name',
                    'Experience',
                    'Rating',
                    if (_currentPosition != null) 'Distance',
                  ].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text('Sort by $value'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sortBy = val);
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text('Max Distance: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  DropdownButton<double?>(
                    value: _maxDistance,
                    hint: const Text('Any distance'),
                    items: [
                      const DropdownMenuItem(value: 2.0, child: Text('Within 2 km')),
                      const DropdownMenuItem(value: 5.0, child: Text('Within 5 km')),
                      const DropdownMenuItem(value: 10.0, child: Text('Within 10 km')),
                      const DropdownMenuItem(value: 25.0, child: Text('Within 25 km')),
                      const DropdownMenuItem(value: null, child: Text('Any distance')),
                    ],
                    onChanged: (val) {
                      setState(() => _maxDistance = val);
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            TextButton(onPressed: _fetchWorkers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('No skilled workers found for this service.'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_isAiRanking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('AI is ranking best workers for you...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        if (_aiRecommendations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('AI Best Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          ..._aiRecommendations.map((rec) {
            final worker = _allWorkers.firstWhere((w) => w.id == rec.workerId);
            String? distanceStr;
            if (_currentPosition != null && worker.latitude != null && worker.longitude != null) {
              distanceStr = _locationService.getDistanceString(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                worker.latitude!,
                worker.longitude!,
              );
            }
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(51), width: 2),
              ),
              child: WorkerCard(
                worker: worker,
                distance: distanceStr,
                aiReason: rec.reason,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WorkerDetailsScreen(worker: worker)),
                  );
                },
                onCallPressed: () => _callService.makePhoneCall(context, worker.phoneNumber),
              ),
            );
          }),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('All Workers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ] else if (widget.isFromAiAnalyzer && !_isAiRanking) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Not enough worker information is available for AI matching. You can still browse all available workers.',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ..._filteredWorkers.map((worker) {
          String? distanceStr;
          if (_currentPosition != null && worker.latitude != null && worker.longitude != null) {
            distanceStr = _locationService.getDistanceString(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
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
                MaterialPageRoute(builder: (context) => WorkerDetailsScreen(worker: worker)),
              );
            },
            onCallPressed: () => _callService.makePhoneCall(context, worker.phoneNumber),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }
}
