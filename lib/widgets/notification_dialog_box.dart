import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fyp/models/notification_model.dart';

class NotificationDetailDialog extends StatelessWidget {
  final SystemNotification notification;

  const NotificationDetailDialog({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final advice = _getAdviceForNotification(notification);

    return AlertDialog(
      title: Text(notification.type),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 12),
          Text(
            'Received: ${DateFormat('MMM d, yyyy - HH:mm').format(notification.timestamp)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommended Action:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(advice),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getAdviceForNotification(SystemNotification notification) {
    final msg = notification.message.toLowerCase();
    final type = notification.type.toLowerCase();

    if (type.contains('gas') || msg.contains('gas')) {
      return 'Trigger ventilation systems.Initiate safety shutdown protocols.Alert facility and security personnel.Evacuate personnel if levels are dangerous.Check your gas supply and ensure there is no leak. Ventilate the area immediately and call maintenance if the issue persists.';
    } else if (type.contains('temp') || msg.contains('temperature')) {
      return 'Check HVAC (cooling) system functionality.Ensure air filters are clean.Improve airflow or install additional cooling units.Consider relocating heat-intensive equipment.Monitor the temperature sensors. If temperature exceeds safe limits, turn off equipment and investigate possible overheating.';
    } else if (type.contains('network') || msg.contains('network')) {
      return 'Verify network connections and restart your router if needed. Contact IT support if the issue continues.';
    } else if (type.contains('critical')) {
      if (msg.contains('flame')) {
        return 'Activate fire suppression system.Immediately shut down affected systems.Alert emergency services and initiate evacuation.';
      }
      return 'Immediate attention required. Follow your emergency procedures.';
    } else if (type.contains('warning')) {
      if (msg.contains('sound')) {
        return 'Investigate for failing fans or power supplies.Inspect UPS systems for alarms.Isolate sources of mechanical noise.';
      } else if (msg.contains('diskUsage')) {
        return 'Clear unused logs and temporary files.Migrate data to secondary storage.Expand disk capacity or implement archiving policy.';
      } else if (msg.contains('memoryUsage')) {
        return 'Identify memory-hogging processes.Restart services or offload tasks to other servers.Consider increasing RAM or optimizing applications.';
      } else {
        return 'Monitor the system for changes. If the warning persists, escalate the issue to the maintenance team.';
      }
    } else {
      return 'No specific action. Please review the system status for more information.';
    }
  }
}
