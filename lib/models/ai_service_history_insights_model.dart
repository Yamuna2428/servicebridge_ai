class AiServiceHistoryInsightsModel {
  final String summary;
  final String frequentService;
  final String repeatedIssue;
  final String maintenanceSuggestion;
  final String confidence;

  AiServiceHistoryInsightsModel({
    required this.summary,
    required this.frequentService,
    required this.repeatedIssue,
    required this.maintenanceSuggestion,
    required this.confidence,
  });

  factory AiServiceHistoryInsightsModel.fromJson(Map<String, dynamic> json) {
    return AiServiceHistoryInsightsModel(
      summary: json['summary'] ?? 'No summary available.',
      frequentService: json['frequentService'] ?? 'Not enough data',
      repeatedIssue: json['repeatedIssue'] ?? 'Not enough data',
      maintenanceSuggestion: json['maintenanceSuggestion'] ?? 'Keep up with regular maintenance!',
      confidence: json['confidence'] ?? 'Low',
    );
  }
}
