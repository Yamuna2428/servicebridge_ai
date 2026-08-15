class AiReviewAnalysisModel {
  final String sentiment; // Positive, Neutral, Negative
  final String summary;
  final List<String> strengths;
  final List<String> concerns;
  final String serviceQuality;
  final String professionalism;
  final String punctuality;
  final String communication;

  AiReviewAnalysisModel({
    required this.sentiment,
    required this.summary,
    required this.strengths,
    required this.concerns,
    required this.serviceQuality,
    required this.professionalism,
    required this.punctuality,
    required this.communication,
  });

  factory AiReviewAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiReviewAnalysisModel(
      sentiment: json['sentiment'] ?? 'Neutral',
      summary: json['summary'] ?? 'No summary available.',
      strengths: List<String>.from(json['strengths'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      serviceQuality: json['serviceQuality'] ?? 'Not mentioned',
      professionalism: json['professionalism'] ?? 'Not mentioned',
      punctuality: json['punctuality'] ?? 'Not mentioned',
      communication: json['communication'] ?? 'Not mentioned',
    );
  }
}
