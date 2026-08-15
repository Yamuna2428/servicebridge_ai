import 'package:flutter/material.dart';
import '../models/ai_worker_performance_model.dart';
import '../services/ai_service.dart';

class WorkerPerformanceInsightsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> jobHistory;
  final List<String> reviews;

  const WorkerPerformanceInsightsWidget({
    super.key,
    required this.jobHistory,
    required this.reviews,
  });

  @override
  State<WorkerPerformanceInsightsWidget> createState() => _WorkerPerformanceInsightsWidgetState();
}

class _WorkerPerformanceInsightsWidgetState extends State<WorkerPerformanceInsightsWidget> {
  final _aiService = AiService();
  bool _showInsights = false;
  bool _isLoading = false;
  AiWorkerPerformanceModel? _insights;
  String? _error;

  Future<void> _generateInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showInsights = true;
    });

    try {
      final result = await _aiService.generateWorkerPerformanceInsights(
        jobHistory: widget.jobHistory,
        reviews: widget.reviews,
      );
      
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
        margin: const EdgeInsets.symmetric(vertical: 24),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateInsights,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('AI Business Insights'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(13),
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
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Performance Analysis',
                    style: TextStyle(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
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
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _generateInsights,
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (_insights != null)
            _buildInsightsContent(_insights!),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(AiWorkerPerformanceModel insights) {
    Color sentimentColor;
    switch (insights.customerSentiment.toLowerCase()) {
      case 'positive': sentimentColor = Colors.green; break;
      case 'negative': sentimentColor = Colors.red; break;
      default: sentimentColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insights.performanceSummary,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        
        if (insights.topSkillsIdentified.isNotEmpty) ...[
          const Text('Top Strengths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: insights.topSkillsIdentified.map((skill) => Chip(
              label: Text(skill, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.blue[50],
              side: BorderSide.none,
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],

        if (insights.improvementAreas.isNotEmpty) ...[
          const Text('Improvement Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          ...insights.improvementAreas.map((area) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(area, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
          const SizedBox(height: 20),
        ],

        Row(
          children: [
            const Text('Customer Sentiment: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
            Text(
              insights.customerSentiment,
              style: TextStyle(color: sentimentColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const Divider(height: 32),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Growth Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text(insights.businessTip, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
