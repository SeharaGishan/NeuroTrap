import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'neurotrap_critical',
    'NeuroTrap Critical Alerts',
    description: 'Critical threat alerts — shows on lock screen',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFFFF4400),
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
      onDidReceiveBackgroundNotificationResponse: _bgTapHandler,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
      criticalAlert: true, provisional: false);

    final token = await messaging.getToken();
    debugPrint('[FCM] Token: $token');

    // Foreground
    FirebaseMessaging.onMessage.listen((msg) {
      showLocalNotification(msg);
      _navigateToAlert(msg.data);
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _navigateToAlert(msg.data);
    });

    // Killed app
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(seconds: 1),
        () => _navigateToAlert(initial.data));
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final data  = message.data;
    final cls   = data['classification'] ?? '';
    final ip    = data['src_ip'] ?? '--';
    final isAPT = cls == 'advanced_adversary';
    final isSK  = cls == 'script_kiddie';

    if (!isAPT && !isSK) return; // Only alert for threats

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
          // Full screen intent — shows on lock screen
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          // Wake up screen
          enableLights: true,
          ledColor: isAPT ? const Color(0xFFFF4400) : const Color(0xFFFFEA00),
          ledOnMs: 300, ledOffMs: 300,
          // Vibration pattern
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          // Show even in DND
          audioAttributesUsage: AudioAttributesUsage.alarm,
          styleInformation: BigTextStyleInformation(body),
          // Actions on notification
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
      navigatorKey?.currentState?.pushNamed('/alert', arguments: {
        'classification': cls,
        'src_ip':         data['src_ip'] ?? '--',
        'confidence':     double.tryParse(data['confidence']?.toString() ?? '0') ?? 0.0,
        'dqn_action':     data['dqn_action'] ?? '--',
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

@pragma('vm:entry-point')
void _bgTapHandler(NotificationResponse details) {
  // Background tap handled by onMessageOpenedApp
}
