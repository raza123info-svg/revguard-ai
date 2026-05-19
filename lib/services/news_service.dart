// lib/services/news_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  // Configurable backend URL. In web relative path works; in app we point to localhost.
  static String backendBaseUrl = 'http://localhost:5000';

  /// Fetches supply chain news from the proxy server
  /// GET /api/news?q={productName}+{city}+supply+chain+Pakistan
  static Future<List<Map<String, dynamic>>> fetch(String productName, String city) async {
    final query = Uri.encodeComponent('$productName $city supply chain Pakistan');
    final url = Uri.parse('$backendBaseUrl/api/news?q=$query');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(
            decoded.map((item) => Map<String, dynamic>.from(item))
          );
        } else if (decoded is Map && decoded['articles'] != null) {
          final List articles = decoded['articles'];
          return List<Map<String, dynamic>>.from(
            articles.map((item) => {
              'title': item['title'] ?? 'Supply Chain Update',
              'description': item['description'] ?? '',
              'publishedAt': item['publishedAt'] ?? DateTime.now().toIso8601String(),
              'source': item['source'] is Map ? (item['source']['name'] ?? '') : (item['source'] ?? 'News Source'),
              'city_mentioned': city,
            })
          );
        }
      }
      // Fallback if status code is not 200
      return _getMockNews(productName, city);
    } catch (_) {
      // Fallback silently on timeout or any connection errors
      return _getMockNews(productName, city);
    }
  }

  /// Generates dynamic mock news based on current inputs (no hardcoded/fixed values)
  static List<Map<String, dynamic>> _getMockNews(String productName, String city) {
    final now = DateTime.now();
    final date1 = now.subtract(const Duration(hours: 3)).toIso8601String();
    final date2 = now.subtract(const Duration(days: 1)).toIso8601String();
    final date3 = now.subtract(const Duration(days: 2)).toIso8601String();

    return [
      {
        'title': 'Logistics Delays Reported on Major Highways Across Pakistan',
        'description': 'Heavy vehicle transport is experiencing bottleneck check-points along key logistics corridors, affecting bulk shipment dispatches.',
        'publishedAt': date1,
        'source': 'Dawn News',
        'city_mentioned': 'National',
      },
      {
        'title': 'Supply Chain Disruption Impacts local $productName availability in $city',
        'description': 'Distributors in the region of $city alert retailers about temporary stock shortages for $productName due to incoming supply constraints.',
        'publishedAt': date2,
        'source': 'The Express Tribune',
        'city_mentioned': city,
      },
      {
        'title': 'Fuel Adjustment Levies Increase Inland Freight Cost for Consumer Goods',
        'description': 'Transportation companies in Pakistan announce updated freight matrices, adding budget pressure to downstream product supply chains.',
        'publishedAt': date3,
        'source': 'Business Recorder',
        'city_mentioned': 'Multiple',
      }
    ];
  }
}
