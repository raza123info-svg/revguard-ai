import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsArticle {
  final String title;
  final String description;
  final String publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      source: (json['source'] is Map) ? (json['source']['name'] ?? '') : (json['source'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'publishedAt': publishedAt,
      'source': source,
    };
  }
}

class NewsService {
  static List<NewsArticle> getMockArticles() {
    return [
      NewsArticle(
        title: "M-9 motorway strike disrupts Karachi supply",
        description: "A major sit-in on the Karachi-Hyderabad M-9 motorway by transport associations has completely halted container movement, causing supply delays across multiple sectors.",
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        source: "Dawn",
      ),
      NewsArticle(
        title: "Transport workers extend strike",
        description: "The transport workers union in Sindh has announced an indefinite extension of their strike until their demands for lower toll rates and security are met.",
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        source: "The News",
      ),
      NewsArticle(
        title: "Rice prices surge 34% in Karachi",
        description: "Local markets report a 34% spike in essential grain prices, including Basmati rice, as wholesale markets run out of inventory due to highway gridlocks.",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        source: "Business Recorder",
      ),
    ];
  }

  Future<List<NewsArticle>> fetch(String productName, {String? customApiKey}) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : dotenv.env['NEWSAPI_KEY'] ?? '';

    if (apiKey.isEmpty) {
      // Fallback if no API key is set
      return getMockArticles();
    }

    final query = Uri.encodeComponent('$productName supply chain Pakistan');
    final url = 'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          final articlesList = data['articles'] as List;
          if (articlesList.isEmpty) {
            return getMockArticles();
          }
          return articlesList.map((a) => NewsArticle.fromJson(a)).toList();
        }
      }
      return getMockArticles();
    } catch (e) {
      // Return mock articles on failure
      return getMockArticles();
    }
  }
}
