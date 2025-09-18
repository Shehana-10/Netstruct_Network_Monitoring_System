import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class PacketLossCard extends StatelessWidget {
  final double packetLoss;

  const PacketLossCard({super.key, this.packetLoss = 0.3});

  Color getStatusColor() {
    if (packetLoss <= 1.0) return Colors.greenAccent;
    if (packetLoss <= 3.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Packet Loss',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: getStatusColor(), size: 28),
          const SizedBox(width: 8),
          Text(
            '${packetLoss.toStringAsFixed(1)}%',
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
