import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SystemConfigPage extends StatefulWidget {
  final Map<String, dynamic> metrics;
  final io.Socket? socket;

  const SystemConfigPage({super.key, required this.metrics, this.socket});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  // Local states for instant feedback
  late bool autoMitigation;
  late bool aggressiveRecovery;
  late bool audioAlerts;

  @override
  void initState() {
    super.initState();
    autoMitigation = true;
    aggressiveRecovery = false;
    audioAlerts = false;
  }

  @override
  Widget build(BuildContext context) {
    bool isGamingMode = widget.metrics['gaming_mode'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'System Configuration',
            'Adjust global autonomous behavior and security thresholds.',
          ),
          const SizedBox(height: 40),
          _configSection('GAMING & OPTIMIZATION', [
            _toggleTile(
              'Gaming Awareness Mode',
              'Auto-relax security thresholds when a game is detected.',
              isGamingMode,
              (v) {
                widget.socket?.emit('toggle_gaming_mode', {'active': v});
              },
              activeColor: const Color(0xFFF59E0B),
            ),
            _toggleTile(
              'Nova Turbo Mode',
              'Suspend and throttle non-essential background tasks.',
              widget.metrics['turbo_mode'] ?? false,
              (v) {
                widget.socket?.emit('toggle_turbo_mode', {'active': v});
              },
              activeColor: const Color(0xFF4F46E5),
            ),
          ]),
          const SizedBox(height: 30),
          _configSection('AI AGENT BEHAVIOR', [
            _toggleTile(
              'Autonomous Mitigation',
              'Allow AI to terminate high-risk processes without approval.',
              autoMitigation,
              (v) => setState(() => autoMitigation = v),
              activeColor: const Color(0xFF4F46E5),
            ),
            _toggleTile(
              'Aggressive Recovery',
              'Immediately flush memory of background apps if RAM > 80%.',
              aggressiveRecovery,
              (v) => setState(() => aggressiveRecovery = v),
              activeColor: const Color(0xFF4F46E5),
            ),
          ]),
          const SizedBox(height: 30),
          _configSection('ALERTS & FEEDBACK', [
            _toggleTile(
              'Audio Feedback',
              'Aether AI will announce critical system state changes.',
              audioAlerts,
              (v) => setState(() => audioAlerts = v),
              activeColor: const Color(0xFF4F46E5),
            ),
          ]),
          const SizedBox(height: 30),
          _configSection('PERFORMANCE BOOST', [
            _actionTile(
              'Neural Accelerator (GPU)',
              '10x faster AI response by offloading neural tasks to local GPU.',
              Icons.bolt,
              () {
                _showBoostDialog(context);
              },
              color: const Color(0xFF8B5CF6),
            ),
          ]),
        ],
      ),
    );
  }

  void _showBoostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'ACTIVATE NEURAL BOOST?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will optimize local AI libraries for your GPU. No personal data will be shared.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Note: Python dependencies will be updated in the background.',
              style: TextStyle(
                color: const Color(0xFF4F46E5).withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.socket?.emit('upgrade_gpu_request');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF4F46E5),
                  content: Text(
                    'Optimization started in background...',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'ACTIVATE NOW',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color color = const Color(0xFF4F46E5),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _configSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4F46E5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF3F4F6),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    Color activeColor = const Color(0xFF4F46E5),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: activeColor.withOpacity(0.2),
                activeColor: activeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
