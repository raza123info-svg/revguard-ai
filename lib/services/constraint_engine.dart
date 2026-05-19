// lib/services/constraint_engine.dart

class ConstraintEngine {
  /// Validates proposed orders against the user's PKR budget
  /// If proposed_order_cost > user_pkr_budget, loops and scales down quantity by 5% steps
  /// until cost satisfies the budget constraints.
  static Map<String, dynamic> check({
    required double userPkrBudget,
    required List<String> cities,
    required double initialQuantity,
    required double unitPrice,
  }) {
    // If no cities, treat as a single general scope
    final activeCities = cities.isEmpty ? ['General'] : cities;
    final int cityCount = activeCities.length;

    // Distribute budget equally across cities
    final double budgetLimitPerCity = userPkrBudget / cityCount;
    
    // Distribute initial quantity equally across cities
    final double initialQuantityPerCity = initialQuantity / cityCount;
    final double initialCostPerCity = initialQuantityPerCity * unitPrice;

    Map<String, Map<String, dynamic>> cityBreakdown = {};
    double totalAdjustedCost = 0.0;
    double totalAdjustedQuantity = 0.0;
    bool anyAdjusted = false;

    for (var city in activeCities) {
      double qty = initialQuantityPerCity;
      double cost = qty * unitPrice;
      bool adjusted = false;

      if (cost > budgetLimitPerCity) {
        adjusted = true;
        anyAdjusted = true;
        // Loop: scale quantity down by 5% until cost <= budgetLimitPerCity
        // Prevent infinite loops with a safety limit of 1000 iterations or qty > 0.001
        int iterations = 0;
        while (cost > budgetLimitPerCity && qty > 0.0001 && iterations < 1000) {
          qty = qty * 0.95;
          cost = qty * unitPrice;
          iterations++;
        }
      }

      totalAdjustedCost += cost;
      totalAdjustedQuantity += qty;

      cityBreakdown[city] = {
        'city_budget_limit': double.parse(budgetLimitPerCity.toStringAsFixed(2)),
        'initial_quantity': double.parse(initialQuantityPerCity.toStringAsFixed(2)),
        'initial_cost': double.parse(initialCostPerCity.toStringAsFixed(2)),
        'adjusted_quantity': double.parse(qty.toStringAsFixed(2)),
        'adjusted_cost': double.parse(cost.toStringAsFixed(2)),
        'status': adjusted ? 'ADJUSTED' : 'APPROVED',
      };
    }

    String feasibility = 'FEASIBLE';
    String budgetStatus = 'APPROVED';

    if (anyAdjusted) {
      feasibility = 'CONSTRAINED';
      budgetStatus = 'ADJUSTED';
    }

    if (totalAdjustedCost > userPkrBudget) {
      // Final guard, if for some floating point reason total exceeds budget
      feasibility = 'UNFEASIBLE';
      budgetStatus = 'EXCEEDED';
    }

    return {
      'budget_status': budgetStatus,
      'adjusted_quantity': double.parse(totalAdjustedQuantity.toStringAsFixed(2)),
      'adjusted_cost': double.parse(totalAdjustedCost.toStringAsFixed(2)),
      'feasibility': feasibility,
      'city_budget_breakdown': cityBreakdown,
    };
  }
}
