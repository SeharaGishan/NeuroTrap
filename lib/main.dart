import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/vpn/vpn_screen.dart';
import 'screens/threat_alert/threat_alert_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize(navigatorKey);
  runApp(const NeuroTrapApp());
}

class NeuroTrapApp extends StatelessWidget {
  const NeuroTrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroTrap',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'KdamThmorPro',
      ),
      initialRoute: '/',
      routes: {
        '/':        (ctx) => const LandingScreen(),
        '/sign-in': (ctx) => const SignInScreen(),
        '/sign-up': (ctx) => const SignUpScreen(),
        '/verify':  (ctx) => const VerificationScreen(),
        '/vpn':     (ctx) => const VpnScreen(),
        '/home':    (ctx) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/alert') {
          final args = (settings.arguments as Map<String, dynamic>?) ?? {};
          return MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => ThreatAlertScreen(
              classification: args['classification'] ?? 'script_kiddie',
              sourceIp:       args['src_ip'] ?? '--',
              confidence:     (args['confidence'] as num?)?.toDouble() ?? 0.0,
              dqnAction:      args['dqn_action'] ?? '--',
            ),
          );
        }
        return null;
      },
    );
  }
}
