import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Mobile size detection

    return DashboardCard(
      title: 'Network Traffic',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Align to the top
        children: [
          // Adjusted icon size for mobile
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Icon(
                Icons.wifi,
                color: Colors.green,
                size: isMobile ? 48 : 90, // Smaller icon for mobile
              ),
            ),
          ),
          const SizedBox(height: 35), // Space between icon and progress bar
          Padding(
            padding: const EdgeInsets.only(
              bottom: 30,
            ), // Adjusted padding to reduce space
            child: Container(
              height: 6,
              width: isMobile ? 150 : double.infinity, // Smaller bar on mobile
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.cyanAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // Added Padding or SizedBox to push the Row up
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
            ), // Push Row closer to the top
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_upward,
                  color: Colors.lightBlueAccent,
                  size: isMobile ? 20 : 24, // Smaller icons for mobile
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  '23.5 Mbps',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 14 : 18, // Smaller text for mobile
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: isMobile ? 16 : 24,
                ), // Adjust spacing for mobile
                Icon(
                  Icons.arrow_downward,
                  color: Colors.cyanAccent,
                  size: isMobile ? 20 : 24, // Smaller icons for mobile
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  '118.2 Mbps',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 14 : 18, // Smaller text for mobile
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
