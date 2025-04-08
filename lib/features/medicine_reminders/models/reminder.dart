import 'package:flutter/material.dart';

class MedicineReminder {
  final String id;
  final String medicineName;
  final TimeOfDay time;
  final DateTime date;
  final String dosage;
  final String notes;

  MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.time,
    required this.date,
    this.dosage = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'time': '${time.hour}:${time.minute}',
      'date': date.toIso8601String(),
      'dosage': dosage,
      'notes': notes,
    };
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return MedicineReminder(
      id: json['id'],
      medicineName: json['medicineName'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      date: DateTime.parse(json['date']),
      dosage: json['dosage'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
