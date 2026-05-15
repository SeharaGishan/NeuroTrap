import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/top_bar.dart';

const Color _navy = Color(0xFF0A1628);
const Color _card = Color(0xFF0F2340);
const Color _cyan = Color(0xFF00E5FF);
const Color _white = Colors.white;
const Color _aptColor = Color(0xFFFF4400);
const Color _green = Color(0xFF00E676);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(children: [
        SafeArea(child: Column(children: [
          NeuroTrapTopBar(parentContext: context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _green.withValues(alpha: 0.4)),
                    ),
                    child: const Text('NeuroTrap v1.0 — May 2026',
                      style: TextStyle(color: _green, fontSize: 12)),
                  )),
                  const SizedBox(height: 20),

                  _infoCard('About', Icons.info_outline_rounded,
                    'NeuroTrap is an AI-powered adaptive honeypot system that combines '
                    'XGBoost attacker profiling with Deep Q-Network (DQN) deception '
                    'to detect, classify and engage cyber attackers in real-time.\n\n'
                    'The system achieves 99.93% macro F1 score on attacker classification '
                    'and a 2,204% improvement in adversary engagement over baseline.'),

                  _infoCard('Developer', Icons.person_rounded,
                    'Name: Bedde K Samarasinghe\n'
                    'Plymouth Index: 10953243\n'
                    'Programme: BSc (Hons) Computer Security\n'
                    'University: University of Plymouth, UK\n'
                    'Partner: NSBM Green University\n'
                    'Module: PUSL3190 Computing Project\n'
                    'Supervisor: Mr. Chamara Disanayake'),

                  _infoCard('AI Pipeline', Icons.psychology_rounded,
                    '• XGBoost Attacker Profiler — 99.93% F1\n'
                    '• DQN Adaptive Deception Agent v3\n'
                    '• 32.9M SMOTE-balanced training samples\n'
                    '• 45 behavioural features\n'
                    '• 3 threat classes: Bot, Script Kiddie, APT\n'
                    '• 7 deception actions\n'
                    '• Real-time inference < 200ms'),

                  _infoCard('Infrastructure', Icons.cloud_rounded,
                    '• AWS EC2 — Singapore Region (ap-southeast-1)\n'
                    '• Cowrie SSH Honeypot\n'
                    '• OpenSearch 2.x — threat intelligence store\n'
                    '• Grafana — live attack dashboard\n'
                    '• OpenVPN — secure mobile access\n'
                    '• Firebase FCM — push notifications'),

                  _infoCard('Research Impact', Icons.science_rounded,
                    'NeuroTrap exceeds the published state-of-the-art benchmark '
                    'of 90% detection rate by 9.93 percentage points.\n\n'
                    'First operational integration of XGBoost + DQN in a single '
                    'closed-loop honeypot system with real-time mobile monitoring.'),

                  const SizedBox(height: 8),
                  Center(child: Text('© 2026 Bedde K Samarasinghe',
                    style: TextStyle(color: Colors.white38, fontSize: 11))),
                ],
              ),
            ),
          ),
        ])),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: NeuroTrapBottomNav(selectedIndex: -1)),
      ]),
    );
  }

  Widget _infoCard(String title, IconData icon, String content) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _cyan, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          color: _cyan, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      Text(content, style: const TextStyle(
        color: Colors.white70, fontSize: 12, height: 1.6)),
    ]),
  );
}
