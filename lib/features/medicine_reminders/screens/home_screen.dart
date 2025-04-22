import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/add_reminder_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  List<MedicineReminder> _reminders = [];
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkNotificationPermissions();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _reminderService.init();
      final reminders = await _reminderService.getReminders();
      final user = await _authService.getCurrentUser();

      setState(() {
        _reminders = reminders;
        _username = user?.username ?? 'User';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkNotificationPermissions() async {
    final hasPermission = await _reminderService.notificationService
        .checkAndRequestPermissions(context);
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is required for medicine reminders',
            ),
          ),
        );
      }
    }
  }

  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<MedicineReminder>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AddReminderModal(),
    );

    if (result != null) {
      try {
        await _reminderService.addReminder(result);
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding reminder: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteReminder(MedicineReminder reminder) async {
    try {
      await _reminderService.deleteReminder(reminder.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminder: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editReminder(MedicineReminder reminder) async {
    final result = await showModalBottomSheet<MedicineReminder>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddReminderModal(reminder: reminder),
    );

    if (result != null) {
      try {
        await _reminderService.updateReminder(result);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reminder updated')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating reminder: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _testNotification(MedicineReminder reminder) async {
    try {
      final hasPermission = await _reminderService.notificationService
          .checkAndRequestPermissions(context);

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot send notification: Permission denied'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending test notification...')),
      );

      final notificationService = _reminderService.notificationService;
      await notificationService.initialize();

      final testId = DateTime.now().millisecondsSinceEpoch % 10000;

      await notificationService.showImmediateNotification(
        id: testId,
        title: 'TEST: ${reminder.medicineName}',
        body: 'This is a test notification. Dosage: ${reminder.dosage}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent! Check your notifications.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: ${e.toString()}'),
        ),
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(date.year, date.month, date.day);

    if (reminderDate == today) {
      return 'Today';
    } else if (reminderDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders APP'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Hello, $_username',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _reminders.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No medicine reminders yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _addReminder,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add New Reminder'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _reminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _reminders[index];
                                return Dismissible(
                                  key: Key(reminder.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (_) => _deleteReminder(reminder),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        reminder.medicineName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatDate(reminder.date)} at ${_formatTime(reminder.time)}',
                                          ),
                                          if (reminder.dosage.isNotEmpty)
                                            Text('Dosage: ${reminder.dosage}'),
                                        ],
                                      ),
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Icon(
                                          Icons.medication,
                                          color: Colors.white,
                                        ),
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editReminder(reminder);
                                          } else if (value == 'delete') {
                                            _deleteReminder(reminder);
                                          } else if (value == 'test') {
                                            _testNotification(reminder);
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'test',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.notifications),
                                                    SizedBox(width: 8),
                                                    Text('Test'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}
