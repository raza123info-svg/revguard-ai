// lib/services/contradiction_engine.dart

class ContradictionEngine {
  /// Detects contradictions and calculates confidence scores city-by-city
  static Map<String, dynamic> detect({
    required Map<String, dynamic>? warehouseResult,
    required Map<String, dynamic>? salesResult,
    required dynamic supplierResult,
    required Map<String, dynamic>? complaintsResult,
    required List<dynamic>? newsResult,
    required List<String> cities,
  }) {
    List<Map<String, dynamic>> contradictions = [];
    Map<String, double> cityConfidence = {};
    List<String> trustedSources = [];

    // 1. Establish source presence
    bool hasWarehouse = warehouseResult != null;
    bool hasSales = salesResult != null;
    bool hasSupplier = supplierResult != null;
    bool hasComplaints = complaintsResult != null;
    bool hasNews = newsResult != null && newsResult.isNotEmpty;

    // Determine staleness of warehouse
    bool isWarehouseStale = false;
    if (hasWarehouse) {
      isWarehouseStale = warehouseResult['staleness_flag'] == true;
    }

    // 2. Assign dynamic credibility weights per source
    double wWarehouse = hasWarehouse ? (isWarehouseStale ? 0.4 : 0.85) : 0.0;
    double wSales = hasSales ? 0.90 : 0.0;
    double wSupplier = hasSupplier ? 0.75 : 0.0;
    double wComplaints = hasComplaints ? 0.80 : 0.0;
    double wNews = hasNews ? 0.65 : 0.0;

    // Identify trusted sources (credibility weight >= 0.7)
    if (hasSales) trustedSources.add('sales.csv');
    if (hasWarehouse && !isWarehouseStale) trustedSources.add('warehouse.csv');
    if (hasComplaints) trustedSources.add('complaints.csv');
    if (hasSupplier) trustedSources.add('supplier.json');

    // 3. Perform city-by-city validation
    for (String city in cities) {
      double cityBaseConfidence = 100.0;
      List<String> activeSourcesInCity = [];
      
      // Extract data for the specific city
      final warehouseList = hasWarehouse && warehouseResult['city_data'] != null
          ? (warehouseResult['city_data'][city] as List<dynamic>?) ?? []
          : [];
      final salesList = hasSales && salesResult['city_data'] != null
          ? (salesResult['city_data'][city] as List<dynamic>?) ?? []
          : [];
      final complaintsList = hasComplaints && complaintsResult['city_data'] != null
          ? (complaintsResult['city_data'][city] as List<dynamic>?) ?? []
          : [];

      double totalWeight = 0.0;
      int activeSourceCount = 0;

      if (warehouseList.isNotEmpty) {
        activeSourcesInCity.add('Warehouse');
        totalWeight += wWarehouse;
        activeSourceCount++;
      }
      if (salesList.isNotEmpty) {
        activeSourcesInCity.add('Sales');
        totalWeight += wSales;
        activeSourceCount++;
      }
      if (complaintsList.isNotEmpty) {
        activeSourcesInCity.add('Complaints');
        totalWeight += wComplaints;
        activeSourceCount++;
      }
      if (hasSupplier) {
        totalWeight += wSupplier;
        activeSourceCount++;
      }
      if (hasNews) {
        totalWeight += wNews;
        activeSourceCount++;
      }

      double avgWeight = activeSourceCount > 0 ? (totalWeight / activeSourceCount) : 1.0;
      cityBaseConfidence = cityBaseConfidence * avgWeight;

      // Deduct from confidence if warehouse data is stale
      if (warehouseList.isNotEmpty && isWarehouseStale) {
        cityBaseConfidence -= 15.0;
        contradictions.add({
          'city': city,
          'type': 'Stale Data Warning',
          'description': 'Warehouse data for $city is older than 30 days. Stock figures may not reflect current physical status.',
          'severity': 'MEDIUM',
          'sources': ['warehouse.csv'],
        });
      }

      // Check Contradiction A: High warehouse stock vs customer stockout complaints
      if (warehouseList.isNotEmpty && complaintsList.isNotEmpty) {
        // Calculate total stock reported in warehouse for this city
        double totalStock = 0;
        for (var row in warehouseList) {
          final stockVal = row['stock'] ?? row['quantity'] ?? row['inventory'] ?? 0;
          totalStock += double.tryParse(stockVal.toString()) ?? 0;
        }

        // Count stockout-related complaints
        int stockoutComplaintsCount = 0;
        for (var row in complaintsList) {
          final text = (row['complaint'] ?? row['text'] ?? row['description'] ?? '').toString().toLowerCase();
          if (text.contains('stockout') ||
              text.contains('out of stock') ||
              text.contains('no stock') ||
              text.contains('empty shelf') ||
              text.contains('unavailable')) {
            stockoutComplaintsCount++;
          }
        }

        if (totalStock > 100 && stockoutComplaintsCount > 0) {
          double deduction = 15.0 + (stockoutComplaintsCount * 5.0);
          if (deduction > 40.0) deduction = 40.0;
          cityBaseConfidence -= deduction;

          contradictions.add({
            'city': city,
            'type': 'Stock Inconsistency',
            'description': 'Warehouse reports healthy stock level ($totalStock units) in $city, but $stockoutComplaintsCount customer complaints report items are out of stock.',
            'severity': 'HIGH',
            'sources': ['warehouse.csv', 'complaints.csv'],
          });
        }
      }

      // Check Contradiction B: High sales volume reported but zero stock in warehouse
      if (warehouseList.isNotEmpty && salesList.isNotEmpty) {
        double totalStock = 0;
        for (var row in warehouseList) {
          final stockVal = row['stock'] ?? row['quantity'] ?? row['inventory'] ?? 0;
          totalStock += double.tryParse(stockVal.toString()) ?? 0;
        }

        double totalSales = 0;
        for (var row in salesList) {
          final salesVal = row['sales'] ?? row['units_sold'] ?? row['quantity'] ?? 0;
          totalSales += double.tryParse(salesVal.toString()) ?? 0;
        }

        if (totalSales > 10 && totalStock == 0) {
          cityBaseConfidence -= 20.0;
          contradictions.add({
            'city': city,
            'type': 'Sales-Stock Mismatch',
            'description': 'Sales data shows sales of $totalSales units in $city, but warehouse reports 0 units in stock.',
            'severity': 'HIGH',
            'sources': ['warehouse.csv', 'sales.csv'],
          });
        }
      }

      // Keep confidence in valid 0-100 range
      if (cityBaseConfidence < 0.0) cityBaseConfidence = 0.0;
      if (cityBaseConfidence > 100.0) cityBaseConfidence = 100.0;

      // If no sources present for city, or only 1 source, it has less verification, but we keep its confidence
      if (activeSourcesInCity.isEmpty) {
        cityConfidence[city] = 0.0;
      } else {
        cityConfidence[city] = double.parse(cityBaseConfidence.toStringAsFixed(1));
      }
    }

    // 4. Compute overall confidence score (average of cities)
    double overallConfidence = 0.0;
    if (cityConfidence.isNotEmpty) {
      double sum = 0.0;
      int count = 0;
      cityConfidence.forEach((city, score) {
        sum += score;
        count++;
      });
      overallConfidence = sum / count;
    } else {
      // Default to 100 if no cities, or 80 if files exist but no city column
      overallConfidence = 80.0;
    }

    return {
      'contradictions': contradictions,
      'confidence_score': double.parse(overallConfidence.toStringAsFixed(1)),
      'trusted_sources': trustedSources,
      'city_confidence': cityConfidence,
    };
  }
}
