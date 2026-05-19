import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller and API key states
  final TextEditingController _productController = TextEditingController();
  late String _geminiKey;
  late String _newsApiKey;
  String _gcloudProjectId = '';

  bool _isKeysExpanded = false;
  bool _obscureGemini = true;
  bool _obscureNews = true;

  // Selected file content state
  String? _warehouseName;
  String? _warehouseContent;

  String? _salesName;
  String? _salesContent;

  String? _supplierName;
  String? _supplierContent;

  String? _complaintsName;
  String? _complaintsContent;

  @override
  void initState() {
    super.initState();
    // Load pre-filled keys from dotenv
    _geminiKey = dotenv.env['GEMINI_KEY'] ?? '';
    _newsApiKey = dotenv.env['NEWSAPI_KEY'] ?? '';
  }

  Future<void> _pickFile({
    required String fileType, // 'warehouse', 'sales', 'supplier', 'complaints'
    required List<String> extensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String content = '';

        if (kIsWeb) {
          if (file.bytes != null) {
            content = utf8.decode(file.bytes!);
          }
        } else {
          if (file.bytes != null) {
            content = utf8.decode(file.bytes!);
          } else if (file.path != null) {
            content = await File(file.path!).readAsString();
          }
        }

        setState(() {
          switch (fileType) {
            case 'warehouse':
              _warehouseName = file.name;
              _warehouseContent = content;
              break;
            case 'sales':
              _salesName = file.name;
              _salesContent = content;
              break;
            case 'supplier':
              _supplierName = file.name;
              _supplierContent = content;
              break;
            case 'complaints':
              _complaintsName = file.name;
              _complaintsContent = content;
              break;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully uploaded ${file.name}"),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _triggerAnalysis() {
    final productName = _productController.text.trim();
    if (productName.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          productName: productName,
          warehouseCsv: _warehouseContent,
          salesCsv: _salesContent,
          supplierJson: _supplierContent,
          complaintsCsv: _complaintsContent,
          geminiKey: _geminiKey,
          newsApiKey: _newsApiKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnalyzeEnabled = _productController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            // Home screen main contents
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildAPIKeysPanel(),
                const SizedBox(height: 24),
                _buildProductInput(),
                const SizedBox(height: 32),
                _buildUploadSection(),
                const SizedBox(height: 32),
                _buildPipelinePreview(),
                const SizedBox(height: 40),
                _buildActionButton(isAnalyzeEnabled),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "REVGUARD AI",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const Text(
              "ANTIGRAVITY REVENUE AGENT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isKeysExpanded = !_isKeysExpanded;
            });
          },
          icon: Icon(
            _isKeysExpanded ? Icons.key_off : Icons.vpn_key_rounded,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            _isKeysExpanded ? "HIDE KEYS" : "🔑 API KEYS",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E28),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _isKeysExpanded ? const Color(0xFFA855F7) : const Color(0xFF2E2E3E),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAPIKeysPanel() {
    if (!_isKeysExpanded) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "CREDENTIAL MANAGER",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFA855F7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          // Gemini API Key Input
          TextField(
            obscureText: _obscureGemini,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: "Gemini 1.5 Flash API Key",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: const Icon(Icons.psychology, color: Colors.grey, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureGemini ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureGemini = !_obscureGemini),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2E2E3E)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA855F7)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            controller: TextEditingController(text: _geminiKey),
            onChanged: (val) => _geminiKey = val,
          ),
          const SizedBox(height: 16),
          // NewsAPI Key Input
          TextField(
            obscureText: _obscureNews,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: "NewsAPI Key",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: const Icon(Icons.newspaper_rounded, color: Colors.grey, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNews ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureNews = !_obscureNews),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2E2E3E)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA855F7)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            controller: TextEditingController(text: _newsApiKey),
            onChanged: (val) => _newsApiKey = val,
          ),
          const SizedBox(height: 16),
          // GCP Project ID (Optional)
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: "Google Cloud Project ID (Optional)",
              labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Icon(Icons.cloud_queue_rounded, color: Colors.grey, size: 18),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2E2E3E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA855F7)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            controller: TextEditingController(text: _gcloudProjectId),
            onChanged: (val) => _gcloudProjectId = val,
          ),
        ],
      ),
    );
  }

  Widget _buildProductInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "PRODUCT TO DEFEND",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _productController,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          onChanged: (val) {
            setState(() {}); // Re-build to activate/deactivate Analyze button
          },
          decoration: InputDecoration(
            hintText: "e.g. Basmati Rice 5kg — Karachi Store",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF161622),
            prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFA855F7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A3A), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFA855F7), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "INTELLIGENCE CHANNELS (OPTIONAL)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.0,
              ),
            ),
            if (_warehouseName != null || _salesName != null || _supplierName != null || _complaintsName != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _warehouseName = null;
                    _warehouseContent = null;
                    _salesName = null;
                    _salesContent = null;
                    _supplierName = null;
                    _supplierContent = null;
                    _complaintsName = null;
                    _complaintsContent = null;
                  });
                },
                child: const Text("Clear Uploads", style: TextStyle(color: Colors.grey, fontSize: 11)),
              )
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildUploadCard(
              title: "warehouse.csv",
              subtitle: "Inventory Stocks",
              icon: Icons.inventory_2_outlined,
              fileName: _warehouseName,
              onTap: () => _pickFile(fileType: 'warehouse', extensions: ['csv']),
            ),
            _buildUploadCard(
              title: "sales.csv",
              subtitle: "Velocity & Trends",
              icon: Icons.trending_up_rounded,
              fileName: _salesName,
              onTap: () => _pickFile(fileType: 'sales', extensions: ['csv']),
            ),
            _buildUploadCard(
              title: "supplier.json",
              subtitle: "Vendor Alerts",
              icon: Icons.factory_outlined,
              fileName: _supplierName,
              onTap: () => _pickFile(fileType: 'supplier', extensions: ['json']),
            ),
            _buildUploadCard(
              title: "complaints.csv",
              subtitle: "Quality & Delivery",
              icon: Icons.feedback_outlined,
              fileName: _complaintsName,
              onTap: () => _pickFile(fileType: 'complaints', extensions: ['csv']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    bool isSelected = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF2A2A3A),
          strokeWidth: 1.5,
          gap: 6,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F1E19) : const Color(0xFF13131B),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : icon,
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSelected
                    ? (fileName.length > 18 ? "...${fileName.substring(fileName.length - 15)}" : fileName)
                    : subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF10B981).withOpacity(0.7) : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelinePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "8-STAGE AUTONOMOUS REASONING PIPELINE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPipelineBadge("T1: NewsAPI", true),
            _buildPipelineBadge("T2: Warehouse", _warehouseContent != null),
            _buildPipelineBadge("T3: Sales", _salesContent != null),
            _buildPipelineBadge("T4: Supplier", _supplierContent != null),
            _buildPipelineBadge("T5: Complaints", _complaintsContent != null),
            _buildPipelineBadge("T6: Contradiction", true),
            _buildPipelineBadge("T7: Constraints", true),
            _buildPipelineBadge("T8: Gemini AI", true),
          ],
        ),
      ],
    );
  }

  Widget _buildPipelineBadge(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E152F) : const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFA855F7).withOpacity(0.5) : const Color(0xFF22222E),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFFA855F7) : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isEnabled) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _triggerAnalysis : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA855F7),
          disabledBackgroundColor: const Color(0xFF1E1E28),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flash_on_rounded,
              color: isEnabled ? Colors.white : Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(width: 10),
            const Text(
              "ANALYZE REVENUE THREAT",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for dashed borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Add rounded rect
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    ));

    // Draw dashed path
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double len = gap;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + len),
          paint,
        );
        distance += len * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.gap != gap;
  }
}
