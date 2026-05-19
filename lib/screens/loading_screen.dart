import 'dart:async';
import 'package:flutter/material.dart';
import '../services/agent_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String productName;
  final String? warehouseCsv;
  final String? salesCsv;
  final String? supplierJson;
  final String? complaintsCsv;
  final String geminiKey;
  final String newsApiKey;

  const LoadingScreen({
    super.key,
    required this.productName,
    this.warehouseCsv,
    this.salesCsv,
    this.supplierJson,
    this.complaintsCsv,
    required this.geminiKey,
    required this.newsApiKey,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  final AgentService _agentService = AgentService();
  StreamSubscription<AgentStepProgress>? _subscription;

  // Track progress of the 8 steps
  final List<String> _stepTitles = [
    "Tool 1: NewsAPI Fetch",
    "Tool 2: Warehouse Stock Parser",
    "Tool 3: Sales Demand Analyser",
    "Tool 4: Supplier Reliability Reader",
    "Tool 5: Complaints Spike Processor",
    "Tool 6: Contradiction Engine Validation",
    "Tool 7: Constraint Engine Budget Check",
    "Tool 8: Gemini 1.5 Flash Risk Reasoning",
  ];

  final List<String> _defaultMessages = [
    "📡 Waiting for NewsAPI fetch...",
    "📦 Waiting for warehouse stock levels...",
    "📈 Waiting for sales demand trends...",
    "🏭 Waiting for supplier reliability score...",
    "📣 Waiting for complaints spike data...",
    "⚡ Waiting for ContradictionEngine cross-validation...",
    "✅ Waiting for ConstraintEngine budget validation...",
    "🤖 Waiting for Gemini 1.5 Flash risk reasoning...",
  ];

  final List<bool> _completedSteps = List.generate(8, (_) => false);
  final List<bool> _activeSteps = List.generate(8, (_) => false);
  final List<String> _liveMessages = [];
  final List<Duration> _stepDurations = List.generate(8, (_) => Duration.zero);

  double _totalProgress = 0.0;
  String _consoleOutput = "";
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _liveMessages.addAll(_defaultMessages);

    // Initialize scanner animation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    _startPipeline();
  }

  void _startPipeline() {
    final stream = _agentService.runPipeline(
      productName: widget.productName,
      warehouseCsv: widget.warehouseCsv,
      salesCsv: widget.salesCsv,
      supplierJson: widget.supplierJson,
      complaintsCsv: widget.complaintsCsv,
      customGeminiKey: widget.geminiKey,
      customNewsApiKey: widget.newsApiKey,
    );

    // Watch stream and update ui
    _subscription = stream.listen(
      (progress) {
        int idx = progress.toolNumber - 1;
        setState(() {
          // Set progress percentage
          _totalProgress = progress.toolNumber / 8.0;

          // Update active vs completed states
          for (int i = 0; i < 8; i++) {
            _activeSteps[i] = (i == idx && !progress.isCompleted);
          }

          _liveMessages[idx] = progress.message;
          _stepDurations[idx] = progress.elapsed;

          if (progress.isCompleted) {
            _completedSteps[idx] = true;
            _consoleOutput += "[SYSTEM LOG] T${progress.toolNumber} COMPLETED: ${progress.message} (${progress.elapsed.inMilliseconds}ms)\n";
          } else {
            _consoleOutput += "[SYSTEM LOG] T${progress.toolNumber} INITIATED: ${progress.message}\n";
          }
        });

        // If Tool 8 completes, we get the final result payload
        if (progress.toolNumber == 8 && progress.isCompleted && progress.data != null) {
          final result = progress.data!['result'] as AgentPipelineResult;
          _navigateToResult(result);
        }
      },
      onError: (e) {
        setState(() {
          _consoleOutput += "[CRITICAL ERROR] Pipeline aborted: $e\n";
        });
      },
    );
  }

  void _navigateToResult(AgentPipelineResult result) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: result,
              productName: widget.productName,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopScanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLoadingHeader(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildStepsList()),
                    const SizedBox(height: 24),
                    _buildConsoleLogs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopScanner() {
    return AnimatedBuilder(
      animation: _scannerAnimation,
      builder: (context, child) {
        return Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFA855F7)],
              stops: [
                _scannerAnimation.value - 0.2 < 0 ? 0.0 : _scannerAnimation.value - 0.2,
                _scannerAnimation.value,
                _scannerAnimation.value + 0.2 > 1 ? 1.0 : _scannerAnimation.value + 0.2,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "REVENUE PROTECTION ENGINE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFFA855F7),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Analyzing ${widget.productName}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _totalProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFF1E1E28),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress: ${(_totalProgress * 100).toStringAsFixed(0)}%",
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Orchestrating 8 Agents...",
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return ListView.builder(
      itemCount: 8,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        bool isDone = _completedSteps[index];
        bool isActive = _activeSteps[index];
        Duration duration = _stepDurations[index];

        Color itemColor = Colors.grey.withOpacity(0.5);
        if (isActive) {
          itemColor = const Color(0xFF06B6D4);
        } else if (isDone) {
          itemColor = Colors.white;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF13222A)
                : (isDone ? const Color(0xFF13131A) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF06B6D4).withOpacity(0.4)
                  : (isDone ? const Color(0xFF22222E) : Colors.transparent),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: isDone
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                    : (isActive
                        ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF06B6D4)))
                        : const Icon(Icons.radio_button_off, color: Colors.grey, size: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        color: itemColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _liveMessages[index],
                      style: TextStyle(
                        color: isActive ? const Color(0xFF81E6D9) : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone && duration != Duration.zero)
                Text(
                  "${(duration.inMilliseconds / 1000.0).toStringAsFixed(2)}s",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsoleLogs() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF050507),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E26), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AGENT LOG CONSOLE",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(Icons.terminal_rounded, size: 10, color: Colors.grey),
            ],
          ),
          const Divider(color: Color(0xFF1E1E26), height: 12),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              physics: const BouncingScrollPhysics(),
              child: Text(
                _consoleOutput.isEmpty ? "Initializing log pipe...\n" : _consoleOutput,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontFamily: 'monospace',
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
