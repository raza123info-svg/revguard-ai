// lib/models/analysis_result.dart

class AnalysisResult {
  final double overallRiskScore;
  final double overallRevenueAtRiskPkr;
  final List<CityAnalysis> cityAnalysis;
  final List<ActionStep> actionChain;
  final ImpactMetrics before;
  final ImpactMetrics after;
  final double revenueProtectedPkr;
  final List<String> dataSourcesUsed;

  AnalysisResult({
    required this.overallRiskScore,
    required this.overallRevenueAtRiskPkr,
    required this.cityAnalysis,
    required this.actionChain,
    required this.before,
    required this.after,
    required this.revenueProtectedPkr,
    required this.dataSourcesUsed,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers as double
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    var cityAnalysisList = <CityAnalysis>[];
    if (json['city_analysis'] != null && json['city_analysis'] is List) {
      for (var item in json['city_analysis']) {
        if (item is Map<String, dynamic>) {
          cityAnalysisList.add(CityAnalysis.fromJson(item));
        }
      }
    }

    var actionChainList = <ActionStep>[];
    if (json['action_chain'] != null && json['action_chain'] is List) {
      for (var item in json['action_chain']) {
        if (item is Map<String, dynamic>) {
          actionChainList.add(ActionStep.fromJson(item));
        }
      }
    }

    List<String> sources = [];
    if (json['data_sources_used'] != null && json['data_sources_used'] is List) {
      sources = List<String>.from(json['data_sources_used'].map((e) => e.toString()));
    }

    return AnalysisResult(
      overallRiskScore: toDouble(json['overall_risk_score']),
      overallRevenueAtRiskPkr: toDouble(json['overall_revenue_at_risk_pkr']),
      cityAnalysis: cityAnalysisList,
      actionChain: actionChainList,
      before: ImpactMetrics.fromJson(json['before'] ?? {}),
      after: ImpactMetrics.fromJson(json['after'] ?? {}),
      revenueProtectedPkr: toDouble(json['revenue_protected_pkr']),
      dataSourcesUsed: sources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_risk_score': overallRiskScore,
      'overall_revenue_at_risk_pkr': overallRevenueAtRiskPkr,
      'city_analysis': cityAnalysis.map((e) => e.toJson()).toList(),
      'action_chain': actionChain.map((e) => e.toJson()).toList(),
      'before': before.toJson(),
      'after': after.toJson(),
      'revenue_protected_pkr': revenueProtectedPkr,
      'data_sources_used': dataSourcesUsed,
    };
  }
}

class CityAnalysis {
  final String city;
  final double riskScore;
  final double revenueAtRiskPkr;
  final String keyThreat;
  final String recommendedAction;

  CityAnalysis({
    required this.city,
    required this.riskScore,
    required this.revenueAtRiskPkr,
    required this.keyThreat,
    required this.recommendedAction,
  });

  factory CityAnalysis.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CityAnalysis(
      city: json['city']?.toString() ?? 'Unknown',
      riskScore: toDouble(json['risk_score']),
      revenueAtRiskPkr: toDouble(json['revenue_at_risk_pkr']),
      keyThreat: json['key_threat']?.toString() ?? '',
      recommendedAction: json['recommended_action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'risk_score': riskScore,
      'revenue_at_risk_pkr': revenueAtRiskPkr,
      'key_threat': keyThreat,
      'recommended_action': recommendedAction,
    };
  }
}

class ActionStep {
  final int step;
  final String title;
  final double costPkr;
  final String priority;
  final String deadline;
  final String detail;
  final String city;

  ActionStep({
    required this.step,
    required this.title,
    required this.costPkr,
    required this.priority,
    required this.deadline,
    required this.detail,
    required this.city,
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return ActionStep(
      step: toInt(json['step']),
      title: json['title']?.toString() ?? '',
      costPkr: toDouble(json['cost_pkr']),
      priority: json['priority']?.toString() ?? 'MEDIUM',
      deadline: json['deadline']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      city: json['city']?.toString() ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'title': title,
      'cost_pkr': costPkr,
      'priority': priority,
      'deadline': deadline,
      'detail': detail,
      'city': city,
    };
  }
}

class ImpactMetrics {
  final double stockoutRiskPercent;
  final double revenueAtRiskPkr;

  ImpactMetrics({
    required this.stockoutRiskPercent,
    required this.revenueAtRiskPkr,
  });

  factory ImpactMetrics.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return ImpactMetrics(
      stockoutRiskPercent: toDouble(json['stockout_risk_percent']),
      revenueAtRiskPkr: toDouble(json['revenue_at_risk_pkr']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockout_risk_percent': stockoutRiskPercent,
      'revenue_at_risk_pkr': revenueAtRiskPkr,
    };
  }
}
