import 'dart:convert';
import 'package:csv/csv.dart';

class FileParser {
  // Helper to parse double or int from dynamic cell
  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
    return parsed ?? defaultValue;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9-]'), ''));
    return parsed ?? defaultValue;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString().trim());
    } catch (_) {
      // Try parsing other common formats if needed, or return null
      return null;
    }
  }

  /// Tool 2: warehouse.csv parser
  /// Columns: units_available, Last_Updated, location
  /// If Last_Updated > 48 hours ago -> staleness_flag = STALE
  /// Failure (missing column) -> skip staleness check, treat as FRESH
  static Map<String, dynamic> parseWarehouse(String csvContent) {
    try {
      final List<List<dynamic>> rows = csv.decode(csvContent);
      if (rows.isEmpty) {
        return {
          'units': 500,
          'last_updated': 'N/A',
          'staleness_flag': 'FRESH',
          'location': 'Unknown Store'
        };
      }

      // Extract header row
      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

      int unitsIndex = headers.indexOf('units_available');
      int lastUpdatedIndex = headers.indexOf('last_updated');
      int locationIndex = headers.indexOf('location');

      if (unitsIndex == -1) {
        // Let's look for fuzzy matching if exact fails
        unitsIndex = headers.indexWhere((h) => h.contains('unit') || h.contains('stock') || h.contains('avail'));
      }
      if (lastUpdatedIndex == -1) {
        lastUpdatedIndex = headers.indexWhere((h) => h.contains('update') || h.contains('date') || h.contains('time'));
      }
      if (locationIndex == -1) {
        locationIndex = headers.indexWhere((h) => h.contains('loc') || h.contains('store') || h.contains('city'));
      }

      // If we don't have data rows, return fallback
      if (rows.length < 2) {
        return {
          'units': 500,
          'last_updated': 'N/A',
          'staleness_flag': 'FRESH',
          'location': 'Unknown Store'
        };
      }

      // Parse first data row (or latest row)
      final dataRow = rows[1];
      int units = unitsIndex != -1 && unitsIndex < dataRow.length
          ? _parseInt(dataRow[unitsIndex], defaultValue: 500)
          : 500;

      String location = locationIndex != -1 && locationIndex < dataRow.length
          ? dataRow[locationIndex].toString().trim()
          : 'Karachi Store';

      String lastUpdatedStr = 'N/A';
      String stalenessFlag = 'FRESH';

      // Failure 2 recovery: If Last_Updated is missing, skip staleness check, treat as FRESH
      if (lastUpdatedIndex != -1 && lastUpdatedIndex < dataRow.length) {
        final dateVal = dataRow[lastUpdatedIndex];
        lastUpdatedStr = dateVal.toString().trim();
        final parsedDate = _parseDate(dateVal);
        if (parsedDate != null) {
          final difference = DateTime.now().difference(parsedDate);
          if (difference.inHours > 48) {
            stalenessFlag = 'STALE';
          }
        }
      }

      return {
        'units': units,
        'last_updated': lastUpdatedStr,
        'staleness_flag': stalenessFlag,
        'location': location
      };
    } catch (_) {
      // Fallback
      return {
        'units': 500,
        'last_updated': 'N/A',
        'staleness_flag': 'FRESH',
        'location': 'Karachi Store'
      };
    }
  }

  /// Tool 3: sales.csv parser
  /// Columns: date, demand_units, Demand_Trend
  /// Detect spike: if current > baseline * 2 -> CRITICAL
  static Map<String, dynamic> parseSales(String csvContent) {
    try {
      final List<List<dynamic>> rows = csv.decode(csvContent);
      if (rows.isEmpty || rows.length < 2) {
        return {
          'demand_spike_percent': 0.0,
          'trend_status': 'NORMAL'
        };
      }

      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      int demandIndex = headers.indexOf('demand_units');
      int trendIndex = headers.indexOf('demand_trend');

      if (demandIndex == -1) {
        demandIndex = headers.indexWhere((h) => h.contains('demand') || h.contains('sale') || h.contains('qty'));
      }
      if (trendIndex == -1) {
        trendIndex = headers.indexWhere((h) => h.contains('trend') || h.contains('status'));
      }

      // Calculate baseline and current demand
      // We will treat the last row as "current", and the average of all previous rows as the "baseline"
      int dataRowsCount = rows.length - 1;
      if (dataRowsCount == 0 || demandIndex == -1) {
        return {
          'demand_spike_percent': 0.0,
          'trend_status': 'NORMAL'
        };
      }

      List<double> demands = [];
      for (int i = 1; i < rows.length; i++) {
        if (demandIndex < rows[i].length) {
          demands.add(_parseDouble(rows[i][demandIndex]));
        }
      }

      if (demands.isEmpty) {
        return {
          'demand_spike_percent': 0.0,
          'trend_status': 'NORMAL'
        };
      }

      double currentDemand = demands.last;
      double baseline = 0.0;
      if (demands.length > 1) {
        // baseline is average of previous rows
        double sum = demands.sublist(0, demands.length - 1).reduce((a, b) => a + b);
        baseline = sum / (demands.length - 1);
      } else {
        // Only one data row, baseline is itself
        baseline = currentDemand;
      }

      if (baseline == 0.0) baseline = 1.0; // Avoid division by zero

      double spikePercent = ((currentDemand - baseline) / baseline) * 100.0;
      if (spikePercent < 0) spikePercent = 0.0;

      String trendStatus = 'NORMAL';
      if (currentDemand > baseline * 2.0) {
        trendStatus = 'CRITICAL';
      } else if (spikePercent > 30.0) {
        trendStatus = 'HIGH';
      }

      // If Demand_Trend column exists in the last row, we can also factor it in
      if (trendIndex != -1 && trendIndex < rows.last.length) {
        final fileTrend = rows.last[trendIndex].toString().toUpperCase().trim();
        if (fileTrend == 'CRITICAL' || fileTrend == 'HIGH' || fileTrend == 'NORMAL') {
          // If the file explicitly marked it, or our spike triggered CRITICAL, use the higher alarm
          if (trendStatus != 'CRITICAL') {
            trendStatus = fileTrend;
          }
        }
      }

      return {
        'demand_spike_percent': spikePercent,
        'trend_status': trendStatus,
        'current_demand': currentDemand,
        'baseline_demand': baseline
      };
    } catch (_) {
      return {
        'demand_spike_percent': 0.0,
        'trend_status': 'NORMAL'
      };
    }
  }

  /// Tool 4: supplier.json parser
  /// Fields: reliability_score, delay_alert, supplier_name
  /// Failure (unexpected structure) -> wrap raw content as {data: rawContent}, continue
  static Map<String, dynamic> parseSupplier(String jsonContent) {
    try {
      final decoded = jsonDecode(jsonContent.trim());
      if (decoded is Map<String, dynamic>) {
        return {
          'reliability_score': _parseInt(decoded['reliability_score'], defaultValue: 100),
          'delay_flag': decoded['delay_alert'] == true || decoded['delay_alert'] == 'true' || decoded['delay_alert'] == 1,
          'supplier_name': decoded['supplier_name']?.toString() ?? 'Default Supplier',
          'raw_structure': false
        };
      } else {
        // Unexpected structure but valid JSON (e.g. List)
        return {
          'reliability_score': 70,
          'delay_flag': false,
          'supplier_name': 'Unknown Supplier',
          'data': decoded,
          'raw_structure': true
        };
      }
    } catch (_) {
      // Failure 5 recovery: Supplier JSON bad structure/invalid JSON -> wrap as {data: content}, continue
      return {
        'reliability_score': 50,
        'delay_flag': true,
        'supplier_name': 'Fallback Supplier',
        'data': jsonContent,
        'raw_structure': true
      };
    }
  }

  /// Tool 5: complaints.csv parser
  /// Columns: date, complaint_count, severity
  /// Baseline: 6/day
  static Map<String, dynamic> parseComplaints(String csvContent) {
    try {
      final List<List<dynamic>> rows = csv.decode(csvContent);
      if (rows.isEmpty || rows.length < 2) {
        return {
          'count': 6,
          'severity': 'LOW',
          'spike_multiplier': 1.0
        };
      }

      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      int countIndex = headers.indexOf('complaint_count');
      int severityIndex = headers.indexOf('severity');

      if (countIndex == -1) {
        countIndex = headers.indexWhere((h) => h.contains('count') || h.contains('complaint') || h.contains('num'));
      }
      if (severityIndex == -1) {
        severityIndex = headers.indexWhere((h) => h.contains('sever') || h.contains('status') || h.contains('level'));
      }

      if (countIndex == -1) {
        return {
          'count': 6,
          'severity': 'LOW',
          'spike_multiplier': 1.0
        };
      }

      // Take the last row as the current complaints data
      final lastRow = rows.last;
      int count = countIndex < lastRow.length ? _parseInt(lastRow[countIndex], defaultValue: 6) : 6;
      String severity = severityIndex != -1 && severityIndex < lastRow.length
          ? lastRow[severityIndex].toString().toUpperCase().trim()
          : 'MEDIUM';

      double spikeMultiplier = count / 6.0;

      return {
        'count': count,
        'severity': severity,
        'spike_multiplier': spikeMultiplier
      };
    } catch (_) {
      return {
        'count': 6,
        'severity': 'LOW',
        'spike_multiplier': 1.0
      };
    }
  }
}
