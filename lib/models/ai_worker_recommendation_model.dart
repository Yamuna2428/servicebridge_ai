class AiWorkerRecommendation {
  final String workerId;
  final String reason;
  final int matchScore;

  AiWorkerRecommendation({
    required this.workerId,
    required this.reason,
    required this.matchScore,
  });

  factory AiWorkerRecommendation.fromJson(Map<String, dynamic> json) {
    return AiWorkerRecommendation(
      workerId: json['workerId'] ?? '',
      reason: json['reason'] ?? '',
      matchScore: json['matchScore'] ?? 0,
    );
  }
}

class AiWorkerRecommendationResponse {
  final List<AiWorkerRecommendation> recommendations;

  AiWorkerRecommendationResponse({required this.recommendations});

  factory AiWorkerRecommendationResponse.fromJson(Map<String, dynamic> json) {
    var list = json['recommendations'] as List?;
    List<AiWorkerRecommendation> recommendationsList = list != null
        ? list.map((i) => AiWorkerRecommendation.fromJson(i)).toList()
        : [];
    return AiWorkerRecommendationResponse(recommendations: recommendationsList);
  }
}
