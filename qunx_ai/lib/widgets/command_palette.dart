import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CommandPalette extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final io.Socket socket;
  final Map<String, dynamic> metrics;

  const CommandPalette({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.socket,
    required this.metrics,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredItems = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredItems();
  }

  void _updateFilteredItems() {
    final leaksList = (widget.metrics['leaks'] as List?) ?? [];
    final threatsList = (widget.metrics['dna_threats'] as List?) ?? [];

    final leaks = leaksList
        .map(
          (l) =>
              Map<String, dynamic>.from(l as Map)
                ..addAll({'type': 'leak', 'risk': 'warning'}),
        )
        .toList();
    final threats = threatsList
        .map(
          (t) =>
              Map<String, dynamic>.from(t as Map)
                ..addAll({'type': 'threat', 'risk': 'critical'}),
        )
        .toList();

    final allItems = [
      ...leaks,
      ...threats,
      {
        'name': widget.metrics['top_hog'] ?? 'System',
        'cpu': '?',
        'type': 'hog',
        'risk': 'info',
      },
    ];

    // Unique by name
    final seen = <String>{};
    final uniqueItems = allItems
        .where((item) => seen.add(item['name'] as String))
        .toList();

    setState(() {
      filteredItems = uniqueItems
          .where(
            (item) => (item['name'] as String).toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
        }
      },
      child: Container(
        color: Colors.black54,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child:
              Container(
                    width: 600,
                    height: 450,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                size: 20,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (_) => _updateFilteredItems(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Search processes, services, or protocols...',
                                    hintStyle: TextStyle(color: Colors.white24),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Text(
                                  'ESC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Results
                        Expanded(
                          child: filteredItems.isEmpty
                              ? Center(
                                  child: Text(
                                    'No processes found matching "${_searchController.text}"',
                                    style: const TextStyle(
                                      color: Colors.white24,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredItems.length,
                                  padding: const EdgeInsets.all(10),
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    return _buildResultItem(item);
                                  },
                                ),
                        ),

                        // Footer
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '↑↓ to navigate • ↵ to select • ctrl+k to toggle',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white24,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Live Sync Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(),
        ),
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    Color riskColor = Colors.blueAccent;
    IconData icon = LucideIcons.terminal;

    if (item['type'] == 'threat') {
      riskColor = Colors.redAccent;
      icon = LucideIcons.shieldAlert;
    } else if (item['type'] == 'leak') {
      riskColor = Colors.orangeAccent;
      icon = LucideIcons.zap;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: riskColor, size: 18),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (item['risk'] as String? ?? 'INFO').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                    if (item['mem'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${item['mem']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                    if (item['cpu'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${item['cpu']}% CPU',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.socket.emit('flush_memory', {'name': item['name']});
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              elevation: 0,
            ),
            child: const Text('Terminate', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
