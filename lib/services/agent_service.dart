// lib/services/agent_service.dart

import 'dart:async';
import 'file_parser.dart';
import 'contradiction_engine.dart';
import 'constraint_engine.dart';
import 'news_service.dart';
import 'gemini_service.dart';
import '../models/analysis_result.dart';

enum ToolStatus { pending, running, completed, skipped, error }

class AgentStepProgress {
  final int index;
  final String title;
  final ToolStatus status;
  final Duration elapsedTime;
  final String? detail;

  AgentStepProgress({
    required this.index,
    required this.title,
    required this.status,
    required this.elapsedTime,
    this.detail,
  });

  AgentStepProgress copyWith({
    ToolStatus? status,
    Duration? elapsedTime,
    String? detail,
  }) {
    return AgentStepProgress(
      index: index,
      title: title,
      status: status ?? this.status,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      detail: detail ?? this.detail,
    );
  }
}

class AgentProgressState {
  final List<AgentStepProgress> steps;
  final AnalysisResult? result;
  final String? errorMessage;

  AgentProgressState({
    required this.steps,
    this.result,
    this.errorMessage,
  });
}

class AgentService {
  /// Orchestrates the 8-tool agent pipeline and yields step updates.
  static Stream<AgentProgressState> runPipeline({
    required String productName,
    required String selectedCity,
    required double budgetPkr,
    required String? warehouseContent,
    required String? salesContent,
    required String? supplierContent,
    required String? complaintsContent,
  }) async* {
    // Initialise steps list
    final steps = [
      AgentStepProgress(index: 1, title: '📡 Fetching Pakistan supply chain news...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 2, title: '📦 Parsing warehouse data by city...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 3, title: '📈 Analyzing city-wise sales trends...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 4, title: '🏭 Reading supplier reliability data...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 5, title: '📣 Processing complaints by city...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 6, title: '⚡ Cross-validating city data sources...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 7, title: '✅ Validating PKR budget constraints...', status: ToolStatus.pending, elapsedTime: Duration.zero),
      AgentStepProgress(index: 8, title: '🤖 Gemini AI city-wise deep analysis...', status: ToolStatus.pending, elapsedTime: Duration.zero),
    ];

    yield AgentProgressState(steps: List.from(steps));

    // Helper to update and emit step progress
    Future<void> updateStep(int idx, ToolStatus status, Duration duration, {String? detail}) async {
      steps[idx - 1] = steps[idx - 1].copyWith(status: status, elapsedTime: duration, detail: detail);
    }

    // Accumulators for results
    List<Map<String, dynamic>> newsArticles = [];
    Map<String, dynamic>? warehouseResult;
    Map<String, dynamic>? salesResult;
    dynamic supplierResult;
    Map<String, dynamic>? complaintsResult;
    Map<String, dynamic> contradictionResult = {};
    Map<String, dynamic> constraintResult = {};
    AnalysisResult? finalAnalysis;

    // We will collect cities dynamically
    final Set<String> citySet = {selectedCity};

    // --- TOOL 1: NEWS SERVICE ---
    {
      final stopwatch = Stopwatch()..start();
      steps[0] = steps[0].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      try {
        newsArticles = await NewsService.fetch(productName, selectedCity);
        // Extract any cities mentioned in news if possible
        for (var art in newsArticles) {
          final c = art['city_mentioned']?.toString() ?? '';
          if (c.isNotEmpty && c != 'National' && c != 'Multiple') {
            citySet.add(c);
          }
        }
        stopwatch.stop();
        await updateStep(1, ToolStatus.completed, stopwatch.elapsed, detail: '${newsArticles.length} articles found');
      } catch (e) {
        stopwatch.stop();
        await updateStep(1, ToolStatus.error, stopwatch.elapsed, detail: 'Failed but fell back to mock news');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth animation delay
    }

    // --- TOOL 2: PARSE WAREHOUSE ---
    {
      final stopwatch = Stopwatch()..start();
      steps[1] = steps[1].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      if (warehouseContent != null && warehouseContent.trim().isNotEmpty) {
        warehouseResult = FileParser.parseWarehouse(warehouseContent, selectedCity);
        if (warehouseResult != null) {
          final Map<String, dynamic> cityData = warehouseResult['city_data'];
          citySet.addAll(cityData.keys);
          final bool stale = warehouseResult['staleness_flag'] == true;
          stopwatch.stop();
          await updateStep(
            2, 
            ToolStatus.completed, 
            stopwatch.elapsed,
            detail: 'Parsed ${cityData.keys.length} cities. Freshness: ${stale ? "STALE" : "FRESH"}'
          );
        } else {
          stopwatch.stop();
          await updateStep(2, ToolStatus.error, stopwatch.elapsed, detail: 'Parsing failed');
        }
      } else {
        stopwatch.stop();
        await updateStep(2, ToolStatus.skipped, stopwatch.elapsed, detail: 'MISSING - File not uploaded');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 3: PARSE SALES ---
    {
      final stopwatch = Stopwatch()..start();
      steps[2] = steps[2].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      if (salesContent != null && salesContent.trim().isNotEmpty) {
        salesResult = FileParser.parseSales(salesContent, selectedCity);
        if (salesResult != null) {
          final Map<String, dynamic> cityData = salesResult['city_data'];
          citySet.addAll(cityData.keys);
          stopwatch.stop();
          await updateStep(3, ToolStatus.completed, stopwatch.elapsed, detail: 'Parsed sales trends for ${cityData.keys.length} cities');
        } else {
          stopwatch.stop();
          await updateStep(3, ToolStatus.error, stopwatch.elapsed, detail: 'Parsing failed');
        }
      } else {
        stopwatch.stop();
        await updateStep(3, ToolStatus.skipped, stopwatch.elapsed, detail: 'MISSING - File not uploaded');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 4: PARSE SUPPLIER ---
    {
      final stopwatch = Stopwatch()..start();
      steps[3] = steps[3].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      if (supplierContent != null && supplierContent.trim().isNotEmpty) {
        supplierResult = FileParser.parseSupplier(supplierContent);
        stopwatch.stop();
        await updateStep(4, ToolStatus.completed, stopwatch.elapsed, detail: 'Parsed supplier reliability data');
      } else {
        stopwatch.stop();
        await updateStep(4, ToolStatus.skipped, stopwatch.elapsed, detail: 'MISSING - File not uploaded');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 5: PARSE COMPLAINTS ---
    {
      final stopwatch = Stopwatch()..start();
      steps[4] = steps[4].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      if (complaintsContent != null && complaintsContent.trim().isNotEmpty) {
        complaintsResult = FileParser.parseComplaints(complaintsContent, selectedCity);
        if (complaintsResult != null) {
          final Map<String, dynamic> cityData = complaintsResult['city_data'];
          citySet.addAll(cityData.keys);
          stopwatch.stop();
          await updateStep(5, ToolStatus.completed, stopwatch.elapsed, detail: 'Parsed complaints in ${cityData.keys.length} cities');
        } else {
          stopwatch.stop();
          await updateStep(5, ToolStatus.error, stopwatch.elapsed, detail: 'Parsing failed');
        }
      } else {
        stopwatch.stop();
        await updateStep(5, ToolStatus.skipped, stopwatch.elapsed, detail: 'MISSING - File not uploaded');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 6: CONTRADICTION ENGINE ---
    final List<String> sortedCities = citySet.where((c) => c.isNotEmpty).toList()..sort();
    {
      final stopwatch = Stopwatch()..start();
      steps[5] = steps[5].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      try {
        contradictionResult = ContradictionEngine.detect(
          warehouseResult: warehouseResult,
          salesResult: salesResult,
          supplierResult: supplierResult,
          complaintsResult: complaintsResult,
          newsResult: newsArticles,
          cities: sortedCities,
        );
        final List contradictions = contradictionResult['contradictions'];
        final double score = contradictionResult['confidence_score'];
        stopwatch.stop();
        await updateStep(
          6, 
          ToolStatus.completed, 
          stopwatch.elapsed,
          detail: '${contradictions.length} contradictions found. Confidence: $score%'
        );
      } catch (e) {
        stopwatch.stop();
        await updateStep(6, ToolStatus.error, stopwatch.elapsed, detail: 'Evaluation error');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 7: CONSTRAINT ENGINE ---
    {
      final stopwatch = Stopwatch()..start();
      steps[6] = steps[6].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      try {
        // Attempt to dynamically deduce initial quantities & prices from data if present
        double deducedQuantity = 0.0;
        double deducedPrice = 0.0;

        if (warehouseResult != null && warehouseResult['city_data'] != null) {
          final Map<String, dynamic> cityData = warehouseResult['city_data'];
          cityData.forEach((city, rows) {
            for (var row in rows) {
              final stockVal = row['stock'] ?? row['quantity'] ?? row['inventory'] ?? 0.0;
              deducedQuantity += double.tryParse(stockVal.toString()) ?? 0.0;
            }
          });
        }

        if (salesResult != null && salesResult['city_data'] != null) {
          final Map<String, dynamic> cityData = salesResult['city_data'];
          double totalRevenue = 0.0;
          double totalUnits = 0.0;
          cityData.forEach((city, rows) {
            for (var row in rows) {
              final unitsVal = row['units_sold'] ?? row['quantity'] ?? 0.0;
              final revVal = row['revenue'] ?? row['sales'] ?? 0.0;
              
              double units = double.tryParse(unitsVal.toString()) ?? 0.0;
              double rev = double.tryParse(revVal.toString()) ?? 0.0;
              
              totalUnits += units;
              totalRevenue += rev;
            }
          });
          if (totalUnits > 0) {
            deducedPrice = totalRevenue / totalUnits;
          }
        }

        // Fallbacks if data does not exist or values are zero (derived from budget dynamically)
        if (deducedQuantity == 0.0) {
          deducedQuantity = budgetPkr / 150.0; // Estimate quantity relative to budget
        }
        if (deducedPrice == 0.0) {
          deducedPrice = budgetPkr / deducedQuantity;
        }

        // Run budget constraint
        constraintResult = ConstraintEngine.check(
          userPkrBudget: budgetPkr,
          cities: sortedCities,
          initialQuantity: deducedQuantity,
          unitPrice: deducedPrice,
        );

        final String status = constraintResult['budget_status'];
        final String feasibility = constraintResult['feasibility'];
        stopwatch.stop();
        await updateStep(
          7, 
          ToolStatus.completed, 
          stopwatch.elapsed,
          detail: 'Status: $status ($feasibility)'
        );
      } catch (e) {
        stopwatch.stop();
        await updateStep(7, ToolStatus.error, stopwatch.elapsed, detail: 'Validation failed');
      }
      yield AgentProgressState(steps: List.from(steps));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // --- TOOL 8: GEMINI AI DEEP ANALYSIS ---
    {
      final stopwatch = Stopwatch()..start();
      steps[7] = steps[7].copyWith(status: ToolStatus.running);
      yield AgentProgressState(steps: List.from(steps));

      try {
        finalAnalysis = await GeminiService.analyze(
          productName: productName,
          cities: sortedCities,
          budgetPkr: budgetPkr,
          warehouseResult: warehouseResult,
          salesResult: salesResult,
          supplierResult: supplierResult,
          complaintsResult: complaintsResult,
          newsArticles: newsArticles,
          contradictionResult: contradictionResult,
        );
        stopwatch.stop();
        await updateStep(8, ToolStatus.completed, stopwatch.elapsed, detail: 'Insights ready');
      } catch (e) {
        stopwatch.stop();
        await updateStep(8, ToolStatus.error, stopwatch.elapsed, detail: 'API failure');
      }
      
      yield AgentProgressState(
        steps: List.from(steps),
        result: finalAnalysis,
        errorMessage: finalAnalysis == null ? 'AI Analysis execution failed.' : null,
      );
    }
  }
}
