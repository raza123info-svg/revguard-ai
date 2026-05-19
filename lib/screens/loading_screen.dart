// lib/screens/loading_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/agent_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String productName;
  final String selectedCity;
  final double budgetPkr;
  final String? warehouseContent;
  final String? salesContent;
  final String? supplierContent;
  final String? complaintsContent;

  const LoadingScreen({
    super.key,
    required this.productName,
    required this.selectedCity,
    required this.budgetPkr,
    this.warehouseContent,
    this.salesContent,
    this.supplierContent,
    this.complaintsContent,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  StreamSubscription<AgentProgressState>? _subscription;
  List<AgentStepProgress> _steps = [];
  String? _errorMessage;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  void _startPipeline() {
    final stream = AgentService.runPipeline(
      productName: widget.productName,
      selectedCity: widget.selectedCity,
      budgetPkr: widget.budgetPkr,
      warehouseContent: widget.warehouseContent,
      salesContent: widget.salesContent,
      supplierContent: widget.supplierContent,
      complaintsContent: widget.complaintsContent,
    );

    _subscription = stream.listen(
      (state) {
        setState(() {
          _steps = state.steps;
          _errorMessage = state.errorMessage;
        });

        // Navigate when completed
        if (state.result != null && !_isNavigating) {
          _isNavigating = true;
          // Slight delay to let the user see the final step complete
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    result: state.result!,
                    productName: widget.productName,
                    enteredBudgetPkr: widget.budgetPkr,
                  ),
                ),
              );
            }
          });
        }
      },
      onError: (err) {
        setState(() {
          _errorMessage = err.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Total elapsed time sum
    final totalElapsed = _steps.fold<Duration>(
      Duration.zero,
      (sum, step) => sum + step.elapsedTime,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Spinning Agent Aura
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.withOpacity(0.8)),
                        strokeWidth: 3,
                      ),
                    ),
                    const Icon(
                      Icons.radar,
                      color: Colors.cyanAccent,
                      size: 36,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PIPELINE AGENT RUNNING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total Time: ${(totalElapsed.inMilliseconds / 1000).toStringAsFixed(2)}s',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Steps timeline list
              Expanded(
                child: _steps.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: _steps.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final step = _steps[index];
                          return _buildStepRow(step);
                        },
                      ),
              ),

              // Error display or warning
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(AgentStepProgress step) {
    Color textColor = Colors.white60;
    Widget leadingWidget = const Icon(Icons.circle_outlined, color: Colors.white24, size: 20);

    switch (step.status) {
      case ToolStatus.pending:
        textColor = Colors.white30;
        leadingWidget = const Icon(Icons.circle_outlined, color: Colors.white24, size: 20);
        break;
      case ToolStatus.running:
        textColor = Colors.cyanAccent;
        leadingWidget = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
        );
        break;
      case ToolStatus.completed:
        textColor = Colors.white;
        leadingWidget = const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20);
        break;
      case ToolStatus.skipped:
        textColor = Colors.white38;
        leadingWidget = const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20);
        break;
      case ToolStatus.error:
        textColor = Colors.redAccent;
        leadingWidget = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: step.status == ToolStatus.running
            ? Colors.cyan.withOpacity(0.05)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.status == ToolStatus.running
              ? Colors.cyan.withOpacity(0.2)
              : Colors.white.withOpacity(0.02),
        ),
      ),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: step.status == ToolStatus.running ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (step.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.detail!,
                    style: TextStyle(
                      color: step.status == ToolStatus.error 
                          ? Colors.redAccent.withOpacity(0.7) 
                          : Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (step.status != ToolStatus.pending && step.status != ToolStatus.skipped)
            Text(
              '${(step.elapsedTime.inMilliseconds / 1000).toStringAsFixed(2)}s',
              style: TextStyle(
                color: step.status == ToolStatus.running ? Colors.cyanAccent : Colors.white30,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (step.status == ToolStatus.skipped)
            const Text(
              'SKIPPED',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
