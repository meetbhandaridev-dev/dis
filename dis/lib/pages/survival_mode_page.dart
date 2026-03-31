import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SurvivalModePage extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final io.Socket? socket;

  const SurvivalModePage({super.key, required this.metrics, this.socket});

  @override
  Widget build(BuildContext context) {
    final bool isActive = metrics['survival_mode'] ?? false;

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFEF2F2) : const Color(0xFFF5F7FB),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _powerButton(isActive),
              const SizedBox(height: 40),
              Text(
                isActive
                    ? 'EMERGENCY SURVIVAL ACTIVE'
                    : 'SURVIVAL PROTOCOL IDLE',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF111827),
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Immediate priority hijacking to prevent imminent kernel panic or hardware failure.',
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Row(
                children: [
                  Expanded(
                    child: _protocolCard(
                      LucideIcons.zapOff,
                      'Power-Save Throttling',
                      isActive,
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    child: _protocolCard(
                      LucideIcons.activity,
                      'Kernel Scheduler',
                      isActive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (isActive) _emergencyBanner() else _idleStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _powerButton(bool active) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => socket?.emit('toggle_survival_mode', {'active': !active}),
        borderRadius: BorderRadius.circular(60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEF4444) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? const Color(0xFFB91C1C) : const Color(0xFFE5E7EB),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFFEF4444).withOpacity(0.4)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 30,
                spreadRadius: active ? 10 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.power,
            size: 48,
            color: active ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _protocolCard(IconData icon, String title, bool active) {
    return Container(
      padding: const EdgeInsets.all(30),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
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
            children: [
              Icon(
                icon,
                color: active
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF4F46E5),
                size: 24,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          if (title.contains('Power'))
            _powerList(active)
          else
            Text(
              active
                  ? 'Prioritizing core system threads. All non-essential background processes are operating on restricted CPU cycles.'
                  : 'Kernel scheduler is operating in Standard Balance mode. User processes have full access to hardware threads.',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _powerList(bool active) {
    return Column(
      children: [
        _listItem('Background Sync', active ? 'SUSPENDED' : 'ACTIVE', active),
        const SizedBox(height: 14),
        _listItem('Indexing Services', active ? 'SUSPENDED' : 'ACTIVE', active),
        const SizedBox(height: 14),
        _listItem('System Updates', active ? 'DISABLED' : 'QUEUED', active),
      ],
    );
  }

  Widget _listItem(String label, String status, bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: active ? const Color(0xFFEF4444) : const Color(0xFF059669),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldAlert, color: Color(0xFFEF4444), size: 28),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION CRITICAL STATE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB91C1C),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Bypassing group policies to maintain OS core stability. Please close all resource-intensive applications immediately.',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idleStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle2, color: Color(0xFF059669), size: 20),
          SizedBox(width: 12),
          Text(
            'SYSTEM OPERATING WITHIN CONSTRAINTS',
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
