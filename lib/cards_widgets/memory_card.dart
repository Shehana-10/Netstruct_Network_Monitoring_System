import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class TemperatureCard extends StatelessWidget {
  const TemperatureCard({super.key});

  final double currentTemperature = 72.0; // Current temperature (in °F)
  final double maxTemperature = 100.0; // Maximum threshold temperature (in °F)

  double get temperaturePercent =>
      (currentTemperature / maxTemperature).clamp(0.0, 1.0);

  Color getTemperatureColor() {
    if (temperaturePercent <= 0.6) return Colors.blueAccent; // Cool
    if (temperaturePercent <= 0.8) return Colors.orangeAccent; // Moderate
    return Colors.redAccent; // Hot
  }

  String getStatusText() {
    if (temperaturePercent <= 0.6) return "Temperature is normal";
    if (temperaturePercent <= 0.8) return "Temperature is getting warm";
    return "High temperature!";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return DashboardCard(
      title: 'Temperature',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.thermostat_outlined,
            size: isMobile ? 48 : 80,
            color: getTemperatureColor(),
          ),

          // Progress bar with adaptive width
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 6,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade800,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: temperaturePercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: getTemperatureColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),

          // Temperature Text
          Text(
            '${currentTemperature.toStringAsFixed(1)}°F / ${maxTemperature.toStringAsFixed(1)}°F',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 14 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Status
          Text(
            getStatusText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 12 : 16,
              color: getTemperatureColor().withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
