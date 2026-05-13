import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NeuroTrapApp());
}

class NeuroTrapApp extends StatelessWidget {
  const NeuroTrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroTrap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'KdamThmorPro',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/sign-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/verify': (context) => const VerificationScreen(),
        // '/home' will be added when Home screen is built
        '/home': (context) => const _TempHomeScreen(),
      },
    );
  }
}

// ── Temporary home screen placeholder until Home is built ─────────────────────
class _TempHomeScreen extends StatelessWidget {
  const _TempHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000319),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security_rounded,
              color: Color(0xFF00B3FF),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'NEUROTRAP',
              style: TextStyle(
                fontFamily: 'KdamThmorPro',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ Verified & Signed In',
              style: TextStyle(
                fontFamily: 'KdamThmorPro',
                fontSize: 14,
                color: Color(0xFF4CAF50),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'KdamThmorPro',
                  color: Color(0xFFEF5350),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}