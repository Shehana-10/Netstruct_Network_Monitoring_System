import 'package:flutter/material.dart';

class SystemNotification {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool read;

  SystemNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory SystemNotification.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      try {
        if (timestamp is DateTime) {
          return timestamp.toUtc();
        }

        if (timestamp is String) {
          // Handle Postgres format "2025-07-13 13:56:33.656129+00"
          if (timestamp.contains(' ') && timestamp.contains('+')) {
            timestamp = timestamp.replaceFirst(' ', 'T');
          }

          if (!timestamp.endsWith('Z') && !timestamp.contains('+')) {
            timestamp += 'Z';
          }

          return DateTime.parse(timestamp).toUtc();
        }
      } catch (e) {
        debugPrint('Timestamp parsing error: $e');
      }
      return DateTime.now().toUtc();
    }

    return SystemNotification(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      read: map['read'] ?? false,
    );
  }
}
