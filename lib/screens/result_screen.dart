import 'dart:math';
import 'package:flutter/material.dart';
import '../services/agent_service.dart';

class ResultScreen extends StatefulWidget {
  final AgentPipelineResult result;
  final String productName;

  const ResultScreen({
    super.key,
    required this.result,
    required this.productName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPKR(double amount) {
    if (amount >= 1000000) {
      return "PKR ${(amount / 1000000.0).toStringAsFixed(2)}M";
    }
    return "PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "REVGUARD AGENT RESULTS",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFA855F7), letterSpacing: 1.5),
            ),
            Text(
              widget.productName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFA855F7),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          tabs: const [
            Tab(text: "OVERVIEW", icon: Icon(Icons.dashboard_rounded, size: 18)),
            Tab(text: "INSIGHTS", icon: Icon(Icons.analytics_rounded, size: 18)),
            Tab(text: "ACTIONS", icon: Icon(Icons.playlist_add_check_rounded, size: 18)),
            Tab(text: "IMPACT", icon: Icon(Icons.trending_up_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInsightsTab(),
          _buildActionsTab(),
          _buildImpactTab(),
        ],
      ),
    );
  }

  // ================= TAB 1: OVERVIEW =================
  Widget _buildOverviewTab() {
    final analysis = widget.result.analysis;
    final warehouse = widget.result.warehouse;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Meter Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22222E)),
            ),
            child: Column(
              children: [
                const Text(
                  "REVENUE THREAT RISK SCORE",
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: RiskArcPainter(score: analysis.riskScore.toDouble()),
                  ),
                ),
                Text(
                  "${analysis.riskScore}/100",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _getRiskColor(analysis.riskScore.toDouble()),
                  ),
                ),
                Text(
                  _getRiskLabel(analysis.riskScore.toDouble()),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _getRiskColor(analysis.riskScore.toDouble()).withOpacity(0.8),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Revenue Stats
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "REVENUE AT RISK",
                  value: _formatPKR(analysis.revenueAtRiskPkr),
                  color: Colors.redAccent,
                  icon: Icons.gpp_bad_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: "REVENUE PROTECTED",
                  value: _formatPKR(analysis.revenueProtectedPkr),
                  color: const Color(0xFF10B981),
                  icon: Icons.verified_user_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Freshness Badges Row
          const Text(
            "DATA FRESHNESS CHANNELS",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFreshnessBadge("NewsAPI", "TRUSTED", const Color(0xFF10B981)),
              _buildFreshnessBadge("Complaints", "TRUSTED", const Color(0xFF10B981)),
              _buildFreshnessBadge("Sales", "TRUSTED", const Color(0xFF10B981)),
              _buildFreshnessBadge("Supplier", "TRUSTED", const Color(0xFF10B981)),
              _buildFreshnessBadge(
                "Warehouse",
                warehouse['staleness_flag'] == 'STALE' ? "OVERRIDDEN" : "TRUSTED",
                warehouse['staleness_flag'] == 'STALE' ? Colors.orangeAccent : const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live News Cards
          const Text(
            "LIVE NEWS ALERTS (SUPPLY CHAIN)",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.result.newsArticles.length,
            itemBuilder: (context, index) {
              final article = widget.result.newsArticles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E1E26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.source.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _formatTimeAgo(article.publishedAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: INSIGHTS =================
  Widget _buildInsightsTab() {
    final contradiction = widget.result.contradiction;
    final warehouse = widget.result.warehouse;
    final sales = widget.result.sales;
    final supplier = widget.result.supplier;
    final complaints = widget.result.complaints;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22222E)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PIPELINE CONFIDENCE",
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${(contradiction.confidenceScore * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${contradiction.trustedSources.length} Trusted Channels Active",
                        style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: contradiction.confidenceScore,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFF1E1E28),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFA855F7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contradictions detail list
          const Text(
            "CONTRADICTION ANALYSIS",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          if (contradiction.contradictions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E19),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B3E2F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No contradictions found. All raw information streams align.",
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            ...contradiction.contradictions.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241818),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4C2A2A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 24),

          // Raw signals summary grid
          const Text(
            "RAW STREAM TELEMETRY GRID",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _buildRawSignalCard(
                title: "Warehouse Stock",
                value: "${warehouse['units']} units",
                sub: warehouse['staleness_flag'] == 'STALE' ? "Stale (>48h)" : "Fresh database",
                color: warehouse['staleness_flag'] == 'STALE' ? Colors.orangeAccent : const Color(0xFF10B981),
              ),
              _buildRawSignalCard(
                title: "Sales Velocity",
                value: "+${(sales['demand_spike_percent'] as double).toStringAsFixed(0)}% Spike",
                sub: "Trend: ${sales['trend_status']}",
                color: sales['trend_status'] == 'CRITICAL' ? Colors.redAccent : const Color(0xFF10B981),
              ),
              _buildRawSignalCard(
                title: "Supplier Risk",
                value: "Score: ${supplier['reliability_score']}/100",
                sub: supplier['delay_flag'] == true ? "ACTIVE DELAY" : "No delays",
                color: supplier['delay_flag'] == true ? Colors.redAccent : const Color(0xFF10B981),
              ),
              _buildRawSignalCard(
                title: "Complaints Spike",
                value: "${complaints['count']} Daily",
                sub: "Multiplier: x${(complaints['spike_multiplier'] as double).toStringAsFixed(1)}",
                color: (complaints['spike_multiplier'] as double) > 3.0 ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: ACTIONS =================
  Widget _buildActionsTab() {
    final constraint = widget.result.constraint;
    final analysis = widget.result.analysis;

    double budgetPercent = constraint.adjustedCost / 500000.0;
    if (budgetPercent > 1.0) budgetPercent = 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget constraint metrics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22222E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "BUDGET UTILIZATION",
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: constraint.budgetStatus == 'WITHIN_LIMIT' ? const Color(0xFF0F241B) : const Color(0xFF241F14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        constraint.budgetStatus == 'WITHIN_LIMIT' ? "APPROVED" : "ADJUSTED TO LIMIT",
                        style: TextStyle(
                          color: constraint.budgetStatus == 'WITHIN_LIMIT' ? const Color(0xFF10B981) : Colors.orangeAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatPKR(constraint.adjustedCost),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const Text(
                      "Limit: PKR 500,000",
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budgetPercent,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF1E1E28),
                    valueColor: AlwaysStoppedAnimation(constraint.budgetStatus == 'WITHIN_LIMIT' ? const Color(0xFF10B981) : Colors.orangeAccent),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Order cost was trimmed by ConstraintEngine: original quantity ${constraint.originalQuantity} units adjusted to ${constraint.adjustedQuantity} units.",
                  style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action chain list
          const Text(
            "RECOMMENDED ACTION CHAIN",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: analysis.actionChain.length,
            itemBuilder: (context, index) {
              final step = analysis.actionChain[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E1E26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF181822),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFA855F7),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${step.step}",
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "STEP ${step.step}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ],
                          ),
                          _buildPriorityBadge(step.priority),
                        ],
                      ),
                    ),
                    // Step details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.detail,
                            style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3),
                          ),
                          const Divider(color: Color(0xFF1E1E26), height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.payments_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    step.costPkr == 0 ? "No Cost" : _formatPKR(step.costPkr),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    step.deadline,
                                    style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= TAB 4: IMPACT =================
  Widget _buildImpactTab() {
    final analysis = widget.result.analysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Side-by-side states comparison
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A1F1F)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.trending_down_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(height: 8),
                      const Text("BEFORE SHIELD", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        "${analysis.before.stockoutRiskPercent.toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const Text("Stockout Risk", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 8),
                      Text(
                        _formatPKR(analysis.before.revenueAtRiskPkr),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Text("Rev at Risk", style: TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101E17),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1B3E2B)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 28),
                      const SizedBox(height: 8),
                      const Text("AFTER SHIELD", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        "${analysis.after.stockoutRiskPercent.toStringAsFixed(0)}%",
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const Text("Stockout Risk", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 8),
                      Text(
                        _formatPKR(analysis.after.revenueAtRiskPkr),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Text("Rev at Risk", style: TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Protected highlight callout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B0A63), Color(0xFF0F1E19)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  "TOTAL NET REVENUE SHIELDED",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPKR(analysis.revenueProtectedPkr),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Estimated revenue loss prevented for Pakistani business operations upon implementing the Action Chain.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal comparison progress bars
          const Text(
            "COMPUTED IMPACT METRIC ADJUSTMENTS",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          _buildImpactProgressRow(
            label: "Stockout Vulnerability Drop",
            beforeVal: analysis.before.stockoutRiskPercent / 100.0,
            afterVal: analysis.after.stockoutRiskPercent / 100.0,
            suffix: "%",
          ),
          const SizedBox(height: 20),
          _buildImpactProgressRow(
            label: "Revenue Exposure Mitigation",
            beforeVal: analysis.before.revenueAtRiskPkr / max(analysis.before.revenueAtRiskPkr, 1.0),
            afterVal: analysis.after.revenueAtRiskPkr / max(analysis.before.revenueAtRiskPkr, 1.0),
            suffix: " PKR",
            isPrice: true,
            beforePrice: analysis.before.revenueAtRiskPkr,
            afterPrice: analysis.after.revenueAtRiskPkr,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactProgressRow({
    required String label,
    required double beforeVal,
    required double afterVal,
    required String suffix,
    bool isPrice = false,
    double beforePrice = 0.0,
    double afterPrice = 0.0,
  }) {
    String beforeText = isPrice ? _formatPKR(beforePrice) : "${(beforeVal * 100).toStringAsFixed(0)}$suffix";
    String afterText = isPrice ? _formatPKR(afterPrice) : "${(afterVal * 100).toStringAsFixed(0)}$suffix";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Before progress bar
        Row(
          children: [
            const SizedBox(width: 50, child: Text("Before", style: TextStyle(color: Colors.grey, fontSize: 10))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: beforeVal,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF1E1E28),
                  valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 90, child: Text(beforeText, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 8),
        // After progress bar
        Row(
          children: [
            const SizedBox(width: 50, child: Text("After", style: TextStyle(color: Colors.grey, fontSize: 10))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: afterVal,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF1E1E28),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 90, child: Text(afterText, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ],
    );
  }

  // ================= HELPERS & WIDGETS =================
  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22222E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessBadge(String label, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildRawSignalCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.grey;
    if (priority == 'CRITICAL') {
      color = Colors.redAccent;
    } else if (priority == 'HIGH') {
      color = Colors.orangeAccent;
    } else if (priority == 'MEDIUM') {
      color = Colors.yellowAccent;
    } else if (priority == 'LOW') {
      color = const Color(0xFF06B6D4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return "Today";
    try {
      final date = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else {
        return "Just now";
      }
    } catch (_) {
      return "Today";
    }
  }

  Color _getRiskColor(double score) {
    if (score < 40) return const Color(0xFF10B981);
    if (score < 75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getRiskLabel(double score) {
    if (score < 40) return "LOW RISK PROFILE";
    if (score < 75) return "MODERATE EXPOSURE";
    return "CRITICAL SHOCK RISK";
  }
}

// Custom Risk Arc Meter (0 to 100)
class RiskArcPainter extends CustomPainter {
  final double score;

  RiskArcPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2 - 12, size.height - 12);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background arc (grey)
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E28)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, pi, pi, false, bgPaint);

    // Draw active indicator arc
    final double angle = pi * (score / 100.0);

    final activePaint = Paint()
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gradient based on risk level
    if (score < 40) {
      activePaint.color = const Color(0xFF10B981);
    } else if (score < 75) {
      activePaint.color = Colors.orangeAccent;
    } else {
      activePaint.color = Colors.redAccent;
    }

    canvas.drawArc(rect, pi, angle, false, activePaint);

    // Draw needle pointing to score
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double needleAngle = pi + angle;
    final needleLength = radius - 8;
    final needleTip = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    canvas.drawLine(center, needleTip, needlePaint);

    // Draw center hub
    final hubPaint = Paint()..color = const Color(0xFFA855F7);
    canvas.drawCircle(center, 8, hubPaint);
    final hubInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, hubInnerPaint);
  }

  @override
  bool shouldRepaint(covariant RiskArcPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
