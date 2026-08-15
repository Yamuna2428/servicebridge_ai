import 'package:flutter/material.dart';
import '../models/ai_review_analysis_model.dart';
import '../services/ai_service.dart';

class ReviewInsightWidget extends StatefulWidget {
  final String reviewText;

  const ReviewInsightWidget({super.key, required this.reviewText});

  @override
  State<ReviewInsightWidget> createState() => _ReviewInsightWidgetState();
}

class _ReviewInsightWidgetState extends State<ReviewInsightWidget> {
  final _aiService = AiService();
  bool _showInsight = false;
  bool _isLoading = false;
  AiReviewAnalysisModel? _insight;
  String? _error;

  Future<void> _fetchInsight() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showInsight = true;
    });

    try {
      final result = await _aiService.analyzeWorkerReview(widget.reviewText);
      if (mounted) {
        setState(() {
          _insight = result;
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
    if (!_showInsight) {
      return TextButton.icon(
        onPressed: _fetchInsight,
        icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
        label: const Text('AI Insight', style: TextStyle(fontSize: 12, color: Colors.blue)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Review Insights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () => setState(() => _showInsight = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: LinearProgressIndicator(minHeight: 2))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))
          else if (_insight != null)
            _buildInsightContent(_insight!),
        ],
      ),
    );
  }

  Widget _buildInsightContent(AiReviewAnalysisModel insight) {
    Color sentimentColor;
    switch (insight.sentiment.toLowerCase()) {
      case 'positive': sentimentColor = Colors.green; break;
      case 'negative': sentimentColor = Colors.red; break;
      default: sentimentColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sentimentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sentimentColor),
              ),
              child: Text(
                insight.sentiment,
                style: TextStyle(color: sentimentColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          insight.summary,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        if (insight.strengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Strengths:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ...insight.strengths.map((s) => _buildBulletPoint(s)),
        ],
        if (insight.concerns.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Concerns:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
          ...insight.concerns.map((c) => _buildBulletPoint(c)),
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _buildMetricRow('Service Quality', insight.serviceQuality),
        _buildMetricRow('Professionalism', insight.professionalism),
        _buildMetricRow('Punctuality', insight.punctuality),
        _buildMetricRow('Communication', insight.communication),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    if (value.toLowerCase() == 'not mentioned') return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
