class ConstraintEngineResult {
  final String budgetStatus; // 'WITHIN_LIMIT' | 'ADJUSTED' | 'EXCEEDED'
  final double originalQuantity;
  final double adjustedQuantity;
  final double originalCost;
  final double adjustedCost;
  final String feasibility;

  ConstraintEngineResult({
    required this.budgetStatus,
    required this.originalQuantity,
    required this.adjustedQuantity,
    required this.originalCost,
    required this.adjustedCost,
    required this.feasibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget_status': budgetStatus,
      'original_quantity': originalQuantity,
      'adjusted_quantity': adjustedQuantity,
      'original_cost': originalCost,
      'adjusted_cost': adjustedCost,
      'feasibility': feasibility,
    };
  }
}

class ConstraintEngine {
  static const double budgetLimit = 500000.0;

  static ConstraintEngineResult check({
    required double quantity,
    required double unitPrice,
  }) {
    double originalCost = quantity * unitPrice;
    double adjustedQuantity = quantity;
    double adjustedCost = originalCost;
    String status = 'WITHIN_LIMIT';

    if (originalCost > budgetLimit) {
      status = 'ADJUSTED';
      int loopCount = 0;
      // Safety limit of 200 iterations to prevent infinite loops
      while (adjustedCost > budgetLimit && loopCount < 200) {
        adjustedQuantity = adjustedQuantity * 0.95;
        adjustedCost = adjustedQuantity * unitPrice;
        loopCount++;
      }
    }

    String feasibility = 'APPROVED';
    if (adjustedCost > budgetLimit) {
      feasibility = 'FAILED_BUDGET_CONSTRAINT';
      status = 'EXCEEDED';
    }

    return ConstraintEngineResult(
      budgetStatus: status,
      originalQuantity: quantity,
      adjustedQuantity: double.parse(adjustedQuantity.toStringAsFixed(1)),
      originalCost: originalCost,
      adjustedCost: double.parse(adjustedCost.toStringAsFixed(1)),
      feasibility: feasibility,
    );
  }
}
