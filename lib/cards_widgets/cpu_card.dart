import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dashboard_card.dart';
import 'mini_chart.dart';

class CpuCard extends StatelessWidget {
  const CpuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Mobile size detection

    return SizedBox(
      width: isMobile ? 250 : 300, // Adjusted card width for mobile
      height: isMobile ? 300 : 350, // Adjusted card height for mobile
      child: DashboardCard(
        title: 'CPU',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: isMobile ? 180 : 220, // Adjusted gauge height for mobile
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.15,
                      thicknessUnit: GaugeSizeUnit.factor,
                      color: Color(0xFF1E3A5F),
                    ),
                    pointers: const [
                      RangePointer(
                        value: 35,
                        width: 0.15,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: Color(0xFF00C9A7),
                      ),
                    ],
                    annotations: const [
                      GaugeAnnotation(
                        widget: Text(
                          '35%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(height: 5, child: MiniChart()),
            ),
          ],
        ),
      ),
    );
  }
}
