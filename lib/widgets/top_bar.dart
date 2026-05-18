import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _navy    = Color(0xFF0D1F3C);
const Color _cyan    = Color(0xFF00E5FF);
const Color _white   = Colors.white;

class NeuroTrapTopBar extends StatelessWidget {
  final BuildContext parentContext;
  final bool showBack;

  const NeuroTrapTopBar({
    super.key,
    required this.parentContext,
    this.showBack = true,
  });

  String _greeting() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Hi';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return 'Hi ' + user.displayName!.split(' ').first;
    }
    final email = user.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return 'Hi';
    return 'Hi ' + name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        // Logo row - centered and large
        Center(
          child: Image.asset('assets/images/logo.png', height: 52,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Column(children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'NEURO', style: TextStyle(
                  color: _white, fontWeight: FontWeight.w900,
                  fontSize: 24, letterSpacing: 2)),
                TextSpan(text: 'TRAP', style: TextStyle(
                  color: _cyan, fontWeight: FontWeight.w900,
                  fontSize: 24, letterSpacing: 2)),
              ])),
              const Text('SECURITY THAT EVOLVES',
                style: TextStyle(color: _cyan, fontSize: 7, letterSpacing: 1.5)),
            ])),
        ),
        const SizedBox(height: 6),
        // Navigation row
        Row(children: [
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.pop(parentContext),
              child: const Icon(Icons.arrow_back_ios,
                color: _white, size: 20))
          else
            const SizedBox(width: 20),
          const Spacer(),
          Text(_greeting(),
            style: TextStyle(color: _white, fontSize: 13,
              fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
