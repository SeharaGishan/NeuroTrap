import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/top_bar.dart';

const Color _navy = Color(0xFF0A1628);
const Color _card = Color(0xFF0F2340);
const Color _cyan = Color(0xFF00E5FF);
const Color _white = Colors.white;

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

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
                  const Text('License & Agreement',
                    style: TextStyle(color: _white, fontSize: 22,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('NeuroTrap AI Honeypot System v1.0',
                    style: TextStyle(color: _cyan.withValues(alpha: 0.7),
                      fontSize: 12)),
                  const SizedBox(height: 20),
                  _section('MIT License',
                    'Copyright © 2026 Bedde K Samarasinghe\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy '
                    'of this software and associated documentation files (the "Software"), to deal '
                    'in the Software without restriction, including without limitation the rights '
                    'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                    'copies of the Software, and to permit persons to whom the Software is '
                    'furnished to do so, subject to the following conditions:\n\n'
                    'The above copyright notice and this permission notice shall be included in all '
                    'copies or substantial portions of the Software.'),
                  _section('Disclaimer',
                    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
                    'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
                    'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
                    'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
                    'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
                    'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'),
                  _section('Ethical Use Policy',
                    'NeuroTrap is developed exclusively for defensive cybersecurity research and '
                    'education. The system is designed to detect and analyse attacker behaviour '
                    'within a controlled honeypot environment.\n\n'
                    'Users must:\n'
                    '• Only deploy NeuroTrap on systems they own or have explicit permission to monitor\n'
                    '• Comply with all applicable laws and regulations in their jurisdiction\n'
                    '• Not use NeuroTrap or its data for offensive cyber operations\n'
                    '• Obtain appropriate institutional approval before deployment'),
                  _section('Third-Party Components',
                    '• Cowrie SSH Honeypot — MIT License\n'
                    '• OpenSearch — Apache License 2.0\n'
                    '• Grafana — AGPL-3.0 License\n'
                    '• XGBoost — Apache License 2.0\n'
                    '• PyTorch — BSD License\n'
                    '• Firebase — Google Terms of Service\n'
                    '• Flutter — BSD 3-Clause License\n'
                    '• AWS EC2 — Amazon Web Services Terms'),
                  _section('Academic Use',
                    'This software was developed as part of a BSc (Hons) Computer Security '
                    'final year project at University of Plymouth, UK in partnership with the '
                    'University of Plymouth (PUSL3190).\n\n'
                    'Plymouth Index: 10953243\n'
                    'Supervisor: Mr. Chamara Disanayake\n'
                    'Submission: May 2026'),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'By using NeuroTrap, you agree to the terms and conditions '
                      'outlined in this license agreement.',
                      style: TextStyle(color: Colors.white60, fontSize: 12,
                        height: 1.5, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

  Widget _section(String title, String content) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
        color: _cyan, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(
        color: Colors.white70, fontSize: 12, height: 1.6)),
    ]),
  );
}
