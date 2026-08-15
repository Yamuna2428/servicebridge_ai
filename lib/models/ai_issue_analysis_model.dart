class AiIssueAnalysisModel {
  final String detectedProblem;
  final String recommendedService;
  final String urgency; // Low, Medium, High, Emergency
  final String explanation;
  final List<String> precautions;
  final String professionalRecommendation;
  final bool immediateProfessionalHelp;

  AiIssueAnalysisModel({
    required this.detectedProblem,
    required this.recommendedService,
    required this.urgency,
    required this.explanation,
    required this.precautions,
    required this.professionalRecommendation,
    required this.immediateProfessionalHelp,
  });

  factory AiIssueAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiIssueAnalysisModel(
      detectedProblem: json['detectedProblem'] ?? 'Unknown issue',
      recommendedService: json['recommendedService'] ?? 'Other',
      urgency: json['urgency'] ?? 'Medium',
      explanation: json['explanation'] ?? 'No explanation provided.',
      precautions: List<String>.from(json['precautions'] ?? []),
      professionalRecommendation: json['professionalRecommendation'] ?? 'Contact a professional.',
      immediateProfessionalHelp: json['immediateProfessionalHelp'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detectedProblem': detectedProblem,
      'recommendedService': recommendedService,
      'urgency': urgency,
      'explanation': explanation,
      'precautions': precautions,
      'professionalRecommendation': professionalRecommendation,
      'immediateProfessionalHelp': immediateProfessionalHelp,
    };
  }
}
