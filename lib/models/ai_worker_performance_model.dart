class AiWorkerPerformanceModel {
  final String performanceSummary;
  final List<String> topSkillsIdentified;
  final List<String> improvementAreas;
  final String customerSentiment; // Positive, Neutral, Negative
  final String businessTip;

  AiWorkerPerformanceModel({
    required this.performanceSummary,
    required this.topSkillsIdentified,
    required this.improvementAreas,
    required this.customerSentiment,
    required this.businessTip,
  });

  factory AiWorkerPerformanceModel.fromJson(Map<String, dynamic> json) {
    return AiWorkerPerformanceModel(
      performanceSummary: json['performanceSummary'] ?? 'No summary available.',
      topSkillsIdentified: List<String>.from(json['topSkillsIdentified'] ?? []),
      improvementAreas: List<String>.from(json['improvementAreas'] ?? []),
      customerSentiment: json['customerSentiment'] ?? 'Neutral',
      businessTip: json['businessTip'] ?? 'Keep providing great service!',
    );
  }
}
