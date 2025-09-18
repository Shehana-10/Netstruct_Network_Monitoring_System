import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dashboard_card.dart';

class DiskCard extends StatelessWidget {
  const DiskCard({super.key});

  final double used = 120;
  final double total = 240;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 300,
      child: DashboardCard(
        title: 'Disk',
        child: Stack(
          alignment: Alignment.center,
          children: [
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: total,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.15,
                    thicknessUnit: GaugeSizeUnit.factor,
                    color: Color(0xFF1E3A5F),
                  ),
                  pointers: [
                    RangePointer(
                      value: used,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sd_storage_rounded,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 8),
                Text(
                  "${used.toInt()} GB / ${total.toInt()} GB",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
