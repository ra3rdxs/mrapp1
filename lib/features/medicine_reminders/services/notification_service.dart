import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Singleton pattern
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal();

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicine_reminder_channel',
      'Medicine Reminders',
      description: 'Notifications for medicine reminders',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      showBadge: true,
    );

    // Create the notification channel on Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    // Request permission on iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true, critical: true);

    // Note: Android 13+ permissions are requested in the AndroidManifest.xml

    _isInitialized = true;
    print('Notification service initialized successfully');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Print debug information
    print('Attempting to schedule notification:');
    print('ID: $id');
    print('Title: $title');
    print('Body: $body');
    print('Scheduled for: ${scheduledDate.toString()}');

    if (scheduledDate.isBefore(DateTime.now())) {
      print('Scheduled date is in the past. Sending immediate notification.');
      await showImmediateNotification(id: id, title: title, body: body);
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminder_channel',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Medicine Reminder',
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: 'medicine_reminder_$id'
      );
      print('Notification scheduled successfully for $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
      print('Fallback: Sending immediate notification.');
      await showImmediateNotification(id: id, title: title, body: body);
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminder_channel',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Medicine Reminder',
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        payload: 'medicine_reminder_$id',
      );
      print('Immediate notification sent successfully');
    } catch (e) {
      print('Error showing immediate notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('Notification with ID $id canceled');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('All notifications canceled');
  }

  Future<bool> requestPermission() async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // For iOS
    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true, critical: true);
      return result ?? false;
    }
    // For Android
    else if (Platform.isAndroid) {
      // Android 13+ (API level 33) requires explicit permission request
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      return grantedNotificationPermission ?? false;
    }

    return false;
  }

  // Check if notifications are permitted
  Future<bool> areNotificationsPermitted() async {
    if (Platform.isIOS) {
      // iOS permission check - we'll need to check directly
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: false, badge: false, sound: false);

      // If null or false, permissions are not granted
      return result ?? false;
    } else if (Platform.isAndroid) {
      // Android permission check
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? areEnabled =
          await androidImplementation?.areNotificationsEnabled();
      return areEnabled ?? false;
    }
    return false;
  }

  // This method checks if permissions are granted and requests them if they aren't
  Future<bool> checkAndRequestPermissions(BuildContext context) async {
    final bool hasPermission = await areNotificationsPermitted();

    if (!hasPermission) {
      // Show dialog explaining why we need permissions
      final bool shouldRequest =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Notification Permission'),
                  content: const Text(
                    'To receive medicine reminders, you need to allow notifications. Would you like to enable notifications?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No, thanks'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes, enable'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (shouldRequest) {
        return await requestPermission();
      }
      return false;
    }

    return true;
  }
}
