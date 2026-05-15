import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/vpn/vpn_screen.dart';
import 'screens/threat_alert/threat_alert_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/contacts/contacts_screen.dart';
import 'screens/license/license_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize(navigatorKey);
  final user = FirebaseAuth.instance.currentUser;
  runApp(NeuroTrapApp(initialRoute: user != null ? '/home' : '/'));
}

class NeuroTrapApp extends StatelessWidget {
  final String initialRoute;
  const NeuroTrapApp({super.key, this.initialRoute = '/'});

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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/':        (ctx) => const LandingScreen(),
        '/sign-in': (ctx) => const SignInScreen(),
        '/sign-up': (ctx) => const SignUpScreen(),
        '/verify':  (ctx) => const VerificationScreen(),
        '/vpn':     (ctx) => const VpnScreen(),
        '/home':    (ctx) => const HomeScreen(),
        '/about':   (ctx) => const AboutScreen(),
        '/contacts':(ctx) => const ContactsScreen(),
        '/license': (ctx) => const LicenseScreen(),
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
