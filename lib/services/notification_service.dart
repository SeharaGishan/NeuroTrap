import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showLocalNotification(message);
}

@pragma('vm:entry-point')
void bgTapHandler(NotificationResponse details) {}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'neurotrap_critical',
    'NeuroTrap Critical Alerts',
    description: 'Critical threat alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFFFF4400),
    showBadge: true,
  );

  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    const android  = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _local.initialize(settings,
      onDidReceiveNotificationResponse: (details) {
        _handleTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: bgTapHandler,
    );

    // Create channel with max importance
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permissions including full screen
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
      criticalAlert: true, provisional: false);

    // Set foreground notification presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);

    // Request all critical permissions
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();

    final token = await messaging.getToken();
    debugPrint('[FCM] Token: $token');

    // Foreground — auto-popup alert screen immediately
    FirebaseMessaging.onMessage.listen((msg) async {
      debugPrint('[FCM] onMessage received: ${msg.data}');
      final cls = msg.data['classification'] ?? '';
      if (cls == 'advanced_adversary' || cls == 'script_kiddie') {
        navigatorKey?.currentState?.pushNamed('/alert', arguments: {
          'classification': cls,
          'src_ip':         msg.data['src_ip'] ?? '--',
          'confidence':     double.tryParse(msg.data['confidence']?.toString() ?? '0') ?? 0.0,
          'dqn_action':     msg.data['dqn_action'] ?? '--',
        });
      }
    });

    // User tapped notification — open alert screen
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToAlert(msg.data);
      });
    });

    // Killed app
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(seconds: 2),
        () => _navigateToAlert(initial.data));
    }

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final data  = message.data;
    final cls   = data['classification'] ?? '';
    final ip    = data['src_ip'] ?? '--';
    final isAPT = cls == 'advanced_adversary';
    final isSK  = cls == 'script_kiddie';

    if (!isAPT && !isSK) return;

    final title = isAPT
        ? '🚨 CRITICAL — APT Detected!'
        : '⚠️ Script Kiddie Detected';
    final body  = 'Source: $ip  •  ${data['dqn_action'] ?? ''}';

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          // KEY: full screen intent shows alert on lock screen automatically
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          enableLights: true,
          ledColor: isAPT
              ? const Color(0xFFFF4400)
              : const Color(0xFFFFEA00),
          ledOnMs: 300, ledOffMs: 300,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(
            [0, 500, 200, 500, 200, 500]),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Auto cancel false — stays until user dismisses
          autoCancel: false,
          ongoing: false,
          styleInformation: BigTextStyleInformation(body),
          actions: [
            const AndroidNotificationAction(
              'open', 'OPEN NEUROTRAP',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'dismiss', 'Dismiss',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static void _navigateToAlert(Map<String, dynamic> data) {
    final cls = data['classification'] ?? '';
    if (cls == 'advanced_adversary' || cls == 'script_kiddie') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // not signed in — ignore
      // Push home first if not there, then alert on top
      navigatorKey?.currentState?.pushNamedAndRemoveUntil(
        '/home', (r) => false);
      Future.delayed(const Duration(milliseconds: 300), () {
        navigatorKey?.currentState?.pushNamed('/alert', arguments: {
          'classification': cls,
          'src_ip':         data['src_ip'] ?? '--',
          'confidence':     double.tryParse(
            data['confidence']?.toString() ?? '0') ?? 0.0,
          'dqn_action':     data['dqn_action'] ?? '--',
        });
      });
    }
  }

  static void _handleTap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateToAlert(data);
    } catch (_) {}
  }
}
