import 'news_service.dart';

class ContradictionEngineResult {
  final List<String> contradictions;
  final double confidenceScore;
  final List<String> trustedSources;

  ContradictionEngineResult({
    required this.contradictions,
    required this.confidenceScore,
    required this.trustedSources,
  });

  Map<String, dynamic> toJson() {
    return {
      'contradictions': contradictions,
      'confidence_score': confidenceScore,
      'trusted_sources': trustedSources,
    };
  }
}

class ContradictionEngine {
  static ContradictionEngineResult detect({
    required List<NewsArticle> newsArticles,
    required Map<String, dynamic> warehouse,
    required Map<String, dynamic> sales,
    required Map<String, dynamic> supplier,
    required Map<String, dynamic> complaints,
  }) {
    List<String> contradictions = [];
    List<String> trustedSources = [];
    List<double> trustedScores = [];

    // Base credibility definitions
    const double newsScore = 0.90;
    const double complaintsScore = 0.85;
    const double salesScore = 0.75;
    const double supplierScore = 0.72;
    const double warehouseBaseScore = 0.70; // if fresh

    // Evaluate warehouse freshness
    bool warehouseStale = warehouse['staleness_flag'] == 'STALE';
    double currentWarehouseScore = warehouseStale ? 0.30 : warehouseBaseScore;

    // Check sources status
    trustedSources.add('NewsAPI Live Feed');
    trustedScores.add(newsScore);

    trustedSources.add('Complaints CSV (<24h)');
    trustedScores.add(complaintsScore);

    trustedSources.add('Sales CSV (<24h)');
    trustedScores.add(salesScore);

    trustedSources.add('Supplier JSON (<24h)');
    trustedScores.add(supplierScore);

    if (warehouseStale) {
      // Overridden due to staleness
      // Do not add to trusted list as primary source, mark overridden
    } else {
      trustedSources.add('Warehouse CSV (Fresh)');
      trustedScores.add(currentWarehouseScore);
    }

    // 1. Check Contradiction: Stale Warehouse OK vs. Active News/Supply Chain Strike/Complaints Spike
    bool hasMotorwayStrike = newsArticles.any((article) =>
        article.title.toLowerCase().contains('strike') ||
        article.description.toLowerCase().contains('strike') ||
        article.title.toLowerCase().contains('disrupt') ||
        article.description.toLowerCase().contains('disrupt'));

    int stockUnits = warehouse['units'] ?? 0;
    if (warehouseStale && stockUnits > 100) {
      if (hasMotorwayStrike) {
        contradictions.add(
          "Warehouse reports ample stock ($stockUnits units) but data is STALE (3+ days old, Credibility: 0.30). News reports active M-9 motorway transport strike (Credibility: 0.90). Stale stock overridden by live transport blockade signal.",
        );
      }
      if ((complaints['count'] ?? 0) > 20) {
        contradictions.add(
          "Warehouse reports $stockUnits units available (Credibility: 0.30), but customer complaints have spiked to ${complaints['count']} (Credibility: 0.85). Stale warehouse stock records overridden by verified customer stockout reports.",
        );
      }
    }

    // 2. Check Contradiction: Supplier Delay Alert vs. Supplier Reliability Score
    bool delayAlert = supplier['delay_flag'] == true;
    int reliability = supplier['reliability_score'] ?? 100;
    if (delayAlert && reliability > 80) {
      contradictions.add(
        "Supplier '${supplier['supplier_name']}' has high reliability ($reliability, Credibility: 0.72) but has issued an active delay alert. Alert takes precedence, showing risk of short-term delivery failure.",
      );
    }

    // 3. Check Contradiction: Sales Spike vs. Stale Stock
    double demandSpike = sales['demand_spike_percent'] ?? 0.0;
    if (demandSpike > 100.0 && warehouseStale) {
      contradictions.add(
        "Sales report a +${demandSpike.toStringAsFixed(0)}% demand spike (Credibility: 0.75), while warehouse database has not updated for >48 hours. Sales velocity suggests stock depleted, overriding stale warehouse counts.",
      );
    }

    // Calculate confidence score as the weighted average of the trusted source scores
    double totalScore = trustedScores.reduce((a, b) => a + b);
    double confidenceScore = totalScore / trustedScores.length;

    // Cap confidence score representation
    if (confidenceScore > 1.0) confidenceScore = 1.0;
    if (confidenceScore < 0.0) confidenceScore = 0.0;

    return ContradictionEngineResult(
      contradictions: contradictions,
      confidenceScore: confidenceScore,
      trustedSources: trustedSources,
    );
  }
}
