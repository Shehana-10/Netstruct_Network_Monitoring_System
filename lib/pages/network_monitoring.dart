import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NetworkMonitoringPage extends StatefulWidget {
  const NetworkMonitoringPage({Key? key}) : super(key: key);

  @override
  _NetworkMonitoringPageState createState() => _NetworkMonitoringPageState();
}

class _NetworkMonitoringPageState extends State<NetworkMonitoringPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final RealtimeChannel _networkChannel;
  bool _networkSubscribed = false;

  // Network metrics
  double? latency;
  double? packetLoss;
  double? uptimeSeconds;
  String uptimeStatus = "Loading...";
  String deviceStatus = 'offline';
  DateTime? lastUpdated;

  // Network traffic data
  List<NetworkData> networkHistory = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _networkChannel = _supabase.channel('network_realtime');
    _initState();
  }

  @override
  void dispose() {
    _networkChannel.unsubscribe();
    super.dispose();
  }

  void _initState() {
    listenToDeviceStatus();
    _setupRealtimeSubscription();
    _fetchInitialData();
  }

  void _setupRealtimeSubscription() {
    if (!_networkSubscribed) {
      _networkChannel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'network_status',
            callback: (payload) {
              if (mounted && deviceStatus == 'online') {
                _processNetworkUpdate(payload.newRecord);
              }
            },
          )
          .subscribe();

      // Updated to listen to infrastructure table instead
      _supabase
          .channel('network_traffic_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'infrastructure', // Changed from network_traffic
            callback: (payload) {
              if (mounted && deviceStatus == 'online') {
                _fetchNetworkTrafficData(silent: true);
              }
            },
          )
          .subscribe();

      _networkSubscribed = true;
    }
  }

  Future<void> _fetchInitialData() async {
    if (deviceStatus != 'online') return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch network status
      final networkResponse =
          await _supabase
              .from('network_status')
              .select()
              .order('timestamp', ascending: false)
              .limit(1)
              .maybeSingle();

      if (networkResponse != null && mounted) {
        _processNetworkUpdate(networkResponse);
      }

      // Fetch network traffic data
      await _fetchNetworkTrafficData();
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNetworkTrafficData({bool silent = false}) async {
    if (deviceStatus != 'online') return;

    try {
      // Updated to query the infrastructure table
      final historyResponse = await _supabase
          .from('infrastructure')
          .select('download_kbps, upload_kbps, timestamp')
          .order('timestamp', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          networkHistory =
              historyResponse.map<NetworkData>((row) {
                try {
                  final timestamp = DateTime.parse(row['timestamp'] as String);
                  return NetworkData(
                    timestamp,
                    _parseDouble(row['download_kbps']) ?? 0,
                    _parseDouble(row['upload_kbps']) ?? 0,
                  );
                } catch (e) {
                  debugPrint('Error parsing network data row: $e');
                  return NetworkData(DateTime.now(), 0, 0);
                }
              }).toList();

          networkHistory.sort((a, b) => a.time.compareTo(b.time));
          lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error fetching network traffic data: $e');
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load network traffic: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processNetworkUpdate(Map<String, dynamic>? data) {
    if (data == null || !mounted) return;

    final now = DateTime.now();
    if (lastUpdated != null &&
        now.difference(lastUpdated!).inMilliseconds < 1000) {
      return;
    }

    setState(() {
      latency = _parseDouble(data['latency_ms']);
      packetLoss = _parseDouble(data['packet_loss']);
      uptimeSeconds = _parseDouble(data['uptime_s']);
      uptimeStatus = (uptimeSeconds ?? 0) > 0 ? "Up" : "Down";
      lastUpdated = now;
    });
  }

  void listenToDeviceStatus() {
    _supabase
        .from('netstruct')
        .stream(primaryKey: ['uuid'])
        .order('timestamp', ascending: false)
        .limit(1)
        .listen(
          (data) {
            if (data.isNotEmpty && mounted) {
              final newStatus =
                  data.last['status']?.toString().toLowerCase() ?? 'offline';

              setState(() {
                deviceStatus = newStatus;
                _clearDataIfOffline();
              });

              if (newStatus == 'online') {
                _fetchInitialData();
              }
            }
          },
          onError: (error) {
            debugPrint('Device status stream error: $error');
          },
        );
  }

  void _clearDataIfOffline() {
    if (deviceStatus != 'online') {
      setState(() {
        latency = null;
        packetLoss = null;
        uptimeSeconds = null;
        uptimeStatus = "Offline";
        networkHistory.clear();
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle cases where the string might be a number but with commas, spaces, etc.
        final cleaned =
            value
                .replaceAll(
                  RegExp(r'[^\d.-]'),
                  '',
                ) // Remove all non-numeric characters except . and -
                .trim();
        return double.tryParse(cleaned);
      }
      if (value is num) return value.toDouble();

      // If we get here, try to convert to string and parse
      return double.tryParse(value.toString());
    } catch (e) {
      debugPrint('Error parsing double from $value: $e');
      return null;
    }
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Device is offline - Displaying last known values',
              style: TextStyle(
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

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            deviceStatus == 'online' ? Icons.check_circle : Icons.error_outline,
            color: deviceStatus == 'online' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            'Device Status: ${deviceStatus.toUpperCase()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: deviceStatus == 'online' ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required double? value,
    required double max,
    required List<GaugeRange> ranges,
    required String unit,
    String? valueFormat,
  }) {
    return Opacity(
      opacity: deviceStatus == 'online' ? 1.0 : 0.6,
      child: IgnorePointer(
        ignoring: deviceStatus != 'online',
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: max,
                        ranges: ranges,
                        pointers: <GaugePointer>[
                          NeedlePointer(
                            value: value ?? 0,
                            enableAnimation: true,
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            widget: Text(
                              value != null
                                  ? '${valueFormat != null ? NumberFormat(valueFormat).format(value) : value.toStringAsFixed(2)} $unit'
                                  : '-- $unit',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
    String? description,
  }) {
    return Opacity(
      opacity: deviceStatus == 'online' ? 1.0 : 0.6,
      child: IgnorePointer(
        ignoring: deviceStatus != 'online',
        child: Card(
          color: color.withOpacity(0.4),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Status: $status',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (description != null)
                      Text(description, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Icon(icon, color: color, size: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NETWORK TRAFFIC (Kbps)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child:
                  deviceStatus == 'online' && networkHistory.isNotEmpty
                      ? SfCartesianChart(
                        tooltipBehavior: TooltipBehavior(
                          enable: true,
                          format: 'point.x : point.y Kbps',
                        ),
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.top,
                          overflowMode: LegendItemOverflowMode.wrap,
                        ),
                        primaryXAxis: DateTimeAxis(
                          title: AxisTitle(text: 'Time'),
                          intervalType: DateTimeIntervalType.minutes,
                          dateFormat: DateFormat.Hm(),
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Speed (Kbps)'),
                          numberFormat: NumberFormat('#,##0'),
                        ),
                        series: <CartesianSeries>[
                          LineSeries<NetworkData, DateTime>(
                            name: 'Download',
                            dataSource: networkHistory,
                            xValueMapper: (d, _) => d.time,
                            yValueMapper: (d, _) => d.incoming,
                            color: const Color(0xFF2196F3),
                            width: 3,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                            ),
                          ),
                          LineSeries<NetworkData, DateTime>(
                            name: 'Upload',
                            dataSource: networkHistory,
                            xValueMapper: (d, _) => d.time,
                            yValueMapper: (d, _) => d.outgoing,
                            color: const Color(0xFFFF5722),
                            width: 3,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                            ),
                          ),
                        ],
                      )
                      : Center(
                        child: Text(
                          deviceStatus == 'online'
                              ? 'No data available'
                              : 'Device offline',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Network Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInitialData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (deviceStatus != 'online') _buildOfflineBanner(),
            if (isLoading) const LinearProgressIndicator(),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatusIndicator(),
                    _buildLastUpdatedText(),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                      title: 'Server Status',
                      status: uptimeStatus,
                      icon:
                          uptimeStatus == "Up"
                              ? Icons.cloud_done
                              : uptimeStatus == "Down"
                              ? Icons.cloud_off
                              : Icons.cloud,
                      color:
                          uptimeStatus == "Up"
                              ? Colors.green
                              : uptimeStatus == "Down"
                              ? Colors.red
                              : Colors.grey,
                      description:
                          uptimeStatus == "Up"
                              ? 'Uptime: ${(uptimeSeconds ?? 0) ~/ 3600}h ${((uptimeSeconds ?? 0) % 3600) ~/ 60}m'
                              : 'Device Offline',
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              _buildGaugeCard(
                                title: 'Latency (ms)',
                                value: latency,
                                max: 100,
                                ranges: [
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 30,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 30,
                                    endValue: 70,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 70,
                                    endValue: 100,
                                    color: Colors.red,
                                  ),
                                ],
                                unit: 'ms',
                                valueFormat: '#,##0.0',
                              ),
                              const SizedBox(height: 16),
                              _buildGaugeCard(
                                title: 'Packet Loss (%)',
                                value: packetLoss,
                                max: 5,
                                ranges: [
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 1,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 1,
                                    endValue: 3,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 3,
                                    endValue: 5,
                                    color: Colors.red,
                                  ),
                                ],
                                unit: '%',
                                valueFormat: '#,##0.00',
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildGaugeCard(
                                title: 'Latency (ms)',
                                value: latency,
                                max: 100,
                                ranges: [
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 30,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 30,
                                    endValue: 70,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 70,
                                    endValue: 100,
                                    color: Colors.red,
                                  ),
                                ],
                                unit: 'ms',
                                valueFormat: '#,##0.0',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGaugeCard(
                                title: 'Packet Loss (%)',
                                value: packetLoss,
                                max: 5,
                                ranges: [
                                  GaugeRange(
                                    startValue: 0,
                                    endValue: 1,
                                    color: Colors.green,
                                  ),
                                  GaugeRange(
                                    startValue: 1,
                                    endValue: 3,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: 3,
                                    endValue: 5,
                                    color: Colors.red,
                                  ),
                                ],
                                unit: '%',
                                valueFormat: '#,##0.00',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildNetworkChart(),
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

class NetworkData {
  final DateTime time;
  final double incoming;
  final double outgoing;
  NetworkData(this.time, this.incoming, this.outgoing);
}
