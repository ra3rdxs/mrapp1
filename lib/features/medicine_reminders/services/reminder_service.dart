import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  static const String _remindersKey = 'medicine_reminders';
  // Make notification service accessible from outside
  final NotificationService notificationService = NotificationService();

  // Initialize notification service
  Future<void> init() async {
    await notificationService.initialize();
  }

  // Get all reminders
  Future<List<MedicineReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reminderJson = prefs.getString(_remindersKey);

    if (reminderJson == null) {
      return [];
    }

    List<dynamic> decodedList = jsonDecode(reminderJson);
    return decodedList.map((item) => MedicineReminder.fromJson(item)).toList();
  }

  // Add a new reminder
  Future<void> addReminder(MedicineReminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);

    // Schedule notification
    final DateTime notificationTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    // Check if the notification time is in the future
    if (notificationTime.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Medicine Reminder',
        body:
            'Time to take ${reminder.medicineName}${reminder.dosage.isNotEmpty ? ' - ${reminder.dosage}' : ''}',
        scheduledDate: notificationTime,
      );
    } else {
      print('Notification time is in the past: $notificationTime');
    }
  }

  // Update an existing reminder
  Future<void> updateReminder(MedicineReminder updatedReminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);

    if (index != -1) {
      reminders[index] = updatedReminder;
      await _saveReminders(reminders);

      // Cancel previous notification and schedule a new one
      await notificationService.cancelNotification(updatedReminder.id.hashCode);

      // Schedule notification
      final DateTime notificationTime = DateTime(
        updatedReminder.date.year,
        updatedReminder.date.month,
        updatedReminder.date.day,
        updatedReminder.time.hour,
        updatedReminder.time.minute,
      );

      // Check if the notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        await notificationService.scheduleNotification(
          id: updatedReminder.id.hashCode,
          title: 'Medicine Reminder',
          body:
              'Time to take ${updatedReminder.medicineName}${updatedReminder.dosage.isNotEmpty ? ' - ${updatedReminder.dosage}' : ''}',
          scheduledDate: notificationTime,
        );
      } else {
        print('Updated notification time is in the past: $notificationTime');
      }
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((reminder) => reminder.id == id);
    await _saveReminders(reminders);

    // Cancel notification
    await notificationService.cancelNotification(id.hashCode);
  }

  // Save reminders to SharedPreferences
  Future<void> _saveReminders(List<MedicineReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        reminders.map((reminder) => reminder.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(jsonList));
  }
}
