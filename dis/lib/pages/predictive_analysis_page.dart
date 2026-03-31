import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class PredictiveAnalysisPage extends StatefulWidget {
  final List<FlSpot> ramHistory;
  final Map<String, dynamic> metrics;
  final io.Socket? socket;

  const PredictiveAnalysisPage({
    super.key,
    required this.ramHistory,
    required this.metrics,
    this.socket,
  });

  @override
  State<PredictiveAnalysisPage> createState() => _PredictiveAnalysisPageState();
}

class _PredictiveAnalysisPageState extends State<PredictiveAnalysisPage> {
  bool isSimulating = false;
  bool isCompacting = false;
  Map<String, dynamic>? simResults;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    widget.socket?.on('simulation_results', (data) {
      if (mounted) setState(() => simResults = data);
    });
  }

  void toggleSimulation() {
    if (!isSimulating) {
      widget.socket?.emit('request_simulation', {
        'process': widget.metrics['top_hog'] ?? "System",
      });
      setState(() => isSimulating = true);
    } else {
      setState(() {
        isSimulating = false;
        simResults = null;
      });
    }
  }

  void handleCompaction() {
    setState(() => isCompacting = true);
    widget.socket?.emit('flush_memory', {'name': 'SYSTEM_HEAP'});
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isCompacting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF4F46E5),
            content: Text(
              'Preemptive Memory Compaction Successfully Executed.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String predictionStatus =
        widget.metrics['prediction']?['status'] ?? 'stable';
    final int stabilityScore = isSimulating && simResults != null
        ? (simResults!['new_stability'] as num).toInt()
        : (predictionStatus == 'stable'
              ? 98
              : (predictionStatus == 'warning' ? 75 : 42));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSection(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _projectionChart()),
              const SizedBox(width: 25),
              Expanded(
                flex: 1,
                child: _sidebarStats(predictionStatus, stabilityScore),
              ),
            ],
          ),
          if (predictionStatus != 'stable' && !isSimulating)
            _actionRecommendationCard(),
        ],
      ),
    );
  }

  Widget _headerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.timer,
                  color: Color(0xFF4F46E5),
                  size: 28,
                ),
                const SizedBox(width: 15),
                Text(
                  'Stability Time-Machine',
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
            const Text(
              'AI Digital Twin: Projecting system states through simulation.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: toggleSimulation,
          icon: Icon(
            isSimulating ? LucideIcons.stopCircle : LucideIcons.play,
            size: 18,
          ),
          label: Text(
            isSimulating ? 'Simulation Active' : 'Start Digital Twin',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSimulating
                ? const Color(0xFF22C55E).withOpacity(0.1)
                : Colors.white,
            foregroundColor: isSimulating
                ? const Color(0xFF059669)
                : const Color(0xFF4F46E5),
            elevation: 0,
            side: BorderSide(
              color: isSimulating
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE5E7EB),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _projectionChart() {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSimulating
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSimulating
                        ? 'Hypothetical Exhaustion Projection'
                        : 'Resource Exhaustion Projection',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.cpu,
                        size: 12,
                        color: isSimulating
                            ? const Color(0xFF059669)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSimulating
                            ? 'Scenario: Post-Termination of ${widget.metrics['top_hog'] ?? "System"}'
                            : 'Current Pressure Source: ${widget.metrics['top_hog'] ?? "System"}',
                        style: TextStyle(
                          color: isSimulating
                              ? const Color(0xFF059669)
                              : const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isSimulating)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE SIMULATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final List<FlSpot> currentSpots = widget.ramHistory;

    // Create projection spots based on slope or backend prediction
    final prediction = widget.metrics['prediction'];
    final double lastY = currentSpots.isNotEmpty ? currentSpots.last.y : 0;

    List<FlSpot> projectionSpots = [];
    if (currentSpots.isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        // Mocking a projection if stable, or using backend logic if we had slope
        double nextY = lastY + (i * 2);
        if (prediction != null && prediction['status'] == 'critical') {
          nextY = lastY + (i * 5); // Steeper growth if critical
        }
        projectionSpots.add(FlSpot(19 + i.toDouble(), nextY));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: currentSpots,
            isCurved: true,
            color: isSimulating
                ? const Color(0xFF22C55E)
                : const Color(0xFF4F46E5),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color:
                  (isSimulating
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF4F46E5))
                      .withOpacity(0.05),
            ),
          ),
          LineChartBarData(
            spots: projectionSpots,
            isCurved: true,
            color: isSimulating
                ? const Color(0xFF22C55E).withOpacity(0.5)
                : const Color(0xFFEF4444),
            dashArray: [5, 5],
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _sidebarStats(String status, int score) {
    return Column(
      children: [
        _forecastCard(status),
        const SizedBox(height: 20),
        _stabilityIndexCard(score),
      ],
    );
  }

  Widget _forecastCard(String status) {
    final bool isSafe = status == 'stable' || isSimulating;
    final String label = isSimulating
        ? 'SIMULATED FORECAST'
        : 'STABILITY FORECAST';
    final String value = isSimulating
        ? '+${simResults?['improvement_min'] ?? 0}m'
        : (status == 'stable'
              ? 'STABLE'
              : '${widget.metrics['prediction']?['min']}m ${widget.metrics['prediction']?['sec']}s');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSafe
              ? const Color(0xFF22C55E).withOpacity(0.1)
              : const Color(0xFFEF4444).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            isSafe
                ? const Color(0xFF22C55E).withOpacity(0.05)
                : const Color(0xFFEF4444).withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isSafe ? const Color(0xFF059669) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSimulating
                ? 'Gain approximately ${simResults?['improvement_min']} mins of life.'
                : (status == 'stable'
                      ? 'Safe margins.'
                      : 'Risk in ${widget.metrics['top_hog']}.'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _stabilityIndexCard(int score) {
    Color color = score > 80
        ? const Color(0xFF22C55E)
        : (score > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    return Container(
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSimulating ? 'Projected Index' : 'Stability Index',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 25),
          _detailRow(
            LucideIcons.trendingUp,
            'Spiral Detection',
            '${widget.metrics['prediction']?['acceleration'] ?? '0.000'} m/s²',
            const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 15),
          _detailRow(
            LucideIcons.zap,
            'Scenario Mode',
            isSimulating ? 'Active' : 'Idle',
            const Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _actionRecommendationCard() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.shieldAlert,
            size: 36,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PREEMPTIVE ACTION RECOMMENDED',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB91C1C),
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'AI predicts a Kernel Heap Overflow due to ${widget.metrics['top_hog']}. Execute memory compaction?',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isCompacting ? null : handleCompaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isCompacting ? 'Compacting...' : 'Start Compaction',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
