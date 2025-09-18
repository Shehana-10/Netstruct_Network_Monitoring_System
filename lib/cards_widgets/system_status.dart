// system_status.dart
import 'package:flutter/material.dart';

class SystemStatus extends StatelessWidget {
  const SystemStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'System Status',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statusRow(Icons.wifi, 'Network: Connected', Colors.green),
              SizedBox(height: 8),
              _statusRow(Icons.storage, 'Disk Usage: Normal', Colors.orange),
              SizedBox(height: 8),
              _statusRow(Icons.memory, 'CPU Load Size: 23%', Colors.blue),
              SizedBox(height: 8),
              _statusRow(Icons.thermostat, 'Temperature  : 28°C', Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
