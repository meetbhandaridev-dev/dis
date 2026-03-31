import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Import Custom Widgets
// Minimal Light Design System Components
import 'widgets/glitch_toast.dart';
import 'widgets/command_palette.dart';

// Import Pages
import 'pages/dashboard_page.dart';
import 'pages/command_log_page.dart';
import 'pages/neural_lab_page.dart';
import 'pages/predictive_analysis_page.dart';
import 'pages/kernel_shield_page.dart';
import 'pages/survival_mode_page.dart';
import 'pages/system_config_page.dart';

void main() {
  runApp(const QunetXApp());
}

class QunetXApp extends StatelessWidget {
  const QunetXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOVA SHIELD AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardColor: Colors.white,
        primaryColor: const Color(0xFF4F46E5),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false; // Starts closed as requested
  late io.Socket socket;
  bool isConnected = false;
  Process? _backendProcess;

  // System State Management
  double cpu = 0.0;
  double ram = 0.0;
  double disk = 0.0;
  double network = 0.0;
  double temp = 0.0;
  int riskScore = 0;
  String topHog = "System";
  List<FlSpot> cpuHistory = [];
  List<FlSpot> ramHistory = [];
  List<Map<String, dynamic>> logs = [];
  Map<String, dynamic> advancedMetrics = {};
  List<Map<String, dynamic>> activeToasts = [];
  bool isCommandPaletteOpen = false;

  @override
  void initState() {
    super.initState();
    _startBackend(); // Start the AI Engine
    _initSocket();
    for (int i = 0; i < 20; i++) {
      cpuHistory.add(FlSpot(i.toDouble(), 0));
      ramHistory.add(FlSpot(i.toDouble(), 0));
    }
  }

  Future<void> _startBackend() async {
    try {
      if (kDebugMode) {
        print("Running in Debug Mode: Manually start your python app.py");
        return;
      }

      // Release mode: backend executable in relative folder
      final String baseDir = File(Platform.resolvedExecutable).parent.path;
      final String exePath = "$baseDir\\backend\\app.exe";

      print("Starting AI Engine at: $exePath");

      _backendProcess = await Process.start(
        exePath,
        [],
        runInShell: true,
        mode: ProcessStartMode.detachedWithStdio,
        workingDirectory: "$baseDir\\backend",
      );

      print("AI Engine Started with PID: ${_backendProcess?.pid}");

      // Auto-kill backend when Flutter is closed
      ProcessSignal.sigterm.watch().listen((_) => _backendProcess?.kill());
    } catch (e) {
      print("Failed to start AI Engine: $e");
    }
  }

  void _initSocket() {
    socket = io.io(
      'http://127.0.0.1:8888',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .build(),
    );

    socket.onConnect((_) {
      setState(() => isConnected = true);
      socket.emit('get_history'); // Fetch past metrics for persistent UI
      debugPrint('Connected to System Agent');
    });

    socket.onConnectError((data) {
      debugPrint('Connection Error: $data');
      if (mounted) setState(() => isConnected = false);
    });

    socket.onDisconnect((_) {
      setState(() => isConnected = false);
      debugPrint('Disconnected from Agent');
    });

    socket.on('system_metrics', (data) {
      if (!mounted) return;
      setState(() {
        cpu = (data['cpu'] ?? 0.0).toDouble();
        ram = (data['ram'] ?? 0.0).toDouble();
        disk = (data['disk'] ?? 0.0).toDouble();
        network = (data['network'] ?? 0.0).toDouble();
        temp = (data['temp'] ?? 0.0).toDouble();
        riskScore = data['risk_score'] ?? 0;
        topHog = data['top_hog'] ?? "System";

        cpuHistory.removeAt(0);
        ramHistory.removeAt(0);
        for (int i = 0; i < cpuHistory.length; i++) {
          cpuHistory[i] = FlSpot(i.toDouble(), cpuHistory[i].y);
          ramHistory[i] = FlSpot(i.toDouble(), ramHistory[i].y);
        }
        cpuHistory.add(FlSpot(19, cpu));
        ramHistory.add(FlSpot(19, ram));
      });
    });

    socket.on('advanced_metrics', (data) {
      if (!mounted) return;
      setState(() {
        advancedMetrics = data;
      });
    });

    socket.on('new_log', (data) {
      if (!mounted) return;
      setState(() {
        logs.insert(0, data);
        if (logs.length > 50) logs.removeLast();
      });
    });

    socket.on('history_data', (data) {
      if (!mounted) return;
      List<dynamic> history = data as List<dynamic>;
      List<FlSpot> cpuSpots = [];
      List<FlSpot> ramSpots = [];
      for (int i = 0; i < history.length; i++) {
        cpuSpots.add(
          FlSpot(i.toDouble(), (history[i]['cpu'] ?? 0.0).toDouble()),
        );
        ramSpots.add(
          FlSpot(i.toDouble(), (history[i]['ram'] ?? 0.0).toDouble()),
        );
      }
      setState(() {
        cpuHistory = cpuSpots;
        ramHistory = ramSpots;
      });
    });

    socket.on('ai_chat_response', (data) {
      if (!mounted) return;
      // You could store the last response here
      setState(() {
        advancedMetrics['last_ai_response'] = data['response'];
      });
    });

    socket.on('mitigation_request', (data) {
      _showMitigationDialog(data);
      _showGlitchToast(data);
    });
  }

  void _showGlitchToast(dynamic data) {
    setState(() {
      activeToasts.add(data);
    });
    // Auto remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          activeToasts.remove(data);
        });
      }
    });
  }

  void _showMitigationDialog(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111112),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, color: Colors.redAccent),
            const SizedBox(width: 10),
            const Text('AI MITIGATION REQUEST'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI detected risk in ${data['name']} (PID: ${data['pid']}).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trust Score:'),
                Text(
                  '${data['trust'] ?? 50}/100',
                  style: TextStyle(
                    color: (data['trust'] ?? 50) > 70
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Risk Level:'),
                Text(
                  data['risk'] == 2 ? 'CRITICAL' : 'WARNING',
                  style: TextStyle(
                    color: data['risk'] == 2
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'The process has been throttled or suspended. Terminate permanently?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              socket.emit('mitigation_response', {
                'pid': data['pid'],
                'approved': false,
              });
              Navigator.pop(context);
            },
            child: const Text(
              'IGNORE & TRUST',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              socket.emit('mitigation_response', {
                'pid': data['pid'],
                'approved': true,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('KILL PROCESS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 1100;

        return Scaffold(
          key: GlobalKey<ScaffoldState>(),
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: Colors.white,
                  child: _buildSidebar(isDrawer: true),
                ),
          backgroundColor: Colors.transparent,
          body: CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.keyK,
                control: true,
              ): () {
                setState(() => isCommandPaletteOpen = !isCommandPaletteOpen);
              },
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  _buildAmbientBackground(),
                  Row(
                    children: [
                      if (isDesktop) _buildSidebar(),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                isDesktop ? 20 : 60,
                                20,
                                20,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _getPage(_selectedIndex),
                              ),
                            ),
                            // Desktop toggle button (floating near the edge when sidebar is closed)
                            if (isDesktop && !_isSidebarOpen)
                              Positioned(
                                top: 15,
                                left: 15,
                                child: IconButton(
                                  icon: const Icon(
                                    LucideIcons.menu,
                                    color: Color(0xFF1F2937),
                                  ),
                                  onPressed: () =>
                                      setState(() => _isSidebarOpen = true),
                                ),
                              ),
                            if (!isDesktop)
                              Positioned(
                                top: 15,
                                left: 15,
                                child: Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(
                                      LucideIcons.menu,
                                      color: Color(0xFF1F2937),
                                    ),
                                    onPressed: () =>
                                        Scaffold.of(context).openDrawer(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: activeToasts
                          .map(
                            (t) => GlitchToast(
                              data: t,
                              onDismiss: () =>
                                  setState(() => activeToasts.remove(t)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (isCommandPaletteOpen)
                    CommandPalette(
                      isOpen: isCommandPaletteOpen,
                      onClose: () =>
                          setState(() => isCommandPaletteOpen = false),
                      socket: socket,
                      metrics: advancedMetrics,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmbientBackground() {
    return Container(color: const Color(0xFFF5F7FB));
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    double width = isDrawer ? 280 : (_isSidebarOpen ? 280 : 0);

    // If desktop and closed, we hide it completely to show the toggle button in the main area
    if (!isDrawer && !_isSidebarOpen) return const SizedBox.shrink();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Close button for Desktop
          if (!isDrawer)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => setState(() => _isSidebarOpen = false),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    color: Color(0xFF4F46E5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOVA',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'SHIELD AI',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _sidebarItem(0, LucideIcons.activity, 'Dashboard'),
                _sidebarItem(1, LucideIcons.terminal, 'Command Log'),
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                  child: Text(
                    'ADVANCED CORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _sidebarItem(2, LucideIcons.brainCircuit, 'Neural Insight Lab'),
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                  child: Text(
                    'CRASH PREVENTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _sidebarItem(3, LucideIcons.timer, 'Stability Time-Machine'),
                _sidebarItem(4, LucideIcons.hardDrive, 'Kernel Shield'),
                _sidebarItem(5, LucideIcons.power, 'Survival Mode'),
                _sidebarItem(6, LucideIcons.settings, 'System Config'),
              ],
            ),
          ),
          _buildConnectionStatus(),
          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              'v1.0.0 BETA',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context); // Close drawer on tap
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? const Color(0xFF111827)
                      : const Color(0xFF4B5563),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF22C55E).withOpacity(0.2)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBadge(
            isConnected ? 'AGENT CONNECTED' : 'AGENT OFFLINE',
            isConnected ? LucideIcons.signal : LucideIcons.signalLow,
            isConnected ? Colors.green : Colors.red,
          ),
          if (advancedMetrics['gaming_mode'] == true) ...[
            const SizedBox(height: 10),
            _buildStatusBadge(
              'GAMING MODE ACTIVE',
              LucideIcons.gamepad2,
              const Color(0xFFF59E0B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          cpu: cpu,
          ram: ram,
          disk: disk,
          temp: temp,
          riskScore: riskScore,
          cpuHistory: cpuHistory,
          ramHistory: ramHistory,
          logs: logs,
          advancedMetrics: advancedMetrics,
          socket: socket,
        );
      case 1:
        return CommandLogPage(logs: logs);
      case 2:
        return NeuralLabPage(dnaThreats: advancedMetrics['dna_threats'] ?? []);
      case 3:
        return PredictiveAnalysisPage(
          ramHistory: ramHistory,
          metrics: advancedMetrics,
          socket: socket,
        );
      case 4:
        return KernelShieldPage(metrics: advancedMetrics, socket: socket);
      case 5:
        return SurvivalModePage(metrics: advancedMetrics, socket: socket);
      case 6:
        return SystemConfigPage(metrics: advancedMetrics, socket: socket);
      default:
        return DashboardPage(
          cpu: 0,
          ram: 0,
          disk: 0,
          temp: 0,
          riskScore: 0,
          cpuHistory: const [],
          ramHistory: const [],
          logs: const [],
          advancedMetrics: const {},
        );
    }
  }
}
