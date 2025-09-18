import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SystemDataTab extends StatefulWidget {
  const SystemDataTab({super.key});

  @override
  State<SystemDataTab> createState() => _SystemDataTabState();
}

class _SystemDataTabState extends State<SystemDataTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 2 : 1;
    final bgColor = isDark ? const Color(0xFF161B22) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Metrics",
            style: TextStyle(
              fontSize: 20,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                CpuMemoryLineChart(
                  title: 'CPU Usage',
                  lineColor: Colors.red,
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                CpuMemoryLineChart(
                  title: 'Memory Usage',
                  lineColor: Colors.blue,
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                CpuMemoryLineChart(
                  title: 'Disk Usage',
                  lineColor: Colors.green,
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                NetworkTrafficChart(bgColor: bgColor, textColor: textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= Network Traffic ========================= */

class NetworkTrafficChart extends StatefulWidget {
  final Color bgColor;
  final Color textColor;

  const NetworkTrafficChart({
    super.key,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<NetworkTrafficChart> createState() => _NetworkTrafficChartState();
}

class _NetworkTrafficChartState extends State<NetworkTrafficChart> {
  static const int _pageSize = 50;

  List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];
  bool isLoading = true;
  DateTime? lastUpdated;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    try {
      final supabase = Supabase.instance.client;
      List data = await supabase
          .from('infrastructure')
          .select('timestamp, download_kbps, upload_kbps')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final dl = <FlSpot>[];
      final ul = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        final d = _parseDouble(data[i]['download_kbps']) ?? 0;
        final u = _parseDouble(data[i]['upload_kbps']) ?? 0;
        dl.add(FlSpot(i.toDouble(), d));
        ul.add(FlSpot(i.toDouble(), u));
      }

      setState(() {
        downloadSpots = dl;
        uploadSpots = ul;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading network data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load network data';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Traffic (Kbps)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Last updated: ${DateFormat('MMM dd, HH:mm:ss').format(lastUpdated!)}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: widget.textColor),
                    )
                    : (downloadSpots.isEmpty)
                    ? Center(
                      child: Text(
                        'No network data available',
                        style: TextStyle(color: widget.textColor),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final timestamp = DateFormat(
                                  'MMM dd, HH:mm:ss',
                                ).format(DateTime.now());
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)} Kbps\n$timestamp',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                            spots: downloadSpots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blue.withOpacity(0.28),
                                  Colors.blue.withOpacity(0.04),
                                ],
                              ),
                            ),
                          ),
                          LineChartBarData(
                            spots: uploadSpots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green.withOpacity(0.28),
                                  Colors.green.withOpacity(0.04),
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

/* ========================= CPU/Memory/Disk Chart ========================= */

class CpuMemoryLineChart extends StatefulWidget {
  final String title;
  final Color lineColor;
  final Color bgColor;
  final Color textColor;

  const CpuMemoryLineChart({
    super.key,
    required this.title,
    required this.lineColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<CpuMemoryLineChart> createState() => _CpuMemoryLineChartState();
}

class _CpuMemoryLineChartState extends State<CpuMemoryLineChart> {
  List<FlSpot> dataPoints = [];
  bool isLoading = true;
  String deviceStatus = 'offline';
  DateTime? lastUpdated;
  String? errorMessage;

  DateTime? _oldestTs;
  DateTime? _newestTs;
  bool _hasMoreOlder = true;
  bool _hasMoreNewer = false; // latest page at start

  @override
  void initState() {
    super.initState();
    _listenToDeviceStatus();
    _loadLatest(force: true);
  }

  void _listenToDeviceStatus() {
    Supabase.instance.client
        .from('netstruct')
        .stream(primaryKey: ['uuid'])
        .order('timestamp', ascending: false)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final newStatus =
                data.last['status']?.toString().toLowerCase() ?? 'offline';
            setState(() => deviceStatus = newStatus);
          }
        }, onError: (e) => debugPrint('Device status stream error: $e'));
  }

  Future<void> _loadLatest({bool force = false}) async {
    if (!force && deviceStatus != 'online') return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final supabase = Supabase.instance.client;
    final title = widget.title.toLowerCase();

    String? column;
    if (title.contains('cpu'))
      column = 'cpu';
    else if (title.contains('memory'))
      column = 'memory';
    else if (title.contains('disk'))
      column = 'disk';

    if (column == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Unknown metric';
      });
      return;
    }

    try {
      List data = await supabase
          .from('infrastructure')
          .select('timestamp, $column')
          .order('timestamp', ascending: false)
          .limit(50);

      data = data.reversed.toList();

      final points = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        final raw = data[i][column];
        if (raw == null) continue;
        final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(raw.toString());
        final value = match != null ? double.tryParse(match.group(0)!) : null;
        if (value != null) points.add(FlSpot(i.toDouble(), value));
      }

      setState(() {
        dataPoints = points;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading latest ${widget.title}: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load ${widget.title} data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Last updated: ${DateFormat('MMM dd, HH:mm:ss').format(lastUpdated!)}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: widget.textColor),
                    )
                    : (dataPoints.isEmpty)
                    ? Center(
                      child: Text(
                        'No ${widget.title} data available',
                        style: TextStyle(color: widget.textColor),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final timestamp = DateFormat(
                                  'MMM dd, HH:mm:ss',
                                ).format(DateTime.now());
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)}%\n$timestamp',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                            spots: dataPoints,
                            isCurved: true,
                            color: widget.lineColor,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  widget.lineColor.withOpacity(0.4),
                                  widget.lineColor.withOpacity(0.05),
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
