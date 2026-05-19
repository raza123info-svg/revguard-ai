class AnalysisResult {
  final int riskScore;
  final double revenueAtRiskPkr;
  final List<ActionStep> actionChain;
  final StockState before;
  final StockState after;
  final double revenueProtectedPkr;

  AnalysisResult({
    required this.riskScore,
    required this.revenueAtRiskPkr,
    required this.actionChain,
    required this.before,
    required this.after,
    required this.revenueProtectedPkr,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    var actionList = json['action_chain'] as List? ?? [];
    List<ActionStep> parsedSteps = actionList.map((item) => ActionStep.fromJson(item)).toList();

    return AnalysisResult(
      riskScore: json['risk_score'] ?? 0,
      revenueAtRiskPkr: (json['revenue_at_risk_pkr'] ?? 0).toDouble(),
      actionChain: parsedSteps,
      before: StockState.fromJson(json['before'] ?? {}),
      after: StockState.fromJson(json['after'] ?? {}),
      revenueProtectedPkr: (json['revenue_protected_pkr'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_score': riskScore,
      'revenue_at_risk_pkr': revenueAtRiskPkr,
      'action_chain': actionChain.map((step) => step.toJson()).toList(),
      'before': before.toJson(),
      'after': after.toJson(),
      'revenue_protected_pkr': revenueProtectedPkr,
    };
  }

  static AnalysisResult getMockAnalysis() {
    return AnalysisResult(
      riskScore: 85,
      revenueAtRiskPkr: 2400000.0,
      actionChain: [
        ActionStep(
          step: 1,
          title: 'Emergency order 800 units from backup supplier',
          costPkr: 180000.0,
          priority: 'CRITICAL',
          deadline: 'Today 4hrs',
          detail: 'Place alternative purchase order immediately to offset current motorway delays.',
        ),
        ActionStep(
          step: 2,
          title: 'Activate rationing: 2 units per customer',
          costPkr: 0.0,
          priority: 'HIGH',
          deadline: 'Immediate',
          detail: 'Limit purchase volumes to safeguard existing floor stock from bulk hoarding.',
        ),
        ActionStep(
          step: 3,
          title: 'Alert 12 Karachi store managers',
          costPkr: 5000.0,
          priority: 'HIGH',
          deadline: '1 hour',
          detail: 'Initiate inventory check, prioritize high-value customers, and coordinate local updates.',
        ),
        ActionStep(
          step: 4,
          title: 'Renegotiate primary supplier contract',
          costPkr: 15000.0,
          priority: 'MEDIUM',
          deadline: '7 days',
          detail: 'Include clear penalty clauses for transit failures and delays exceeding 48 hours.',
        ),
        ActionStep(
          step: 5,
          title: 'Monitor M-9 motorway every 6 hours',
          costPkr: 2000.0,
          priority: 'LOW',
          deadline: 'Ongoing',
          detail: 'Set up real-time text alert subscriptions and dispatch reports for logistics teams.',
        ),
      ],
      before: StockState(
        stockoutRiskPercent: 95.0,
        revenueAtRiskPkr: 2400000.0,
      ),
      after: StockState(
        stockoutRiskPercent: 12.0,
        revenueAtRiskPkr: 180000.0,
      ),
      revenueProtectedPkr: 2220000.0,
    );
  }
}

class ActionStep {
  final int step;
  final String title;
  final double costPkr;
  final String priority; // 'CRITICAL'|'HIGH'|'MEDIUM'|'LOW'
  final String deadline;
  final String detail;

  ActionStep({
    required this.step,
    required this.title,
    required this.costPkr,
    required this.priority,
    required this.deadline,
    required this.detail,
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    return ActionStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      costPkr: (json['cost_pkr'] ?? 0).toDouble(),
      priority: json['priority'] ?? 'MEDIUM',
      deadline: json['deadline'] ?? '',
      detail: json['detail'] ?? '',
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
    };
  }
}

class StockState {
  final double stockoutRiskPercent;
  final double revenueAtRiskPkr;

  StockState({
    required this.stockoutRiskPercent,
    required this.revenueAtRiskPkr,
  });

  factory StockState.fromJson(Map<String, dynamic> json) {
    return StockState(
      stockoutRiskPercent: (json['stockout_risk_percent'] ?? 0).toDouble(),
      revenueAtRiskPkr: (json['revenue_at_risk_pkr'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockout_risk_percent': stockoutRiskPercent,
      'revenue_at_risk_pkr': revenueAtRiskPkr,
    };
  }
}
