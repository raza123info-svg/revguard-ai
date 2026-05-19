// lib/screens/home_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Input controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _customCityController = TextEditingController();

  // Selections
  String? _selectedCity;
  bool _isCustomCity = false;

  // File data holds
  String? _warehouseName;
  String? _warehouseContent;

  String? _salesName;
  String? _salesContent;

  String? _supplierName;
  String? _supplierContent;

  String? _complaintsName;
  String? _complaintsContent;

  // List of supported cities
  final List<String> _pakistaniCities = [
    'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Multan',
    'Peshawar', 'Quetta', 'Hyderabad', 'Sialkot', 'Gujranwala', 'Bahawalpur',
    'Sargodha', 'Sukkur', 'Larkana', 'Abbottabad', 'Mardan', 'Dera Ghazi Khan',
    'Rahim Yar Khan', 'Sahiwal'
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _budgetController.dispose();
    _customCityController.dispose();
    super.dispose();
  }

  // File picker helper
  Future<void> _pickFile(String expectedType, Function(String name, String content) onPicked) async {
    try {
      final result = await FilePicker.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final content = utf8.decode(file.bytes!);
          
          // If the CSV contains a city column, we can try to extract cities and select the first one!
          // We do this by checking if the content has a city column.
          _tryAutoPopulateCityFromContent(content);

          setState(() {
            onPicked(file.name, content);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _tryAutoPopulateCityFromContent(String content) {
    // Basic CSV parser to see if a header has a city column
    try {
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        final headers = lines.first.split(',').map((e) => e.trim().toLowerCase()).toList();
        int cityIdx = -1;
        for (int i = 0; i < headers.length; i++) {
          if (headers[i] == 'city' || headers[i] == 'location' || headers[i] == 'town') {
            cityIdx = i;
            break;
          }
        }
        if (cityIdx != -1 && lines.length > 1) {
          final firstRow = lines[1].split(',');
          if (firstRow.length > cityIdx) {
            final cityValue = firstRow[cityIdx].trim();
            if (cityValue.isNotEmpty) {
              // Normalize city name
              final matchedCity = _pakistaniCities.firstWhere(
                (c) => c.toLowerCase() == cityValue.toLowerCase(),
                orElse: () => '',
              );
              if (matchedCity.isNotEmpty) {
                _selectedCity = matchedCity;
                _isCustomCity = false;
              } else {
                _selectedCity = 'Other / Enter manually';
                _isCustomCity = true;
                _customCityController.text = cityValue;
              }
            }
          }
        }
      }
    } catch (_) {
      // Fail silently, auto-population is a nice-to-have
    }
  }

  // Validation check
  bool _isFormValid() {
    final productName = _productNameController.text.trim();
    final budget = _budgetController.text.trim();
    
    final hasProduct = productName.isNotEmpty;
    final hasBudget = budget.isNotEmpty && double.tryParse(budget) != null;
    
    final hasCity = _isCustomCity 
        ? _customCityController.text.trim().isNotEmpty 
        : (_selectedCity != null && _selectedCity != 'Other / Enter manually');

    final hasFiles = _warehouseContent != null ||
        _salesContent != null ||
        _supplierContent != null ||
        _complaintsContent != null;

    return hasProduct && hasBudget && hasCity && hasFiles;
  }

  void _startAnalysis() {
    if (!_isFormValid()) return;

    final product = _productNameController.text.trim();
    final budget = double.parse(_budgetController.text.trim());
    final city = _isCustomCity 
        ? _customCityController.text.trim() 
        : _selectedCity!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          productName: product,
          selectedCity: city,
          budgetPkr: budget,
          warehouseContent: _warehouseContent,
          salesContent: _salesContent,
          supplierContent: _supplierContent,
          complaintsContent: _complaintsContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid = _isFormValid();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Design
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.cyan,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'REVGUARD AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ANTIGRAVITY REVENUE AGENT — PAKISTAN',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Inputs Card
              _buildSectionTitle('AGENT RUNTIME PARAMETERS'),
              const SizedBox(height: 12),
              _buildFormCard(),

              const SizedBox(height: 28),

              // File Uploads Card
              _buildSectionTitle('DATA PIPELINE INGESTION'),
              const SizedBox(height: 12),
              _buildFileUploadCard(),

              const SizedBox(height: 40),

              // Execute Button
              Center(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isValid
                        ? const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    boxShadow: isValid
                        ? [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isValid ? _startAnalysis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.white10,
                    ),
                    child: Text(
                      'ANALYZE REVENUE THREAT',
                      style: TextStyle(
                        color: isValid ? Colors.white : Colors.white30,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name Input
          const Text(
            'Product / Service Name',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _productNameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter your product or service name', null),
          ),
          const SizedBox(height: 20),

          // City Selection Dropdown
          const Text(
            'Target City (Pakistan)',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                hint: const Text(
                  'Select city...',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                dropdownColor: const Color(0xFF0F172A),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyan),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: [
                  ..._pakistaniCities.map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      )),
                  const DropdownMenuItem(
                    value: 'Other / Enter manually',
                    child: Text('Other / Enter manually', style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCity = val;
                    _isCustomCity = val == 'Other / Enter manually';
                    if (!_isCustomCity) {
                      _customCityController.clear();
                    }
                  });
                },
              ),
            ),
          ),

          // Custom City Free-Text Field
          if (_isCustomCity) ...[
            const SizedBox(height: 16),
            const Text(
              'Enter City Manually',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customCityController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Enter city name', null),
            ),
          ],

          const SizedBox(height: 20),

          // Budget Input
          const Text(
            'Fulfillment Budget',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter your available budget in PKR', 'PKR'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildUploadRow(
            label: 'Warehouse Inventory Data',
            expectedFile: 'warehouse.csv',
            fileName: _warehouseName,
            onTap: () => _pickFile('csv', (name, content) {
              _warehouseName = name;
              _warehouseContent = content;
            }),
            onClear: () => setState(() {
              _warehouseName = null;
              _warehouseContent = null;
            }),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildUploadRow(
            label: 'Sales Trends Data',
            expectedFile: 'sales.csv',
            fileName: _salesName,
            onTap: () => _pickFile('csv', (name, content) {
              _salesName = name;
              _salesContent = content;
            }),
            onClear: () => setState(() {
              _salesName = null;
              _salesContent = null;
            }),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildUploadRow(
            label: 'Supplier Reliability Data',
            expectedFile: 'supplier.json',
            fileName: _supplierName,
            onTap: () => _pickFile('json', (name, content) {
              _supplierName = name;
              _supplierContent = content;
            }),
            onClear: () => setState(() {
              _supplierName = null;
              _supplierContent = null;
            }),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildUploadRow(
            label: 'Customer Complaints Data',
            expectedFile: 'complaints.csv',
            fileName: _complaintsName,
            onTap: () => _pickFile('csv', (name, content) {
              _complaintsName = name;
              _complaintsContent = content;
            }),
            onClear: () => setState(() {
              _complaintsName = null;
              _complaintsContent = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRow({
    required String label,
    required String expectedFile,
    required String? fileName,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final bool hasFile = fileName != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                hasFile ? fileName : 'No file chosen (required: $expectedFile)',
                style: TextStyle(
                  color: hasFile ? const Color(0xFF10B981) : Colors.white30,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (hasFile)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            onPressed: onClear,
          )
        else
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_file, size: 16, color: Colors.cyan),
            label: const Text('UPLOAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyan)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              side: BorderSide(color: Colors.cyan.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, String? prefix) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
      prefixText: prefix != null ? '$prefix ' : null,
      prefixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyan, width: 1.5),
      ),
    );
  }
}
