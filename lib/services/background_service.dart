import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NeuroTrapTaskHandler());
}

class NeuroTrapTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BG] NeuroTrap monitoring started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    debugPrint('[BG] NeuroTrap alive: $timestamp');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[BG] NeuroTrap monitoring stopped');
  }
}

class NeuroTrapBackgroundService {

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'neurotrap_monitor',
        channelName: 'NeuroTrap Monitor',
        channelDescription: 'NeuroTrap is actively monitoring threats',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startService() async {
    init();
    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      serviceId: 1000,
      notificationTitle: 'NeuroTrap Active',
      notificationText: 'Monitoring for threats — tap to open',
      notificationIcon: null,
      notificationButtons: [],
      callback: startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
