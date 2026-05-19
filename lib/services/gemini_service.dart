import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/analysis_result.dart';
import 'news_service.dart';

class GeminiService {
  Future<AnalysisResult> analyze({
    required String productName,
    required Map<String, dynamic> warehouse,
    required List<NewsArticle> newsArticles,
    required Map<String, dynamic> sales,
    required Map<String, dynamic> supplier,
    required Map<String, dynamic> complaints,
    required Map<String, dynamic> contradictionsResult,
    required Map<String, dynamic> constraintResult,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : dotenv.env['GEMINI_KEY'] ?? '';

    if (apiKey.isEmpty) {
      // Fallback if key is missing
      return AnalysisResult.getMockAnalysis();
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    // Format news articles list
    String newsSignalList = newsArticles.isEmpty
        ? 'No news articles found.'
        : newsArticles.map((a) => '- ${a.title} (${a.source})').join('\n');

    // Build prompt
    final prompt = '''
You are a revenue protection AI for a Pakistani retail business.
Analyze this threat data and return ONLY valid JSON (no markdown, no explanation).

Product: $productName
Warehouse stock: ${warehouse['units']} units | Freshness: ${warehouse['staleness_flag']} | Last updated: ${warehouse['last_updated']}
News signals:
$newsSignalList
Demand trend: +${(sales['demand_spike_percent'] as double).toStringAsFixed(0)}% spike | Status: ${sales['trend_status']}
Supplier reliability score: ${supplier['reliability_score']} | Delay alert: ${supplier['delay_flag']}
Customer complaints today: ${complaints['count']} vs baseline 6/day | Severity: ${complaints['severity']}
Contradictions found: ${(contradictionsResult['contradictions'] as List).length} | Confidence: ${contradictionsResult['confidence_score']}
Trusted sources: ${(contradictionsResult['trusted_sources'] as List).join(', ')}
Budget constraint: PKR 500,000 | Adjusted Order Cost: PKR ${constraintResult['adjusted_cost']} (Adjusted Quantity: ${constraintResult['adjusted_quantity']})

Return this exact JSON structure:
{
  "risk_score": number (0-100),
  "revenue_at_risk_pkr": number,
  "action_chain": [
    {"step":1, "title":string, "cost_pkr":number, "priority":"CRITICAL"|"HIGH"|"MEDIUM"|"LOW", "deadline":string, "detail":string},
    {"step":2, "title":string, "cost_pkr":number, "priority":"CRITICAL"|"HIGH"|"MEDIUM"|"LOW", "deadline":string, "detail":string},
    {"step":3, "title":string, "cost_pkr":number, "priority":"CRITICAL"|"HIGH"|"MEDIUM"|"LOW", "deadline":string, "detail":string},
    {"step":4, "title":string, "cost_pkr":number, "priority":"CRITICAL"|"HIGH"|"MEDIUM"|"LOW", "deadline":string, "detail":string},
    {"step":5, "title":string, "cost_pkr":number, "priority":"CRITICAL"|"HIGH"|"MEDIUM"|"LOW", "deadline":string, "detail":string}
  ],
  "before": {"stockout_risk_percent": number, "revenue_at_risk_pkr": number},
  "after":  {"stockout_risk_percent": number, "revenue_at_risk_pkr": number},
  "revenue_protected_pkr": number
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 429) {
        // Failure 3 recovery: Gemini 429 rate limit -> return _getMockAnalysis() hardcoded result
        return AnalysisResult.getMockAnalysis();
      }

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final candidateText = decodedResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            decodedResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (candidateText != null) {
          final cleanedJson = _cleanJsonString(candidateText.toString());
          final Map<String, dynamic> resultJson = jsonDecode(cleanedJson);
          return AnalysisResult.fromJson(resultJson);
        }
      }

      return AnalysisResult.getMockAnalysis();
    } catch (_) {
      return AnalysisResult.getMockAnalysis();
    }
  }

  // Strip markdown blocks if returned by the LLM
  String _cleanJsonString(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      // Find start of json if marked
      final jsonStart = cleaned.indexOf('json');
      if (jsonStart != -1 && jsonStart < 10) {
        cleaned = cleaned.substring(jsonStart + 4);
      } else {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }
    return cleaned.trim();
  }
}
