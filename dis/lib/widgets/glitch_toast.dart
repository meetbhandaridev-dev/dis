import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GlitchToast extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const GlitchToast({super.key, required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Background Glitch Layers
          ...List.generate(3, (index) {
            return Positioned.fill(
              child:
                  Opacity(
                        opacity: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.red
                                : (index == 1 ? Colors.blue : Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .move(
                        begin: const Offset(0, 0),
                        end: Offset(
                          Random().nextDouble() * 10 - 5,
                          Random().nextDouble() * 10 - 5,
                        ),
                        duration: 100.ms,
                        curve: Curves.elasticIn,
                      ),
            );
          }),

          // Main Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                          LucideIcons.shieldAlert,
                          color: Colors.redAccent,
                          size: 24,
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 500.ms, color: Colors.white),
                    const SizedBox(width: 15),
                    const Text(
                          'AI THREAT DETECTED',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        )
                        .animate()
                        .tint(color: Colors.white, duration: 200.ms)
                        .then()
                        .tint(color: Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  'System has identified suspicious activity in ${data['name']}. Risk Score: ${data['risk_score'] ?? 'URGENT'}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onDismiss,
                      child: const Text(
                        'DISMISS',
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: onDismiss, // For now just dismiss
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'QUARANTINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().shake(
            duration: 500.ms,
            hz: 10,
            offset: const Offset(4, 0),
          ),
        ],
      ),
    );
  }
}
