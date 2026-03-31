import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

class NeuralLabPage extends StatefulWidget {
  final List<dynamic> dnaThreats;

  const NeuralLabPage({super.key, required this.dnaThreats});

  @override
  State<NeuralLabPage> createState() => _NeuralLabPageState();
}

class _NeuralLabPageState extends State<NeuralLabPage> {
  bool isRetraining = false;

  void handleRetrain() {
    setState(() => isRetraining = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => isRetraining = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _header(
                'Neural Insight Lab',
                'Proactive Behavioral DNA Fingerprinting & Model Interpretability.',
              ),
              ElevatedButton.icon(
                onPressed: isRetraining ? null : handleRetrain,
                icon: isRetraining
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.zap, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: Text(
                  isRetraining ? 'Retraining AI...' : 'Optimize Model DNA',
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _dnaMonitor()),
              const SizedBox(width: 20),
              Expanded(child: _modelTrustChart()),
            ],
          ),
          const SizedBox(height: 20),
          _decisionConfidenceCard(),
        ],
      ),
    );
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.brainCircuit,
              color: Color(0xFF4F46E5),
              size: 28,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _dnaMonitor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Injected DNA Monitor', LucideIcons.microscope),
          const SizedBox(height: 20),
          ...widget.dnaThreats.map((threat) => _dnaTile(threat)).toList(),
          if (widget.dnaThreats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No active DNA modifications detected.',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dnaTile(dynamic threat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.fingerprint,
            size: 18,
            color: Color(0xFF4F46E5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              threat.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            LucideIcons.checkCircle2,
            size: 14,
            color: Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  Widget _modelTrustChart() {
    final List<Map<String, dynamic>> confidenceData = [
      {'name': 'Consistency', 'value': 94},
      {'name': 'Pattern Match', 'value': 88},
      {'name': 'Anomaly Det.', 'value': 91},
      {'name': 'Context Accuracy', 'value': 85},
    ];

    return Container(
      height: 380,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Model Trust & Feature Weighting', LucideIcons.barChart),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            confidenceData[value.toInt()]['name'],
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: confidenceData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['value'].toDouble(),
                        color: const Color(0xFF4F46E5),
                        width: 25,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionConfidenceCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(LucideIcons.brain, color: Color(0xFF4F46E5), size: 50),
              if (isRetraining)
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF4F46E5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Decision Confidence',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'AI currently requires 90% confidence for autonomous termination.',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.9,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F46E5),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ethical Bias Check: PASSED',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verified vendors (Microsoft, Google, etc.) are granted a 80% Risk-Mitigation bias to prevent accidental system corruption.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
