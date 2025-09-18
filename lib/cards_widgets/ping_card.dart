import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class PingCard extends StatelessWidget {
  final int ping;

  const PingCard({super.key, this.ping = 12});

  Color getStatusColor() {
    if (ping <= 50) return Colors.greenAccent;
    if (ping <= 100) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Ping',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed, color: getStatusColor(), size: 28),
          const SizedBox(width: 8),
          Text(
            '$ping ms',
            style: TextStyle(
              color: getStatusColor(),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
