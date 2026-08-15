import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../models/service_request_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/service_request_service.dart';
import '../services/ai_service.dart';
import '../widgets/custom_text_field.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  final WorkerModel worker;

  const ServiceRequestFormScreen({super.key, required this.worker});

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _requestService = ServiceRequestService();
  final _aiService = AiService();
  
  final _descriptionController = TextEditingController();
  final _dateTimeController = TextEditingController();
  bool _isLoading = false;
  bool _isImproving = false;
  String? _aiSuggestion;

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  Future<void> _improveDescription() async {
    final originalText = _descriptionController.text.trim();
    if (originalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description first.')),
      );
      return;
    }

    setState(() {
      _isImproving = true;
      _aiSuggestion = null;
    });

    try {
      final improved = await _aiService.improveServiceRequestDescription(originalText);
      setState(() {
        _aiSuggestion = improved;
        _isImproving = false;
      });
    } catch (e) {
      setState(() => _isImproving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = _authService.currentUser;
        if (user == null) throw 'User not authenticated';

        final profile = await _firestoreService.getUserProfile(user.uid);
        if (profile == null) throw 'Customer profile not found';

        final request = ServiceRequestModel(
          requestId: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: user.uid,
          customerName: profile['name'] ?? 'Customer',
          workerId: widget.worker.id,
          serviceCategory: widget.worker.service,
          description: _descriptionController.text.trim(),
          preferredDateTime: _dateTimeController.text.trim(),
          location: profile['location'] ?? 'Not specified',
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _requestService.createRequest(request);

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request sent successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request ${widget.worker.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Service: ${widget.worker.service}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _descriptionController,
                label: 'Problem Description',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (value) => (value == null || value.isEmpty) ? 'Please describe your problem' : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isImproving ? null : _improveDescription,
                  icon: _isImproving 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Improve with AI'),
                ),
              ),
              if (_aiSuggestion != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Suggestion:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(_aiSuggestion!),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _aiSuggestion = null),
                            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _descriptionController.text = _aiSuggestion!;
                              setState(() => _aiSuggestion = null);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            child: const Text('Use Suggestion'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: _dateTimeController,
                label: 'Preferred Date & Time',
                icon: Icons.calendar_today_outlined,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter preferred time' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
