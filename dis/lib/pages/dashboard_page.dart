import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

class DashboardPage extends StatelessWidget {
  final double cpu;
  final double ram;
  final double disk;
  final double temp;
  final int riskScore;
  final List<dynamic> cpuHistory;
  final List<dynamic> ramHistory;
  final List<Map<String, dynamic>> logs;
  final Map<String, dynamic> advancedMetrics;
  final dynamic socket;

  const DashboardPage({
    super.key,
    required this.cpu,
    required this.ram,
    required this.disk,
    required this.temp,
    required this.riskScore,
    required this.cpuHistory,
    required this.ramHistory,
    required this.logs,
    required this.advancedMetrics,
    this.socket,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOVA SHIELD',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  Text(
                    'REAL-TIME DEFENSE',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              _buildAutoPilotBadge(),
            ],
          ),
          const SizedBox(height: 25),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isCompact = constraints.maxWidth < 1100;

              if (isCompact) {
                return Column(
                  children: [
                    _buildAiStatusPanel(),
                    const SizedBox(height: 20),
                    _buildLiveSystemHealth(),
                    const SizedBox(height: 20),
                    _buildNeuralCoreDNA(),
                    const SizedBox(height: 20),
                    _buildAdvancedShieldsHub(),
                    const SizedBox(height: 20),
                    _buildAiCoPilotAdvisory(),
                    const SizedBox(height: 20),
                    _buildControlPanel(context),
                    const SizedBox(height: 20),
                    _buildPredictiveMaintenance(),
                    const SizedBox(height: 20),
                    _buildRecentAlerts(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildAiStatusPanel(),
                        const SizedBox(height: 20),
                        _buildNeuralCoreDNA(),
                        const SizedBox(height: 20),
                        _buildAiCoPilotAdvisory(),
                        const SizedBox(height: 20),
                        _buildPredictiveMaintenance(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Column
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildLiveSystemHealth(),
                        const SizedBox(height: 20),
                        _buildAdvancedShieldsHub(),
                        const SizedBox(height: 20),
                        _buildControlPanel(context),
                        const SizedBox(height: 20),
                        _buildRecentAlerts(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildAutoPilotBadge() {
    bool isIdle = cpu < 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      constraints: const BoxConstraints(maxWidth: 180), // Prevent badge from pushing layout
      decoration: BoxDecoration(
        color: isIdle ? const Color(0xFFF3E8FF) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIdle ? const Color(0xFFD8B4FE) : const Color(0xFFC7D2FE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIdle ? LucideIcons.zap : LucideIcons.cpu,
            size: 14,
            color: isIdle ? Colors.purpleAccent : Colors.blueAccent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isIdle ? 'AUTO-PILOT: IDLE' : 'AUTO-PILOT: ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isIdle
                    ? const Color(0xFF7E22CE)
                    : const Color(0xFF4338CA),
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralCoreDNA() {
    List<dynamic> dnaThreats = advancedMetrics['dna_threats'] ?? [];
    bool isBaselineReady = advancedMetrics['dna_lab_ready'] ?? true;

    return _glassPanel(
      title: 'NEURAL CORE DNA ANALYSIS',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Baseline DNA State:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              Text(
                isBaselineReady ? 'ESTABLISHED' : 'CALIBRATING...',
                style: TextStyle(
                  color: isBaselineReady
                      ? const Color(0xFF7E22CE)
                      : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (dnaThreats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.fingerprint,
                      color: const Color(0xFF6B7280).withOpacity(0.2),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No anomalous DNA patterns detected.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          else
            ...dnaThreats
                .map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: Color(0xFFEF4444),
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                t['dna'] ?? 'Pattern Identified',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RISK',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildAdvancedShieldsHub() {
    return _glassPanel(
      title: 'ADVANCED PROTECTION SHIELDS',
      child: Column(
        children: [
          _shieldTile(
            'Process Tree Analysis',
            'Graph-logic monitoring parent-child maps.',
            LucideIcons.component,
            const Color(0xFF4F46E5),
            true,
          ),
          const SizedBox(height: 12),
          _shieldTile(
            'Network NIDS / Exfiltration',
            'Predictive behavioral connection audit.',
            LucideIcons.network,
            Colors.cyanAccent,
            true,
          ),
          const SizedBox(height: 12),
          _shieldTile(
            'Registry Integrity Guard',
            'Persistence & Startup boot-log monitor.',
            LucideIcons.binary,
            const Color(0xFF22C55E),
            true,
          ),
        ],
      ),
    );
  }

  Widget _shieldTile(
    String title,
    String desc,
    IconData icon,
    Color color,
    bool active,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color.withOpacity(0.2) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: color, size: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictiveMaintenance() {
    double baseline = 40 + (cpu * 0.4);
    double delta = temp - baseline;
    bool needsCleaning = delta > 10;

    return _glassPanel(
      title: 'PREDICTIVE MAINTENANCE',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cooling Efficiency:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              Text(
                needsCleaning ? 'DEGRADING' : 'OPTIMAL',
                style: TextStyle(
                  color: needsCleaning
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: (100 - delta.clamp(0, 50)) / 100,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(
              needsCleaning ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            needsCleaning
                ? 'ADVISORY: Thermal efficiency is dropping. Consider cleaning dust.'
                : 'Hardware health is within normal parameters.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatusPanel() {
    Color statusColor = const Color(0xFF22C55E);
    String statusText = 'SAFE';
    double gaugeValue = 0.85;

    if (riskScore >= 2) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'CRITICAL';
      gaugeValue = 0.3;
    } else if (riskScore == 1) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'WARNING';
      gaugeValue = 0.55;
    }

    return _glassPanel(
      title: 'AI STATUS PANEL',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: CircularGaugePainter(
                    value: gaugeValue,
                    color: statusColor,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'Current Threat Level: ${riskScore == 0
                        ? "Low"
                        : riskScore == 1
                        ? "Medium"
                        : "High"}.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusIndicator(
                'Graph Logic:',
                'ACTIVE',
                const Color(0xFF4F46E5),
              ),
              _statusIndicator(
                'NIDS Engine:',
                'ARMED',
                const Color(0xFF06B6D4),
              ),
              _statusIndicator('DNA Lab:', 'SYNCED', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _statusIndicator(String label, String status, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSystemHealth() {
    return _glassPanel(
      title: 'LIVE SYSTEM HEALTH',
      child: LayoutBuilder(
        builder: (context, constraints) {
          double spacing = 12.0;
          int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1100 ? 2 : 4);
          double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: itemWidth,
                child: _miniMetricCard(
                  'CPU USAGE',
                  '${cpu.toStringAsFixed(0)}%',
                  _sparkline(const Color(0xFF4F46E5), 1),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _miniMetricCard(
                  'RAM USAGE',
                  '${(ram * 0.16).toStringAsFixed(1)}GB / 16GB',
                  _barChart(),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _miniMetricCard(
                  'DISK SPACE',
                  '${(disk * 2.5).toStringAsFixed(0)}GB Free',
                  _circularStorage(disk / 100),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _miniMetricCard(
                  'TEMPERATURE',
                  '${temp.toStringAsFixed(0)}°C',
                  _tempWidget(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniMetricCard(String title, String value, Widget visual) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: visual),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return _glassPanel(
      title: 'CONTROL PANEL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Defense Modes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _showAiChatDialog(context),
                child: const Text(
                  'OPEN AI CHAT',
                  style: TextStyle(
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          StatefulBuilder(
            builder: (context, setState) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _modeToggle(
                    'Gaming Mode',
                    LucideIcons.gamepad2,
                    const Color(0xFFF59E0B),
                    advancedMetrics['gaming_mode'] ?? false,
                    (val) {
                      socket.emit('toggle_gaming_mode', {'active': val});
                      setState(() => advancedMetrics['gaming_mode'] = val);
                    },
                  ),
                  _modeToggle(
                    'Survival Mode',
                    LucideIcons.zap,
                    const Color(0xFFEF4444),
                    advancedMetrics['survival_mode'] ?? false,
                    (val) {
                      socket.emit('toggle_survival_mode', {'active': val});
                      setState(() => advancedMetrics['survival_mode'] = val);
                    },
                  ),
                  _modeToggle(
                    'Deep Scan',
                    LucideIcons.search,
                    const Color(0xFF8B5CF6),
                    advancedMetrics['deep_scan'] ?? false,
                    (val) {
                      socket.emit('toggle_deep_scan', {'active': val});
                      setState(() => advancedMetrics['deep_scan'] = val);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PEAS Engine Active: Monitoring behavior with trust scoring.',
                    style: TextStyle(
                      color: const Color(0xFF059669),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle(
    String label,
    IconData icon,
    Color color,
    bool isActive,
    Function(bool) onToggle,
  ) {
    return InkWell(
      onTap: () => onToggle(!isActive),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? color : Colors.white38),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? color : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return _glassPanel(
      title: 'RECENT ALERTS & NOTIFICATIONS',
      child: Column(
        children: [
          _alertItem(
            '[INFO] Time-Series Monitoring persisted to SQLite.',
            Colors.green,
            LucideIcons.database,
          ),
          const SizedBox(height: 10),
          _alertItem(
            '[SYSTEM] AI Auto-Pilot: Background task priority optimized.',
            Colors.blue,
            LucideIcons.zap,
          ),
        ],
      ),
    );
  }

  Widget _alertItem(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Data Live Stream: Connected via WebSocket',
          style: TextStyle(color: const Color(0xFF6B7280), fontSize: 10),
        ),
      ],
    );
  }

  Widget _glassPanel({
    required String title,
    required Widget child,
    double? height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.03),
            blurRadius: 15,
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
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF111827),
                ),
              ),
              Icon(Icons.more_horiz, color: const Color(0xFF9CA3AF), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _sparkline(Color color, int index) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: CustomPaint(painter: SparklinePainter(color, index)),
    );
  }

  Widget _barChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        6,
        (index) => Container(
          width: 8,
          height: 10 + (index * 4.0) + (ram % 10), // Stable calculation
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _circularStorage(double percent) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
          ),
          const Text(
            '250GB',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tempWidget() {
    return Column(
      children: [
        const Icon(LucideIcons.thermometer, color: Color(0xFF4F46E5), size: 30),
        const SizedBox(height: 5),
        _sparkline(const Color(0xFF4F46E5), 2),
      ],
    );
  }

  void _showAiChatDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI Chat',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          _AiChatDialog(socket: socket, advancedMetrics: advancedMetrics),
    );
  }

  Widget _buildAiCoPilotAdvisory() {
    String? response = advancedMetrics['last_ai_response'];

    return _glassPanel(
      title: 'AI CO-PILOT ADVISORY',
      child: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.brain,
                  color: Colors.blueAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Insight',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4338CA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              response ??
                  'Ask a diagnostic question via Control Panel to receive a neural insight about your current system state.',
              style: const TextStyle(
                color: const Color(0xFF1F2937),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatDialog extends StatefulWidget {
  final dynamic socket;
  final Map<String, dynamic> advancedMetrics;

  const _AiChatDialog({required this.socket, required this.advancedMetrics});

  @override
  State<_AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<_AiChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text':
          'Hello! I am your NOVA SHIELD AI Co-pilot. How can I help with your system diagnostics today?',
    });

    if (widget.socket != null) {
      widget.socket.on('ai_chat_response', (data) {
        if (mounted) {
          setState(() {
            // Remove any active indicators (Deep Scan or Normal)
            _messages.removeWhere((m) => m['isIndicator'] == true);

            _messages.add({
              'role': 'ai',
              'text':
                  data['response'] ??
                  'I apologize, but I could not generate a diagnostic at this time.',
            });
            _isWaiting = false;
          });
          _scrollToBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.socket != null) {
      widget.socket.off('ai_chat_response');
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_isWaiting || _controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final queryLower = text.toLowerCase();

    // Keywords to trigger system analysis indicator
    const sysKeywords = [
      'slow',
      'hang',
      'lag',
      'performance',
      'cpu',
      'ram',
      'memory',
      'speed',
      'heat',
      'hot',
      'system',
      'status',
      'pc',
      'computer',
      'halat',
      'garam',
      'load',
      'kam',
      'atak',
      'thik',
      'fix',
      'issue',
      'problem',
      'analysis',
      'scan',
      'risk',
      'resource',
      'usage',
      'health',
    ];

    bool isSystemQuery = sysKeywords.any((kw) => queryLower.contains(kw));

    setState(() {
      _messages.add({'role': 'user', 'text': text});

      // Dynamic Indicator based on query type
      if (isSystemQuery) {
        _messages.add({
          'role': 'ai',
          'text': 'Deep Scanning system telemetry...',
          'isIndicator': true,
          'type': 'deep_scan',
        });
      } else {
        _messages.add({
          'role': 'ai',
          'text': 'Processing...',
          'isIndicator': true,
          'type': 'normal',
        });
      }

      _isWaiting = true;
      _controller.clear();
    });

    if (widget.socket != null) {
      widget.socket.emit('ai_chat_query', {'query': text});
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        height: 600,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                color: Colors.blueAccent.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(LucideIcons.brain, color: Colors.blueAccent),
                    const SizedBox(width: 15),
                    Text(
                      'AI NEURAL CO-PILOT',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isAi = msg['role'] == 'ai';
                    final isIndicator = msg['isIndicator'] == true;

                    if (isIndicator) {
                      bool isDeepScan = msg['type'] == 'deep_scan';
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDeepScan
                                ? const Color(0xFFF5F3FF)
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDeepScan
                                  ? const Color(0xFFDDD6FE)
                                  : const Color(0xFFC7D2FE),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    isDeepScan
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isDeepScan
                                      ? const Color(0xFF7E22CE)
                                      : const Color(0xFF4338CA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (isDeepScan) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  LucideIcons.search,
                                  size: 14,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isAi
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 350),
                        decoration: BoxDecoration(
                          color: isAi
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAi
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF4338CA),
                          ),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isAi
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_isWaiting,
                        style: TextStyle(
                          color: _isWaiting
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF111827),
                          fontSize: 13,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: _isWaiting
                              ? 'AI is thinking...'
                              : 'Ask your AI co-pilot...',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _isWaiting
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF4F46E5),
                      ),
                      onPressed: _isWaiting ? null : _sendMessage,
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
}

class CircularGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  CircularGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.7,
      math.pi * 1.6,
      false,
      bgPaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.7,
      math.pi * 1.6 * value,
      false,
      glowPaint,
    );

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.7,
      math.pi * 1.6 * value,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklinePainter extends CustomPainter {
  final Color color;
  final int index;
  SparklinePainter(this.color, this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final random = math.Random(index); // Stable seed
    path.moveTo(0, size.height * 0.7);

    for (var i = 1; i <= 10; i++) {
      path.lineTo(
        size.width * (i / 10),
        size.height * (0.3 + random.nextDouble() * 0.6),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
