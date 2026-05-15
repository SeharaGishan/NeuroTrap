import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/settings/settings_screen.dart';

const Color _cyan     = Color(0xFF00E5FF);
const Color _navy     = Color(0xFF0A1628);
const Color _card     = Color(0xFF0F2340);
const Color _aptColor = Color(0xFFFF4400);
const Color _white    = Colors.white;

class NeuroTrapBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const NeuroTrapBottomNav({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  Future<void> _handleShutdown(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.power_settings_new, color: _aptColor, size: 22),
          SizedBox(width: 10),
          Flexible(child: Text('Shutdown NeuroTrap',
            style: TextStyle(color: _white, fontSize: 16))),
        ]),
        content: const Text(
          'This will:\n\n'
          '• Mute all push notifications\n'
          '• Sign you out of the app\n\n'
          'The AI pipeline continues running on AWS.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _cyan)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _aptColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Shutdown',
              style: TextStyle(color: _white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const _ShutdownAnim()));
    try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
    await Future.delayed(const Duration(seconds: 3));
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  void _confirmSignOut(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sign Out', style: TextStyle(color: _white)),
      content: const Text('Sign out of NeuroTrap?',
        style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _cyan))),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await FirebaseAuth.instance.signOut();
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          },
          child: const Text('Sign Out',
            style: TextStyle(color: _aptColor)),
        ),
      ],
    ),
  );

  void _onNavTap(BuildContext context, int i) {
    if (onTap != null) onTap!(i);
    switch (i) {
      case 0: _confirmSignOut(context); break;
      case 1:
        if (selectedIndex != 1) Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AlertsScreen()));
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context, '/home', (r) => false);
        break;
      case 3:
        if (selectedIndex != 3) Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 4: _handleShutdown(context); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.logout,                'label': 'Sign Out'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.home_rounded,          'label': 'Home'},
      {'icon': Icons.settings_rounded,      'label': 'Settings'},
      {'icon': Icons.power_settings_new,    'label': 'Shutdown'},
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SafeArea(top: false, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final idx      = e.key;
              final item     = e.value;
              final isHome   = idx == 2;
              final selected = idx == selectedIndex;

              return GestureDetector(
                onTap: () => _onNavTap(context, idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: isHome
                      ? const EdgeInsets.all(10)
                      : const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? _cyan.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(isHome ? 50 : 10),
                    border: selected
                        ? Border.all(
                            color: _cyan.withValues(alpha: 0.4), width: 1)
                        : null,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(item['icon'] as IconData,
                      color: selected ? _cyan : Colors.white38, size: 22),
                    const SizedBox(height: 3),
                    Text(item['label'] as String,
                      style: TextStyle(
                        color: selected ? _cyan : Colors.white38,
                        fontSize: 9)),
                  ]),
                ),
              );
            }).toList(),
          )),
        ),
      ),
    );
  }
}

// ── Shutdown animation ────────────────────────────────────────────────────────
class _ShutdownAnim extends StatefulWidget {
  const _ShutdownAnim();
  @override
  State<_ShutdownAnim> createState() => _ShutdownAnimState();
}

class _ShutdownAnimState extends State<_ShutdownAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;
  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _spin.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(turns: _spin,
          child: const Icon(Icons.settings_rounded,
            color: Colors.white38, size: 48)),
        const SizedBox(height: 20),
        const Text('Shutting Down',
          style: TextStyle(color: Colors.white60,
            fontSize: 16, letterSpacing: 2)),
        const SizedBox(height: 60),
        Image.asset('assets/images/logo.png', height: 44,
          errorBuilder: (_, __, ___) => const Text('NEUROTRAP',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 20))),
        const SizedBox(height: 8),
        const Text('SECURITY THAT EVOLVES',
          style: TextStyle(color: Colors.white38,
            fontSize: 8, letterSpacing: 2)),
      ],
    )),
  );
}
