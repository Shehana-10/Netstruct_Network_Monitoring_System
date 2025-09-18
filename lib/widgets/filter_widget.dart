import 'package:flutter/material.dart';

class FilterCard extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isDeviceOnline;

  final String selectedTimeRange;
  final String selectedDevice;
  final String selectedSensor;

  final bool showDeviceDropdown;
  final List<String> sensorOptions;

  final ValueChanged<String?> onTimeRangeChanged;
  final ValueChanged<String?> onDeviceChanged;
  final ValueChanged<String?> onSensorChanged;

  const FilterCard({
    super.key,
    required this.onRefresh,
    required this.isDeviceOnline,
    required this.selectedTimeRange,
    required this.selectedDevice,
    required this.selectedSensor,
    required this.onTimeRangeChanged,
    required this.onDeviceChanged,
    required this.onSensorChanged,
    required this.sensorOptions,
    this.showDeviceDropdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF161B22) : Colors.grey[100]!;

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildDropdown(
              context: context,
              value: selectedTimeRange,
              items: ['Last 1hr', 'Last 2hr', 'Last 10hr', 'Last 24 hours'],
              textColor: textColor,
              onChanged: onTimeRangeChanged,
            ),
            if (showDeviceDropdown)
              _buildDropdown(
                context: context,
                value: selectedDevice,
                items: ['Switch 1', 'Switch 2'],
                textColor: textColor,
                onChanged: onDeviceChanged,
              ),
            _buildDropdown(
              context: context,
              value: selectedSensor,
              items: sensorOptions,
              textColor: textColor,
              onChanged: onSensorChanged,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton.icon(
                onPressed: isDeviceOnline ? onRefresh : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required Color textColor,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white : Colors.black54,
          ),
          dropdownColor: isDark ? const Color(0xFF0D1117) : Colors.white,
          style: TextStyle(color: textColor),
          onChanged: onChanged,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
