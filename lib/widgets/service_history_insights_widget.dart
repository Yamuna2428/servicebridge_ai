import 'package:flutter/material.dart';
import '../models/ai_service_history_insights_model.dart';
import '../models/service_request_model.dart';
import '../services/ai_service.dart';

class ServiceHistoryInsightsWidget extends StatefulWidget {
  final List<ServiceRequestModel> requests;

  const ServiceHistoryInsightsWidget({super.key, required this.requests});

  @override
  State<ServiceHistoryInsightsWidget> createState() => _ServiceHistoryInsightsWidgetState();
}

class _ServiceHistoryInsightsWidgetState extends State<ServiceHistoryInsightsWidget> {
  final _aiService = AiService();
  bool _showInsights = false;
  bool _isLoading = false;
  AiServiceHistoryInsightsModel? _insights;
  String? _error;

  Future<void> _generateInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showInsights = true;
    });

    try {
      // Anonymize and format data for Gemini
      final historyData = widget.requests.map((r) => {
        'category': r.serviceCategory,
        'description': r.description,
      }).toList();

      final result = await _aiService.generateServiceHistoryInsights(historyData);
      
      if (mounted) {
        setState(() {
          _insights = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showInsights) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.requests.isEmpty ? null : _generateInsights,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI Smart Insights'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Smart Insights',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _showInsights = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _generateInsights,
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          else if (_insights != null)
            _buildInsightsContent(_insights!),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(AiServiceHistoryInsightsModel insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insights.summary,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildInsightRow(Icons.repeat, 'Frequent Service', insights.frequentService),
        _buildInsightRow(Icons.warning_amber_rounded, 'Repeated Pattern', insights.repeatedIssue),
        _buildInsightRow(Icons.tips_and_updates_outlined, 'Maintenance Tip', insights.maintenanceSuggestion),
        const Divider(color: Colors.white24, height: 24),
        Row(
          children: [
            const Text(
              'Analysis Confidence: ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              insights.confidence,
              style: TextStyle(
                color: _getConfidenceColor(insights.confidence),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[200], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high': return Colors.greenAccent;
      case 'medium': return Colors.orangeAccent;
      default: return Colors.redAccent;
    }
  }
}
