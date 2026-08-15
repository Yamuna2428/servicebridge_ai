import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/ai_issue_analysis_model.dart';
import '../models/ai_worker_recommendation_model.dart';
import '../models/ai_review_analysis_model.dart';
import '../models/ai_service_history_insights_model.dart';
import '../models/ai_worker_performance_model.dart';
import '../models/worker_model.dart';

class AiService {
  late final GenerativeModel _model;
  late final GenerativeModel _recommendationModel;
  late final GenerativeModel _assistantModel;
  late final GenerativeModel _descriptionHelperModel;
  late final GenerativeModel _reviewAnalysisModel;
  late final GenerativeModel _historyInsightsModel;
  late final GenerativeModel _workerPerformanceModel;

  // Singleton pattern
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  AiService._internal() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a professional home service diagnostic assistant for the ServiceBridge AI app. '
        'Your goal is to analyze a customer\'s problem (provided via text, image, or both) and provide structured diagnostic advice. '
        '\n\nSAFETY RULES:\n'
        '1. NEVER provide dangerous repair instructions.\n'
        '2. NEVER tell users to open electrical panels, repair live wiring, dismantle appliances, or fix gas lines.\n'
        '3. For fire, smoke, sparks, or gas smells, recommend immediate evacuation and professional/emergency help.\n'
        '4. For plumbing leaks, suggest turning off the main water valve ONLY if safe.\n'
        '5. Always state: "This is general guidance and does not replace a professional inspection."\n'
        '\n\nIMAGE ANALYSIS RULES:\n'
        '1. If an image is provided, analyze it carefully but conservatively.\n'
        '2. Use phrases like "The image appears to show..." or "This may indicate...".\n'
        '3. Do NOT invent details not visible in the image.\n'
        '4. Prioritize safety if dangerous components (exposed wires, etc.) are visible.'
        '\n\nOUTPUT FORMAT:\n'
        'You must return ONLY a JSON object with this exact structure:\n'
        '{\n'
        '  "detectedProblem": "Short summary",\n'
        '  "recommendedService": "Must be one of: Plumber, Electrician, AC Mechanic, Carpenter, Painter, Appliance Repair, Mason, or Other",\n'
        '  "urgency": "Low | Medium | High | Emergency",\n'
        '  "explanation": "Brief non-technical explanation",\n'
        '  "precautions": ["List of safe steps"],\n'
        '  "professionalRecommendation": "Why a professional is needed",\n'
        '  "immediateProfessionalHelp": boolean\n'
        '}'
      ),
    );

    _recommendationModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a professional matching assistant for the ServiceBridge AI app. '
        'Your goal is to identify the single most suitable worker as the "AI Best Match" and up to 2 other high-quality matches based on a customer\'s problem description.'
        '\n\nRANKING FACTORS:\n'
        '1. Skill Relevance: How well the worker\'s listed skills and profile match the customer\'s specific problem.\n'
        '2. Experience: Favor workers with more years of experience.\n'
        '3. Performance: Favor workers with higher ratings and more reviews.\n'
        '4. Availability: Prioritize workers who are currently available.'
        '\n\nPRIVACY & INTEGRITY:\n'
        '- You will only receive anonymized IDs (e.g., Candidate_1). You MUST use these IDs in your response.\n'
        '- NEVER invent workers or skills.\n'
        '- If no workers are a good fit for the problem, return an empty list.'
        '\n\nOUTPUT FORMAT:\n'
        'You must return ONLY a JSON object with this exact structure:\n'
        '{\n'
        '  "recommendations": [\n'
        '    {\n'
        '      "workerId": "MUST be the anonymized ID provided (e.g., Candidate_1)",\n'
        '      "reason": "Professional explanation (1-2 sentences) of why this worker is a great match for this specific problem.",\n'
        '      "matchScore": 0-100\n'
        '    }\n'
        '  ]\n'
        '}\n'
        'The first item in the list will be treated as the "AI Best Match".'
      ),
    );

    _assistantModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a helpful and safe AI Service Assistant for the ServiceBridge AI app. '
        'Your goal is to answer household service questions and provide general troubleshooting guidance.'
        '\n\nCORE RULES:\n'
        '1. Answer home service questions simply and clearly.\n'
        '2. FORMATTING: Use ONLY plain text. Do NOT use Markdown, bolding (**), headings (###), horizontal lines (---), or any other special formatting characters.\n'
        '3. SAFETY FIRST: Detect dangerous situations (sparks, gas smell, fire, water near electricity).\n'
        '   - FOR ELECTRICAL HAZARDS (sparks, smoke, burning smell, exposed wiring, fire): You MUST respond with: "Do not touch the socket, wiring, or connected appliances. Move away from the area and contact a qualified electrician immediately. If there is smoke, fire, or a burning smell, leave the area and contact emergency services."\n'
        '   - NEVER instruct users to access electrical panels, operate circuit breakers, turn off breakers, touch equipment, or inspect wiring.\n'
        '4. NO DANGEROUS DIY: Never tell users to dismantle complex appliances or fix gas lines.\n'
        '5. STAY ON TOPIC: If asked about non-service topics, politely decline and steer back to home services.\n'
        '6. IDENTIFY NEED FOR PRO: If the problem likely requires a professional, conclude your message with the specific category tag, '
        'e.g., [CATEGORY: Plumber]. Categories: Plumber, Electrician, AC Mechanic, Carpenter, Painter, Appliance Repair, Mason, Other.'
        '\n\nAlways include: "This is general guidance and does not replace a professional inspection."'
      ),
    );

    _descriptionHelperModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a service-request description assistant for ServiceBridge AI. '
        'Rewrite the customer\'s rough description into a clear, concise, and professional description for a local service worker. '
        '\n\nRULES:\n'
        '1. Preserve ONLY information provided by the customer. Do NOT invent facts, symptoms, appliance models, or diagnoses.\n'
        '2. Do NOT provide repair instructions or DIY tips.\n'
        '3. Keep the description professional and easy for a worker to understand.\n'
        '4. If the description contains dangerous situations (sparks, smoke, gas, fire), preserve that safety information exactly.\n'
        '5. Return ONLY the rewritten description text.'
      ),
    );

    _reviewAnalysisModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a professional review-analysis assistant for ServiceBridge AI. '
        'Your goal is to analyze a customer\'s review text and provide structured insights. '
        '\n\nRULES:\n'
        '1. Analyze ONLY the supplied review text. Do NOT invent facts or infer personal information.\n'
        '2. If a metric is not mentioned, return "Not mentioned".\n'
        '3. Sentiment must be: Positive, Neutral, or Negative.\n'
        '4. Quality metrics (serviceQuality, professionalism, punctuality, communication) must be: Excellent, Good, Average, Poor, or Not mentioned.\n'
        '\n\nOUTPUT FORMAT:\n'
        'You must return ONLY a JSON object with this exact structure:\n'
        '{\n'
        '  "sentiment": "Positive | Neutral | Negative",\n'
        '  "summary": "Short professional summary",\n'
        '  "strengths": ["list of strengths"],\n'
        '  "concerns": ["list of concerns"],\n'
        '  "serviceQuality": "Excellent | Good | Average | Poor | Not mentioned",\n'
        '  "professionalism": "Excellent | Good | Average | Poor | Not mentioned",\n'
        '  "punctuality": "Excellent | Good | Average | Poor | Not mentioned",\n'
        '  "communication": "Excellent | Good | Average | Poor | Not mentioned"\n'
        '}'
      ),
    );

    _historyInsightsModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a smart home-maintenance analyst for ServiceBridge AI. '
        'Your goal is to analyze a customer\'s service request history and identify patterns or provide preventive maintenance advice.'
        '\n\nRULES:\n'
        '1. Analyze ONLY the provided list of service categories and problem descriptions. Do NOT invent history.\n'
        '2. If there are fewer than 2-3 requests, state that there is insufficient data for a reliable pattern analysis.\n'
        '3. Focus on identifies recurring issue types (e.g., "Frequent plumbing issues") or maintenance trends.\n'
        '4. Provide safe, general preventive suggestions based on the identified patterns.\n'
        '5. Do NOT diagnose specific new problems.\n'
        '6. Return ONLY the required JSON structure.'
        '\n\nOUTPUT FORMAT:\n'
        '{\n'
        '  "summary": "Short executive summary of the history",\n'
        '  "frequentService": "The most common service category or \'Not enough data\'",\n'
        '  "repeatedIssue": "A pattern of similar problems or \'Not enough data\'",\n'
        '  "maintenanceSuggestion": "Safe preventive tip related to history",\n'
        '  "confidence": "High | Medium | Low"\n'
        '}'
      ),
    );

    _workerPerformanceModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(
        'You are a professional business growth analyst for workers in the ServiceBridge AI app. '
        'Your goal is to analyze a worker\'s job history and customer reviews to provide structured performance insights.'
        '\n\nRULES:\n'
        '1. Analyze ONLY the provided anonymized job history and customer review snippets. Do NOT invent data.\n'
        '2. Focus on identifies professional strengths, areas for improvement, and actionable business tips.\n'
        '3. Sentiment must be: Positive, Neutral, or Negative based on reviews.\n'
        '4. If there is insufficient data (fewer than 3 jobs or 2 reviews), clearly indicate that in the summary.\n'
        '5. Maintain a professional, encouraging, yet honest tone.\n'
        '6. Return ONLY the required JSON structure.'
        '\n\nOUTPUT FORMAT:\n'
        '{\n'
        '  "performanceSummary": "A concise overview of the worker\'s performance trends",\n'
        '  "topSkillsIdentified": ["list of 2-3 skills frequently praised or demonstrated"],\n'
        '  "improvementAreas": ["list of 1-2 specific professional areas to work on"],\n'
        '  "customerSentiment": "Positive | Neutral | Negative",\n'
        '  "businessTip": "One practical tip to grow their business or improve service"\n'
        '}'
      ),
    );
  }

  Future<AiIssueAnalysisModel> analyzeIssue(String description, {Uint8List? imageBytes}) async {
    if (description.trim().isEmpty && imageBytes == null) {
      throw 'Please provide a description or a photo of the problem.';
    }

    return _retryOnTempFailure(() async {
      try {
        final List<Part> contentParts = [];
        
        if (description.trim().isNotEmpty) {
          contentParts.add(TextPart(description));
        }
        
        if (imageBytes != null) {
          contentParts.add(InlineDataPart('image/jpeg', imageBytes));
        }

        final response = await _model.generateContent([Content.multi(contentParts)]);
        final text = response.text;
        
        if (text == null) {
          throw 'The AI could not generate a response. Please try again.';
        }

        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        
        if (jsonStart == -1 || jsonEnd == 0) {
          throw 'Invalid AI response format.';
        }

        final jsonString = text.substring(jsonStart, jsonEnd);
        final decoded = json.decode(jsonString);
        
        return AiIssueAnalysisModel.fromJson(decoded);
      } catch (e) {
        if (e is FormatException) {
          throw 'Failed to parse diagnostic data. Please try again.';
        }
        rethrow;
      }
    });
  }

  Future<List<AiWorkerRecommendation>> recommendWorkers({
    required String problemDescription,
    required String serviceCategory,
    String? customerLocation,
    required List<WorkerModel> candidates,
  }) async {
    if (candidates.isEmpty) return [];

    // Privacy Layer: Anonymize worker IDs and strip PII (Names, Phones, Emails)
    final Map<String, String> anonymizationMap = {}; // TempID -> RealUID
    final List<String> anonymizedWorkerData = [];

    for (int i = 0; i < candidates.length; i++) {
      final worker = candidates[i];
      final tempId = 'Candidate_${i + 1}';
      anonymizationMap[tempId] = worker.id;

      anonymizedWorkerData.add(
        'ID: $tempId, Service: ${worker.service}, Rating: ${worker.rating} (${worker.reviews} reviews), '
        'Experience: ${worker.experienceYears} years, Skills: ${worker.skills.join(", ")}, '
        'Available: ${worker.isAvailable}, Profile: ${worker.description}'
      );
    }

    return _retryOnTempFailure<List<AiWorkerRecommendation>>(() async {
      final candidateListStr = anonymizedWorkerData.join('\n---\n');

      final prompt = 'Customer Problem: $problemDescription\n'
          'Requested Category: $serviceCategory\n\n'
          'Worker Candidates:\n$candidateListStr';

      final response = await _recommendationModel.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) return [];

      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) return [];

      final jsonString = text.substring(jsonStart, jsonEnd);
      final decoded = json.decode(jsonString);
      final recommendationResponse = AiWorkerRecommendationResponse.fromJson(decoded);

      // Verification Layer: Map anonymized IDs back to real UIDs and validate existence
      final List<AiWorkerRecommendation> verifiedRecommendations = [];
      
      for (var rec in recommendationResponse.recommendations) {
        final realUid = anonymizationMap[rec.workerId];
        if (realUid != null) {
          // Sanitize the reason: replace Candidate_X with professional terms
          var sanitizedReason = rec.reason.replaceAll(RegExp(r'Candidate_\d+'), 'This professional');
          // Also handle cases like "Candidate_1 is..." -> "This worker is..."
          sanitizedReason = sanitizedReason.replaceAll('This professional is', 'This worker is');

          verifiedRecommendations.add(AiWorkerRecommendation(
            workerId: realUid,
            reason: sanitizedReason,
            matchScore: rec.matchScore,
          ));
        }
      }

      return verifiedRecommendations;
    }).catchError((_) => <AiWorkerRecommendation>[]);
  }

  Future<Map<String, dynamic>> getAssistantResponse(List<Content> history) async {
    return _retryOnTempFailure(() async {
      // history contains the current user message at the end.
      // startChat expects the history of PREVIOUS messages.
      final pastHistory = history.sublist(0, history.length - 1);
      final currentMessage = history.last.parts.first as TextPart;

      final chat = _assistantModel.startChat(history: pastHistory);
      final response = await chat.sendMessage(Content.text(currentMessage.text));
      final text = response.text;

      if (text == null) throw 'Empty AI response';

      String? category;
      final categoryMatch = RegExp(r'\[CATEGORY:\s*([^\]]+)\]').firstMatch(text);
      if (categoryMatch != null) {
        category = categoryMatch.group(1)?.trim();
      }

      var cleanText = text.replaceFirst(RegExp(r'\[CATEGORY:\s*[^\]]+\]'), '').trim();
      
      // Clean up markdown characters for plain text display
      cleanText = cleanText
          .replaceAll(RegExp(r'\*\*'), '')
          .replaceAll(RegExp(r'###\s*'), '')
          .replaceAll(RegExp(r'##\s*'), '')
          .replaceAll(RegExp(r'#\s*'), '')
          .replaceAll(RegExp(r'---\s*'), '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n');

      return {
        'text': cleanText,
        'category': category,
      };
    });
  }

  /// Improves a rough request description into a professional one using AI.
  Future<String> improveServiceRequestDescription(String description) async {
    if (description.trim().isEmpty) {
      throw 'Please enter a description first.';
    }

    return _retryOnTempFailure(() async {
      final response = await _descriptionHelperModel.generateContent([Content.text(description)]);
      final text = response.text;
      
      if (text == null || text.trim().isEmpty) {
        throw 'The AI could not improve the description. Please try again.';
      }

      return text.trim();
    });
  }

  /// Analyzes a worker review to extract structured insights using AI.
  Future<AiReviewAnalysisModel> analyzeWorkerReview(String reviewText) async {
    if (reviewText.trim().isEmpty) {
      throw 'No review text provided for analysis.';
    }

    return _retryOnTempFailure(() async {
      final response = await _reviewAnalysisModel.generateContent([Content.text(reviewText)]);
      final text = response.text;

      if (text == null) {
        throw 'The AI could not generate an analysis. Please try again.';
      }

      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw 'Invalid AI response format.';
      }

      final jsonString = text.substring(jsonStart, jsonEnd);
      final decoded = json.decode(jsonString);
      
      return AiReviewAnalysisModel.fromJson(decoded);
    });
  }

  /// Generates smart insights based on customer service history.
  Future<AiServiceHistoryInsightsModel> generateServiceHistoryInsights(List<Map<String, String>> historyData) async {
    if (historyData.isEmpty) {
      return AiServiceHistoryInsightsModel(
        summary: 'No service history found.',
        frequentService: 'Not enough data',
        repeatedIssue: 'Not enough data',
        maintenanceSuggestion: 'Start by requesting your first service!',
        confidence: 'Low',
      );
    }

    return _retryOnTempFailure(() async {
      final historyStr = historyData.map((h) => 
        'Category: ${h['category']}, Description: ${h['description']}'
      ).join('\n---\n');

      final response = await _historyInsightsModel.generateContent([Content.text(historyStr)]);
      final text = response.text;

      if (text == null) {
        throw 'The AI could not generate insights. Please try again.';
      }

      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw 'Invalid AI response format.';
      }

      final jsonString = text.substring(jsonStart, jsonEnd);
      final decoded = json.decode(jsonString);
      
      return AiServiceHistoryInsightsModel.fromJson(decoded);
    });
  }

  /// Generates performance insights for workers based on their job history and reviews.
  Future<AiWorkerPerformanceModel> generateWorkerPerformanceInsights({
    required List<Map<String, dynamic>> jobHistory,
    required List<String> reviews,
  }) async {
    if (jobHistory.length < 3 && reviews.length < 2) {
      return AiWorkerPerformanceModel(
        performanceSummary: 'Insufficient data to generate a complete business analysis. Complete more jobs and receive more reviews to unlock full insights!',
        topSkillsIdentified: [],
        improvementAreas: [],
        customerSentiment: 'Neutral',
        businessTip: 'Aim to complete at least 3 jobs and receive 2 reviews for a detailed analysis.',
      );
    }

    return _retryOnTempFailure(() async {
      final jobHistoryStr = jobHistory.map((j) => 
        'Category: ${j['category']}, Status: ${j['status']}, Description: ${j['description']}'
      ).join('\n---\n');

      final reviewsStr = reviews.join('\n---\n');

      final prompt = 'Job History:\n$jobHistoryStr\n\nCustomer Reviews:\n$reviewsStr';

      final response = await _workerPerformanceModel.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) {
        throw 'The AI could not generate performance insights. Please try again.';
      }

      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw 'Invalid AI response format.';
      }

      final jsonString = text.substring(jsonStart, jsonEnd);
      final decoded = json.decode(jsonString);
      
      return AiWorkerPerformanceModel.fromJson(decoded);
    });
  }

  /// Helper to retry temporary failures like RESOURCE_EXHAUSTED or network errors.
  Future<T> _retryOnTempFailure<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await action();
      } catch (e) {
        final errorStr = e.toString();
        bool isRetryable = errorStr.contains('RESOURCE_EXHAUSTED') || 
                          errorStr.contains('network') ||
                          errorStr.contains('Deadline Exceeded') ||
                          errorStr.contains('Service Unavailable');
        
        if (isRetryable && attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
        
        throw _mapErrorToUserFriendlyMessage(e);
      }
    }
  }

  String _mapErrorToUserFriendlyMessage(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    
    if (errorStr.contains('resource_exhausted')) {
      return 'AI service is temporarily busy. Please try again in a moment.';
    } else if (errorStr.contains('network') || errorStr.contains('failed to host lookup')) {
      return 'Connection error. Please check your internet and try again.';
    } else if (errorStr.contains('deadline exceeded') || errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorStr.contains('format-exception') || errorStr.contains('invalid ai response')) {
      return 'Received an unexpected response from AI. Please try again.';
    }
    
    return 'The AI service is unavailable. Please try again later.';
  }
}
