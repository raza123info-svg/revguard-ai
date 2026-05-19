// lib/services/file_parser.dart

import 'dart:convert';
import 'package:csv/csv.dart';

class FileParser {
  /// Detects city column index. Returns -1 if not found.
  static int _detectCityColumn(List<dynamic> headers) {
    for (int i = 0; i < headers.length; i++) {
      final name = headers[i].toString().toLowerCase().trim();
      if (name == 'city' ||
          name == 'location' ||
          name == 'town' ||
          name == 'district' ||
          name == 'region' ||
          name == 'source_city' ||
          name == 'destination_city') {
        return i;
      }
    }
    return -1;
  }

  /// Detects date column index. Returns -1 if not found.
  static int _detectDateColumn(List<dynamic> headers) {
    for (int i = 0; i < headers.length; i++) {
      final name = headers[i].toString().toLowerCase().trim();
      if (name.contains('date') ||
          name.contains('time') ||
          name.contains('timestamp') ||
          name.contains('updated') ||
          name.contains('created')) {
        return i;
      }
    }
    return -1;
  }

  /// Parses date string and compares with target date (2026-05-19) to check for staleness (> 30 days)
  static bool _checkStaleness(List<List<dynamic>> rows, int dateColIdx) {
    if (dateColIdx == -1 || rows.isEmpty) return false;
    
    DateTime targetDate = DateTime(2026, 5, 19);
    DateTime? latestDate;

    for (var row in rows) {
      if (row.length > dateColIdx) {
        final val = row[dateColIdx].toString().trim();
        final dt = _parseDateString(val);
        if (dt != null) {
          if (latestDate == null || dt.isAfter(latestDate)) {
            latestDate = dt;
          }
        }
      }
    }

    if (latestDate == null) return false;
    final diffDays = targetDate.difference(latestDate).inDays;
    return diffDays > 30; // Stale if more than 30 days old
  }

  static DateTime? _parseDateString(String val) {
    try {
      // Try standard Iso8601
      return DateTime.parse(val);
    } catch (_) {}

    // Try other formats manually
    // e.g. dd/MM/yyyy or MM/dd/yyyy
    final parts = val.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      int? p1 = int.tryParse(parts[0]);
      int? p2 = int.tryParse(parts[1]);
      int? p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        // If p3 is 4 digits, assume yyyy
        if (p3 > 1000) {
          // Check if p1 or p2 is month
          // Let's assume day/month/year by default, or try year/month/day
          if (p2 <= 12) {
            return DateTime(p3, p2, p1);
          } else if (p1 <= 12) {
            return DateTime(p3, p1, p2);
          }
        } else if (p1 > 1000) {
          // yyyy/MM/dd
          if (p2 <= 12) {
            return DateTime(p1, p2, p3);
          }
        }
      }
    }
    return null;
  }

  /// Parse warehouse.csv
  /// Returns Map with keys:
  /// - 'city_data': Map<String, List<Map<String, dynamic>>>
  /// - 'staleness_flag': bool
  /// - 'headers': List<String>
  static Map<String, dynamic>? parseWarehouse(String csvContent, String? selectedCity) {
    if (csvContent.trim().isEmpty) return null;
    try {
      final csvData = const CsvToListConverter().convert(csvContent);
      if (csvData.isEmpty) return null;

      final headers = csvData.first.map((e) => e.toString().trim()).toList();
      final rows = csvData.sublist(1);

      final cityColIdx = _detectCityColumn(headers);
      final dateColIdx = _detectDateColumn(headers);

      final staleness = _checkStaleness(rows, dateColIdx);

      final cityData = <String, List<Map<String, dynamic>>>{};

      for (var row in rows) {
        if (row.length < headers.length) continue;
        final city = (cityColIdx != -1 && row.length > cityColIdx)
            ? row[cityColIdx].toString().trim()
            : (selectedCity ?? 'Karachi');
        if (city.isEmpty) continue;

        final rowMap = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          rowMap[headers[i]] = row[i];
        }

        cityData.putIfAbsent(city, () => []).add(rowMap);
      }

      return {
        'city_data': cityData,
        'staleness_flag': staleness,
        'headers': headers,
      };
    } catch (e) {
      // Log or handle error, fallback to empty or null
      return null;
    }
  }

  /// Parse sales.csv
  /// Returns Map with keys:
  /// - 'city_data': Map<String, List<Map<String, dynamic>>>
  /// - 'headers': List<String>
  static Map<String, dynamic>? parseSales(String csvContent, String? selectedCity) {
    if (csvContent.trim().isEmpty) return null;
    try {
      final csvData = const CsvToListConverter().convert(csvContent);
      if (csvData.isEmpty) return null;

      final headers = csvData.first.map((e) => e.toString().trim()).toList();
      final rows = csvData.sublist(1);

      final cityColIdx = _detectCityColumn(headers);

      final cityData = <String, List<Map<String, dynamic>>>{};

      for (var row in rows) {
        if (row.length < headers.length) continue;
        final city = (cityColIdx != -1 && row.length > cityColIdx)
            ? row[cityColIdx].toString().trim()
            : (selectedCity ?? 'Karachi');
        if (city.isEmpty) continue;

        final rowMap = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          rowMap[headers[i]] = row[i];
        }

        cityData.putIfAbsent(city, () => []).add(rowMap);
      }

      return {
        'city_data': cityData,
        'headers': headers,
      };
    } catch (e) {
      return null;
    }
  }

  /// Parse complaints.csv
  /// Returns Map with keys:
  /// - 'city_data': Map<String, List<Map<String, dynamic>>>
  /// - 'headers': List<String>
  static Map<String, dynamic>? parseComplaints(String csvContent, String? selectedCity) {
    if (csvContent.trim().isEmpty) return null;
    try {
      final csvData = const CsvToListConverter().convert(csvContent);
      if (csvData.isEmpty) return null;

      final headers = csvData.first.map((e) => e.toString().trim()).toList();
      final rows = csvData.sublist(1);

      final cityColIdx = _detectCityColumn(headers);

      final cityData = <String, List<Map<String, dynamic>>>{};

      for (var row in rows) {
        if (row.length < headers.length) continue;
        final city = (cityColIdx != -1 && row.length > cityColIdx)
            ? row[cityColIdx].toString().trim()
            : (selectedCity ?? 'Karachi');
        if (city.isEmpty) continue;

        final rowMap = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          rowMap[headers[i]] = row[i];
        }

        cityData.putIfAbsent(city, () => []).add(rowMap);
      }

      return {
        'city_data': cityData,
        'headers': headers,
      };
    } catch (e) {
      return null;
    }
  }

  /// Parse supplier.json
  /// Returns parsed dynamic JSON object or wraps raw text if fails.
  static dynamic parseSupplier(String jsonContent) {
    if (jsonContent.trim().isEmpty) return null;
    try {
      final decoded = json.decode(jsonContent);
      return decoded;
    } catch (e) {
      // Failure -> wrap as {data: rawContent}
      return {'data': jsonContent};
    }
  }
}
