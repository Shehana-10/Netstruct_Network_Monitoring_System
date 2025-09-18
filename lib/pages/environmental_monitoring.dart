import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnvironmentalMonitoringPage extends StatefulWidget {
  final Function(double) onTemperatureAlert;

  const EnvironmentalMonitoringPage({
    Key? key,
    required this.onTemperatureAlert,
  }) : super(key: key);

  @override
  _EnvironmentalMonitoringPageState createState() =>
      _EnvironmentalMonitoringPageState();
}

class _EnvironmentalMonitoringPageState
    extends State<EnvironmentalMonitoringPage> {
  double temperature = 0.0;
  double humidity = 0.0;
  double gas = 0.0;
  double vibration = 0.0;
  double sound = 0.0;
  double flame = 0.0;
  String deviceStatus = 'offline';
  bool temperatureAlertSent = false;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    listenToDeviceStatus();
    listenToSupabaseSensorData();
  }

  void listenToDeviceStatus() {
    final supabase = Supabase.instance.client;

    supabase
        .from('netstruct')
        .stream(primaryKey: ['uuid'])
        .order('timestamp', ascending: false)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final newStatus =
                data.last['status']?.toString().toLowerCase() ?? 'offline';

            setState(() {
              deviceStatus = newStatus;

              if (newStatus != 'online') {
                temperature = 0.0;
                humidity = 0.0;
                gas = 0.0;
                vibration = 0.0;
                sound = 0.0;
                flame = 0.0;
              }
            });
          }
        });
  }

  void listenToSupabaseSensorData() {
    final supabase = Supabase.instance.client;

    supabase
        .from('sensor_data')
        .stream(primaryKey: ['uuid'])
        .order('timestamp', ascending: false)
        .limit(1)
        .listen(
          (data) {
            if (data.isNotEmpty && mounted) {
              final row = data.last;

              if (deviceStatus == 'online') {
                setState(() {
                  temperature = (row['temperature'] as num?)?.toDouble() ?? 0.0;
                  humidity = (row['humidity'] as num?)?.toDouble() ?? 0.0;
                  gas = (row['gas'] as num?)?.toDouble() ?? 0.0;
                  vibration = (row['vibration'] as num?)?.toDouble() ?? 0.0;
                  sound = (row['sound'] as num?)?.toDouble() ?? 0.0;
                  flame = (row['flame'] as num?)?.toDouble() ?? 0.0;
                  lastUpdated = DateTime.now();
                });

                if (temperature > 35 && !temperatureAlertSent) {
                  widget.onTemperatureAlert(temperature);
                  sendNotificationToSupabase(temperature);
                  temperatureAlertSent = true;
                } else if (temperature <= 35 && temperatureAlertSent) {
                  temperatureAlertSent = false;
                }
              } else {
                setState(() {
                  temperature = 0.0;
                  humidity = 0.0;
                  gas = 0.0;
                  vibration = 0.0;
                  sound = 0.0;
                  flame = 0.0;
                });
              }
            }
          },
          onError: (error) {
            print('Sensor data stream error: $error');
          },
        );
  }

  Future<void> sendNotificationToSupabase(double temperature) async {
    final supabase = Supabase.instance.client;
    await supabase.from("notification").insert({
      "message":
          "High temperature detected: ${temperature.toStringAsFixed(1)}°C",
      "timestamp": DateTime.now().toIso8601String(),
      "read": false,
      "type": "temperature",
    });
  }

  Widget buildGauge(
    String label,
    double value,
    double max,
    List<GaugeRange> ranges,
    String unit,
  ) {
    return Column(
      children: [
        SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: max,
              ranges: ranges,
              pointers: <GaugePointer>[NeedlePointer(value: value)],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    '$value $unit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  positionFactor: 0.5,
                  angle: 90,
                ),
              ],
            ),
          ],
        ),
        Text('$label: $value $unit'),
      ],
    );
  }

  Widget buildStatusCard(
    String label,
    bool detected,
    IconData icon,
    Color activeColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        detected
            ? activeColor.withOpacity(0.2)
            : (isDarkMode ? const Color(0xFF1F2A38) : Colors.grey.shade200);

    final Color iconColor =
        detected
            ? activeColor
            : (isDarkMode ? Colors.grey.shade400 : Colors.grey);

    final Color textColor =
        detected
            ? activeColor
            : (isDarkMode ? Colors.grey.shade300 : Colors.grey);

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 10),
            Text(
              '$label: ${detected ? "Detected" : "Not Detected"}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Device is offline - Displaying last known values',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedText() {
    if (lastUpdated == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Last updated: ${DateFormat('MMM dd, HH:mm:ss').format(lastUpdated!)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Environmental Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                lastUpdated = null;
              });
              listenToDeviceStatus();
              listenToSupabaseSensorData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (deviceStatus != 'online') _buildOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            deviceStatus == 'online'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            deviceStatus == 'online'
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color:
                                deviceStatus == 'online'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Device Status: ${deviceStatus.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  deviceStatus == 'online'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildLastUpdatedText(),
                    const SizedBox(height: 16),

                    // Responsive Gauge Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        final cardWidth =
                            isWide
                                ? constraints.maxWidth / 3 - 12
                                : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: buildGauge(
                                    'Temperature',
                                    temperature,
                                    50,
                                    [
                                      GaugeRange(
                                        startValue: 0,
                                        endValue: 15,
                                        color: Colors.blue,
                                      ),
                                      GaugeRange(
                                        startValue: 15,
                                        endValue: 30,
                                        color: Colors.green,
                                      ),
                                      GaugeRange(
                                        startValue: 30,
                                        endValue: 50,
                                        color: Colors.red,
                                      ),
                                    ],
                                    '°C',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: buildGauge('Humidity', humidity, 90, [
                                    GaugeRange(
                                      startValue: 0,
                                      endValue: 30,
                                      color: Colors.blue,
                                    ),
                                    GaugeRange(
                                      startValue: 30,
                                      endValue: 70,
                                      color: Colors.green,
                                    ),
                                    GaugeRange(
                                      startValue: 70,
                                      endValue: 100,
                                      color: Colors.red,
                                    ),
                                  ], '%'),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: buildGauge('CO₂', gas, 1500, [
                                    GaugeRange(
                                      startValue: 0,
                                      endValue: 200,
                                      color: Colors.green,
                                    ),
                                    GaugeRange(
                                      startValue: 200,
                                      endValue: 600,
                                      color: Colors.orange,
                                    ),
                                    GaugeRange(
                                      startValue: 600,
                                      endValue: 1000,
                                      color: Colors.red,
                                    ),
                                  ], 'ppm'),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Status Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: deviceStatus == 'online' ? 1.0 : 0.6,
                            child: IgnorePointer(
                              ignoring: deviceStatus != 'online',
                              child: buildStatusCard(
                                'Vibration',
                                vibration > 0,
                                Icons.vibration,
                                Colors.purple,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Opacity(
                            opacity: deviceStatus == 'online' ? 1.0 : 0.6,
                            child: IgnorePointer(
                              ignoring: deviceStatus != 'online',
                              child: buildStatusCard(
                                'Sound',
                                sound > 1000,
                                Icons.volume_up,
                                Colors.purple,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Opacity(
                            opacity: deviceStatus == 'online' ? 1.0 : 0.6,
                            child: IgnorePointer(
                              ignoring: deviceStatus != 'online',
                              child: buildStatusCard(
                                'Flame',
                                flame > 0,
                                CupertinoIcons.flame_fill,
                                Colors.purple,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
