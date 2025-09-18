import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfrastructureMonitoringPage extends StatefulWidget {
  @override
  _InfrastructureMonitoringPageState createState() =>
      _InfrastructureMonitoringPageState();
}

class _InfrastructureMonitoringPageState
    extends State<InfrastructureMonitoringPage> {
  double? cpuLoad;
  double? memoryUsage;
  double? diskUsage;
  List<CpuData> cpuHistory = [];
  bool isLoading = false;
  String? errorMessage;
  String deviceStatus = 'offline';
  DateTime? lastUpdated;
  bool _isSubscribed = false;

  final supabase = Supabase.instance.client;
  late final RealtimeChannel _infrastructureChannel;

  @override
  void initState() {
    super.initState();
    _infrastructureChannel = supabase.channel('infrastructure_realtime');
    _setupRealtime();
    _listenToDeviceStatus();
  }

  @override
  void dispose() {
    _infrastructureChannel.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    if (_isSubscribed) return;

    _infrastructureChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'infrastructure',
          callback: (payload) {
            if (deviceStatus == 'online') {
              _fetchInfrastructureData(silent: true);
            }
          },
        )
        .subscribe();

    _isSubscribed = true;
  }

  void _listenToDeviceStatus() {
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
            });

            if (newStatus == 'online') {
              _fetchInfrastructureData();
            } else {
              setState(() {
                cpuLoad = null;
                memoryUsage = null;
                diskUsage = null;
                cpuHistory.clear();
              });
            }
          }
        });
  }

  Future<void> _fetchInfrastructureData({bool silent = false}) async {
    if (deviceStatus != 'online') return;

    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Fetch latest metrics
      final latestResponse =
          await supabase
              .from('infrastructure')
              .select()
              .order('timestamp', ascending: false)
              .limit(1)
              .single();

      // Fetch historical data (last 30 minutes)
      final historyResponse = await supabase
          .from('infrastructure')
          .select('cpu, memory, disk, timestamp')
          .order('timestamp', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          cpuLoad = _parseMetric(latestResponse['cpu'], 'CPU');
          memoryUsage = _parseMetric(latestResponse['memory'], 'Memory');
          diskUsage = _parseMetric(latestResponse['disk'], 'Disk');
          lastUpdated = DateTime.now();

          cpuHistory =
              historyResponse.map((row) {
                final timestamp = DateTime.parse(row['timestamp'] as String);
                return CpuData(
                  timestamp,
                  _parseMetric(row['cpu'], 'CPU History'),
                );
              }).toList();

          cpuHistory.sort((a, b) => a.time.compareTo(b.time));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  double _parseMetric(dynamic value, String metricName) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();

      final numericString = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numericString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Device is offline - No data available',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedText() {
    if (lastUpdated == null || deviceStatus != 'online')
      return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Last updated: ${DateFormat('MMM dd, HH:mm:ss').format(lastUpdated!)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  Widget _buildCpuChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CPU UTILIZATION TREND',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child:
                  deviceStatus == 'online' && cpuHistory.isNotEmpty
                      ? SfCartesianChart(
                        tooltipBehavior: TooltipBehavior(
                          enable: true,
                          builder: (
                            dynamic data,
                            dynamic point,
                            dynamic series,
                            int pointIndex,
                            int seriesIndex,
                          ) {
                            final cpuData = data as CpuData;
                            final formattedTime = DateFormat(
                              'HH:mm:ss',
                            ).format(cpuData.time);
                            return Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(blurRadius: 4)],
                              ),
                              child: Text(
                                '$formattedTime : ${cpuData.usage.toStringAsFixed(1)}%',
                              ),
                            );
                          },
                        ),
                        primaryXAxis: DateTimeAxis(isVisible: false),
                        series: <CartesianSeries>[
                          LineSeries<CpuData, DateTime>(
                            dataSource: cpuHistory,
                            xValueMapper: (d, _) => d.time,
                            yValueMapper: (d, _) => d.usage,
                            color: const Color(0xFF4CAF50),
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

  Widget _buildStatsCard(
    String label,
    double? value,
    Color color, {
    String suffix = '%',
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          height: 160,
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deviceStatus == 'online'
                    ? value != null
                        ? '${value.toStringAsFixed(1)}$suffix'
                        : '--'
                    : '--',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: deviceStatus == 'online' ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  _buildStatsCard('CPU', cpuLoad, Colors.green),
                  _buildStatsCard('Memory', memoryUsage, Colors.blue),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [_buildStatsCard('Disk', diskUsage, Colors.red)]),
            ],
          );
        }
        return Row(
          children: [
            _buildStatsCard('CPU', cpuLoad, Colors.green),
            _buildStatsCard('Memory', memoryUsage, Colors.blue),
            _buildStatsCard('Disk', diskUsage, Colors.red),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Infrastructure Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color:
                  deviceStatus == 'online'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  deviceStatus == 'online'
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color: deviceStatus == 'online' ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  deviceStatus.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: deviceStatus == 'online' ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                deviceStatus == 'online' ? _fetchInfrastructureData : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            _buildTopStats(),
            _buildLastUpdatedText(),
            const SizedBox(height: 16),
            _buildCpuChart(),
          ],
        ),
      ),
    );
  }
}

class CpuData {
  final DateTime time;
  final double usage;
  CpuData(this.time, this.usage);
}
