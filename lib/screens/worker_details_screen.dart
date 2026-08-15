import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/review_service.dart';
import '../services/call_service.dart';
import '../widgets/review_insight_widget.dart';
import 'service_request_form_screen.dart';
import 'package:intl/intl.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerDetailsScreen({super.key, required this.worker});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  final _authService = AuthService();
  final _reviewService = ReviewService();
  final _firestoreService = FirestoreService();
  final _callService = CallService();
  
  bool _hasReviewed = false;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      // 1. Check if the current user is a worker (to hide rating button)
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null && profile['userType'] == 'Worker') {
        setState(() => _isWorker = true);
      }

      // 2. Check if already reviewed
      bool reviewed = await _reviewService.hasUserReviewedWorker(user.uid, widget.worker.id);
      setState(() => _hasReviewed = reviewed);
    }
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write your experience (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setDialogState(() => isSubmitting = true);
                try {
                  final user = _authService.currentUser;
                  if (user == null) throw 'User not authenticated';
                  
                  final profile = await _firestoreService.getUserProfile(user.uid);
                  
                  final review = ReviewModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    workerId: widget.worker.id,
                    customerId: user.uid,
                    customerName: profile?['name'] ?? 'Anonymous',
                    rating: selectedRating,
                    comment: commentController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  await _reviewService.addReview(review);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() => _hasReviewed = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => isSubmitting = true); // Need to reset if I want to allow retry, but logic below sets it to false.
                    // Actually, I should just set isSubmitting to false.
                    setDialogState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.blue[100],
                child: const Center(
                  child: Icon(Icons.person, size: 120, color: Colors.blue),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.worker.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(widget.worker.service, style: TextStyle(fontSize: 18, color: Colors.blue[700])),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.worker.reviews > 0 
                                ? widget.worker.rating.toStringAsFixed(1) 
                                : 'New',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.location_on, widget.worker.location),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.work, '${widget.worker.experience} Experience'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.event_available, widget.worker.isAvailable ? 'Available Now' : 'Not Available'),
                  
                  const Divider(height: 40),
                  const Text('About Me', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(widget.worker.description, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  const Text('Skills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: widget.worker.skills.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.blue[50],
                      labelStyle: const TextStyle(color: Colors.blue),
                    )).toList(),
                  ),

                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (!_isWorker && !_hasReviewed && _authService.currentUser?.uid != widget.worker.id)
                        TextButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Rate Worker'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReviewsList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            if (!_isWorker) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceRequestFormScreen(worker: widget.worker),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Book Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callService.makePhoneCall(context, widget.worker.phoneNumber),
                icon: const Icon(Icons.call),
                label: const Text('Call Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getWorkerReviews(widget.worker.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No reviews yet. Be the first to rate!', style: TextStyle(color: Colors.grey)),
          );
        }

        final reviews = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(review.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review.comment, style: const TextStyle(color: Colors.black87)),
                  ReviewInsightWidget(reviewText: review.comment),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 22),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
