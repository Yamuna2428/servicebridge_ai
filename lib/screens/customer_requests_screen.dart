import 'package:flutter/material.dart';
import '../models/service_request_model.dart';
import '../services/auth_service.dart';
import '../services/service_request_service.dart';
import '../widgets/service_history_insights_widget.dart';
import 'package:intl/intl.dart';

class CustomerRequestsScreen extends StatelessWidget {
  const CustomerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final requestService = ServiceRequestService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text('Please login to view requests.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: requestService.getCustomerRequests(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No requests yet.'));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ServiceHistoryInsightsWidget(requests: requests);
              }
              final request = requests[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            request.serviceCategory,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(request.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${request.preferredDateTime}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(request.description),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(request.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (request.status == RequestStatus.pending || request.status == RequestStatus.accepted)
                            TextButton(
                              onPressed: () => _cancelRequest(context, requestService, request),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Cancel Request'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    Color color;
    switch (status) {
      case RequestStatus.pending: color = Colors.orange; break;
      case RequestStatus.accepted: color = Colors.blue; break;
      case RequestStatus.completed: color = Colors.green; break;
      case RequestStatus.rejected:
      case RequestStatus.cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _cancelRequest(BuildContext context, ServiceRequestService service, ServiceRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this service request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.updateRequestStatus(request.requestId, RequestStatus.cancelled);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request cancelled.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
