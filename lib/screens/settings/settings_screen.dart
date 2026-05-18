import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';

const Color _navy = Color(0xFF0A1628);
const Color _cyan = Color(0xFF00E5FF);
const Color _white = Colors.white;
const Color _card = Color(0xFF0F2340);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            // Top bar
            Container(
              color: const Color(0xFF0D1F3C),
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                    color: _white, size: 20)),
                const Spacer(),
                Image.asset('assets/images/logo.png', height: 32,
                  errorBuilder: (_, _, _) => const Text('NEUROTRAP',
                    style: TextStyle(color: _white,
                      fontWeight: FontWeight.w900, fontSize: 16))),
                const Spacer(),
                const Text('Hi Sehara',
                  style: TextStyle(color: _white, fontSize: 13)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  const Text('Settings',
                    style: TextStyle(color: _white, fontSize: 22,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _settingItem(Icons.notifications_rounded,
                    'Notifications', 'Manage alert preferences'),
                  _settingItem(Icons.vpn_lock_rounded,
                    'VPN Configuration', 'OpenVPN settings'),
                  _settingItem(Icons.security_rounded,
                    'Alert Threshold', 'Set threat sensitivity'),
                  _settingItem(Icons.palette_rounded,
                    'Appearance', 'Theme and display'),
                  _settingItem(Icons.info_outline_rounded,
                    'About NeuroTrap', 'Version and info'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ]),
        ),
        const Positioned(
          left: 0, right: 0, bottom: 0,
          child: NeuroTrapBottomNav(selectedIndex: 3)),
      ]),
    );
  }

  Widget _settingItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        Icon(icon, color: _cyan, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(
              color: Colors.white38, fontSize: 11)),
          ],
        )),
        const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ]),
    );
  }
}
