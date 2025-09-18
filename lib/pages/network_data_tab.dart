import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NetworkDataTab extends StatefulWidget {
  const NetworkDataTab({super.key});

  @override
  State<NetworkDataTab> createState() => _NetworkDataTabState();
}

class _NetworkDataTabState extends State<NetworkDataTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final crossAxisCount = isMobile ? 1 : 2;
    final bgColor = isDark ? const Color(0xFF161B22) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding:
          isMobile ? const EdgeInsets.all(12.0) : const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Network Metrics",
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isMobile ? 12 : 16,
              mainAxisSpacing: isMobile ? 12 : 16,
              childAspectRatio: isMobile ? 1.2 : 1.5,
              children: [
                PacketLossChart(
                  bgColor: bgColor,
                  textColor: textColor,
                  isMobile: isMobile,
                ),
                LatencyChart(
                  bgColor: bgColor,
                  textColor: textColor,
                  isMobile: isMobile,
                ),
                UptimeChart(
                  bgColor: bgColor,
                  textColor: textColor,
                  isMobile: isMobile,
                ),
                NetworkStatusSummary(
                  bgColor: bgColor,
                  textColor: textColor,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Packet Loss Chart ========================= */

class PacketLossChart extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final bool isMobile;

  const PacketLossChart({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.isMobile,
  });

  @override
  State<PacketLossChart> createState() => _PacketLossChartState();
}

class _PacketLossChartState extends State<PacketLossChart> {
  static const int _pageSize = 50;

  List<FlSpot> packetLossSpots = [];
  bool isLoading = true;
  DateTime? lastUpdated;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPacketLossData();
  }

  Future<void> _loadPacketLossData() async {
    try {
      final supabase = Supabase.instance.client;
      List data = await supabase
          .from('network_status')
          .select('timestamp, packet_loss')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final spots = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        final packetLoss = _parsePacketLoss(data[i]['packet_loss']) ?? 0;
        spots.add(FlSpot(i.toDouble(), packetLoss));
      }

      setState(() {
        packetLossSpots = spots;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading packet loss data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load packet loss data';
      });
    }
  }

  double? _parsePacketLoss(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) return value.toDouble();
      if (value is String) {
        // Handle percentage values like "5%"
        final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
        return double.tryParse(cleaned);
      }
      return double.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          widget.isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Packet Loss (%)',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Updated: ${DateFormat('MMM dd, HH:mm').format(lastUpdated!)}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: widget.isMobile ? 9 : 10,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: widget.textColor,
                        strokeWidth: widget.isMobile ? 2 : 4,
                      ),
                    )
                    : (packetLossSpots.isEmpty)
                    ? Center(
                      child: Text(
                        'No packet loss data',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.isMobile ? 12 : 14,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY:
                            packetLossSpots.isNotEmpty
                                ? (packetLossSpots
                                            .map((spot) => spot.y)
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.1)
                                    .ceilToDouble()
                                : 100,
                        lineTouchData: LineTouchData(
                          enabled:
                              !widget
                                  .isMobile, // Disable touch on mobile to prevent interference with scrolling
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final timestamp = DateFormat(
                                  'MMM dd, HH:mm',
                                ).format(DateTime.now());
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)}%\n$timestamp',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.isMobile ? 10 : 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: packetLossSpots,
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: widget.isMobile ? 1.5 : 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.orange.withOpacity(0.4),
                                  Colors.orange.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Latency Chart ========================= */

class LatencyChart extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final bool isMobile;

  const LatencyChart({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.isMobile,
  });

  @override
  State<LatencyChart> createState() => _LatencyChartState();
}

class _LatencyChartState extends State<LatencyChart> {
  static const int _pageSize = 50;

  List<FlSpot> latencySpots = [];
  bool isLoading = true;
  DateTime? lastUpdated;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatencyData();
  }

  Future<void> _loadLatencyData() async {
    try {
      final supabase = Supabase.instance.client;
      List data = await supabase
          .from('network_status')
          .select('timestamp, latency_ms')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final spots = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        final latency = _parseDouble(data[i]['latency_ms']) ?? 0;
        spots.add(FlSpot(i.toDouble(), latency));
      }

      setState(() {
        latencySpots = spots;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading latency data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load latency data';
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
        return double.tryParse(cleaned);
      }
      return double.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          widget.isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latency (ms)',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Updated: ${DateFormat('MMM dd, HH:mm').format(lastUpdated!)}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: widget.isMobile ? 9 : 10,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: widget.textColor,
                        strokeWidth: widget.isMobile ? 2 : 4,
                      ),
                    )
                    : (latencySpots.isEmpty)
                    ? Center(
                      child: Text(
                        'No latency data',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.isMobile ? 12 : 14,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY:
                            latencySpots.isNotEmpty
                                ? (latencySpots
                                            .map((spot) => spot.y)
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.1)
                                    .ceilToDouble()
                                : 100,
                        lineTouchData: LineTouchData(
                          enabled: !widget.isMobile,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final timestamp = DateFormat(
                                  'MMM dd, HH:mm',
                                ).format(DateTime.now());
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)} ms\n$timestamp',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.isMobile ? 10 : 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: latencySpots,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: widget.isMobile ? 1.5 : 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.purple.withOpacity(0.4),
                                  Colors.purple.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Uptime Chart ========================= */

class UptimeChart extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final bool isMobile;

  const UptimeChart({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.isMobile,
  });

  @override
  State<UptimeChart> createState() => _UptimeChartState();
}

class _UptimeChartState extends State<UptimeChart> {
  static const int _pageSize = 30;

  List<FlSpot> uptimeSpots = [];
  bool isLoading = true;
  DateTime? lastUpdated;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUptimeData();
  }

  Future<void> _loadUptimeData() async {
    try {
      final supabase = Supabase.instance.client;
      List data = await supabase
          .from('network_status')
          .select('timestamp, uptime_s')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final spots = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        final uptimeSeconds = _parseDouble(data[i]['uptime_s']) ?? 0;
        // Convert seconds to hours for better readability
        final uptimeHours = uptimeSeconds / 3600;
        spots.add(FlSpot(i.toDouble(), uptimeHours));
      }

      setState(() {
        uptimeSpots = spots;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading uptime data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load uptime data';
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
        return double.tryParse(cleaned);
      }
      return double.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          widget.isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uptime (hours)',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Updated: ${DateFormat('MMM dd, HH:mm').format(lastUpdated!)}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: widget.isMobile ? 9 : 10,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: widget.textColor,
                        strokeWidth: widget.isMobile ? 2 : 4,
                      ),
                    )
                    : (uptimeSpots.isEmpty)
                    ? Center(
                      child: Text(
                        'No uptime data',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.isMobile ? 12 : 14,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: !widget.isMobile,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final timestamp = DateFormat(
                                  'MMM dd, HH:mm',
                                ).format(DateTime.now());
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)} hours\n$timestamp',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.isMobile ? 10 : 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: uptimeSpots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: widget.isMobile ? 1.5 : 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green.withOpacity(0.4),
                                  Colors.green.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Network Status Summary ========================= */

class NetworkStatusSummary extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final bool isMobile;

  const NetworkStatusSummary({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.isMobile,
  });

  @override
  State<NetworkStatusSummary> createState() => _NetworkStatusSummaryState();
}

class _NetworkStatusSummaryState extends State<NetworkStatusSummary> {
  double currentLatency = 0;
  double currentPacketLoss = 0;
  String currentUptime = "0h 0m";
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNetworkStatusSummary();
  }

  Future<void> _loadNetworkStatusSummary() async {
    try {
      final supabase = Supabase.instance.client;

      // Get the latest network status
      final statusData = await supabase
          .from('network_status')
          .select('latency_ms, packet_loss, uptime_h_m')
          .order('timestamp', ascending: false)
          .limit(1);

      if (statusData.isNotEmpty) {
        setState(() {
          currentLatency = _parseDouble(statusData[0]['latency_ms']) ?? 0;
          currentPacketLoss =
              _parsePacketLoss(statusData[0]['packet_loss']) ?? 0;
          currentUptime = statusData[0]['uptime_h_m']?.toString() ?? "0h 0m";
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No network status data available';
        });
      }
    } catch (e) {
      debugPrint('Error loading network status summary: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load status summary';
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
        return double.tryParse(cleaned);
      }
      return double.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  double? _parsePacketLoss(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) return value.toDouble();
      if (value is String) {
        // Handle percentage values like "5%"
        final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
        return double.tryParse(cleaned);
      }
      return double.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          widget.isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Network Status',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: widget.textColor,
                        strokeWidth: widget.isMobile ? 2 : 4,
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusRow(
                          'Latency',
                          '${currentLatency.toStringAsFixed(1)} ms',
                          currentLatency < 50
                              ? Colors.green
                              : currentLatency < 100
                              ? Colors.orange
                              : Colors.red,
                        ),
                        SizedBox(height: widget.isMobile ? 12 : 16),
                        _buildStatusRow(
                          'Packet Loss',
                          '${currentPacketLoss.toStringAsFixed(1)}%',
                          currentPacketLoss < 1
                              ? Colors.green
                              : currentPacketLoss < 5
                              ? Colors.orange
                              : Colors.red,
                        ),
                        SizedBox(height: widget.isMobile ? 12 : 16),
                        _buildStatusRow('Uptime', currentUptime, Colors.blue),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: widget.isMobile ? 12 : 14,
              color: widget.textColor.withOpacity(0.8),
            ),
          ),
        ),
        Container(
          padding:
              widget.isMobile
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: widget.isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
