import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class KernelShieldPage extends StatefulWidget {
  final Map<String, dynamic> metrics;
  final io.Socket? socket;

  const KernelShieldPage({super.key, required this.metrics, this.socket});

  @override
  State<KernelShieldPage> createState() => _KernelShieldPageState();
}

class _KernelShieldPageState extends State<KernelShieldPage> {
  bool isScanning = false;

  void handleScan() {
    setState(() => isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanning = false);
    });
  }

  void handleFlush(String name) {
    widget.socket?.emit('flush_memory', {'name': name});
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> leaks = widget.metrics['leaks'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.shield,
                        color: Color(0xFF4F46E5),
                        size: 28,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Kernel Shield',
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
                    'Low-level memory audit and behavioral analysis for memory leaks.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: isScanning ? null : handleScan,
                icon: Icon(
                  isScanning ? LucideIcons.loader2 : LucideIcons.search,
                  size: 18,
                ),
                label: Text(
                  isScanning ? 'Auditing memory...' : 'Deep Scan Memory',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF4F46E5),
                  foregroundColor: isScanning
                      ? const Color(0xFF6B7280)
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _memoryScannerGrid()),
              const SizedBox(width: 25),
              Expanded(flex: 2, child: _leakList(leaks)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memoryScannerGrid() {
    return Container(
      height: 480,
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
          _cardHeader('Memory Map Audit', LucideIcons.box),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                // Mock grid coloring
                Color color = const Color(0xFFF3F4F6);
                if (index % 7 == 0)
                  color = const Color(0xFFEF4444).withOpacity(0.6);
                if (index % 11 == 0)
                  color = const Color(0xFF4F46E5).withOpacity(0.6);

                return AnimatedOpacity(
                  opacity: isScanning ? (index % 3 == 0 ? 0.3 : 1.0) : 1.0,
                  duration: Duration(milliseconds: 300 + (index * 5)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _heapStatusIndicator(),
        ],
      ),
    );
  }

  Widget _heapStatusIndicator() {
    final bool hasleaks = (widget.metrics['leaks']?.length ?? 0) > 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KERNEL HEAP STATUS',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              hasleaks ? 'ANOMALIES DETECTED' : 'STABLE',
              style: TextStyle(
                color: hasleaks
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF22C55E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hasleaks ? 0.7 : 0.35,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasleaks ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _leakList(List<dynamic> leaks) {
    return Container(
      height: 480,
      padding: const EdgeInsets.all(30),
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
          _cardHeader('Detected Memory Leaks', LucideIcons.hardDrive),
          const SizedBox(height: 30),
          Expanded(
            child: leaks.isEmpty
                ? const Center(
                    child: Text(
                      'No active memory leaks detected.',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: leaks.length,
                    itemBuilder: (context, index) {
                      final leak = leaks[index];
                      return _leakEntry(leak);
                    },
                  ),
          ),
          const SizedBox(height: 20),
          _autoFlushInfo(),
        ],
      ),
    );
  }

  Widget _leakEntry(dynamic leak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leak['name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Expanded(
            child: Text(
              leak['mem'] ?? '0MB',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${(leak['cpu'] as num).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => handleFlush(leak['name']),
            icon: const Icon(LucideIcons.zap, size: 12),
            label: const Text('Flush'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFFECACA), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoFlushInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.info, size: 16, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Flush Protocol',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Optimizing inactive memory pages exceeding 500MB.',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 11,
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
