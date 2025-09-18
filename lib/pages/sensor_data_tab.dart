import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SensorDataTab extends StatefulWidget {
  const SensorDataTab({super.key});

  @override
  State<SensorDataTab> createState() => _SensorDataTabState();
}

class _SensorDataTabState extends State<SensorDataTab> {
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
            "Sensor Metrics",
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
                SensorLineChart(
                  title: 'Temperature',
                  lineColor: Colors.orange,
                  unit: '°C',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                SensorLineChart(
                  title: 'Humidity',
                  lineColor: Colors.blue,
                  unit: '%',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                SensorLineChart(
                  title: 'Gas Level',
                  lineColor: Colors.purple,
                  unit: 'ppm',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                SensorLineChart(
                  title: 'Sound Level',
                  lineColor: Colors.green,
                  unit: 'dB',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                SensorBarChart(
                  title: 'Flame Detection',
                  barColor: Colors.red,
                  unit: '',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                SensorBarChart(
                  title: 'Vibration',
                  barColor: Colors.teal,
                  unit: '',
                  bgColor: bgColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SensorLineChart extends StatefulWidget {
  final String title;
  final Color lineColor;
  final String unit;
  final Color bgColor;
  final Color textColor;

  const SensorLineChart({
    super.key,
    required this.title,
    required this.lineColor,
    required this.unit,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart> {
  static const int _pageSize = 50;
  static const double _swipeDistancePx = 30;

  List<FlSpot> dataPoints = [];
  List<DateTime> timestamps = [];
  bool isLoading = true;
  String deviceStatus = 'offline';
  DateTime? lastUpdated;
  String? errorMessage;

  DateTime? _oldestTs;
  DateTime? _newestTs;
  bool _hasMoreOlder = true;
  bool _hasMoreNewer = false;

  double _dragDx = 0;
  bool _paging = false;
  int _animTick = 0;
  int _lastPageDir = 0;

  bool _isHorizontalSwipe = false;
  Offset _startDragPosition = Offset.zero;
  DateTime _lastTouchTime = DateTime.now();

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
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        isLoading = false;
        lastUpdated = DateTime.now();

        if (data.isNotEmpty) {
          _oldestTs = DateTime.parse(data.first['timestamp'].toString());
          _newestTs = DateTime.parse(data.last['timestamp'].toString());
        } else {
          _oldestTs = _newestTs = null;
        }

        _hasMoreOlder = true;
        _hasMoreNewer = false;
        _lastPageDir = 0;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error loading latest ${widget.title}: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load ${widget.title} data';
      });
    }
  }

  Future<void> _pageOlder() async {
    if (_paging || !_hasMoreOlder || _oldestTs == null) return;
    if (deviceStatus != 'online') return;
    _paging = true;

    final supabase = Supabase.instance.client;
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .lt('timestamp', _oldestTs!.toUtc().toIso8601String())
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      if (data.isEmpty) {
        setState(() => _hasMoreOlder = false);
        return;
      }

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        _oldestTs = DateTime.parse(data.first['timestamp'].toString());
        _newestTs = DateTime.parse(data.last['timestamp'].toString());
        _hasMoreNewer = true;
        _hasMoreOlder = data.length == _pageSize;
        _lastPageDir = -1;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error fetching older ${widget.title}: $e');
    } finally {
      _paging = false;
    }
  }

  Future<void> _pageNewer() async {
    if (_paging || !_hasMoreNewer || _newestTs == null) return;
    if (deviceStatus != 'online') return;
    _paging = true;

    final supabase = Supabase.instance.client;
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .gt('timestamp', _newestTs!.toUtc().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(_pageSize);

      if (data.isEmpty) {
        setState(() => _hasMoreNewer = false);
        return;
      }

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        _oldestTs = DateTime.parse(data.first['timestamp'].toString());
        _newestTs = DateTime.parse(data.last['timestamp'].toString());
        _hasMoreOlder = true;
        _hasMoreNewer = data.length == _pageSize;
        _lastPageDir = 1;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error fetching newer ${widget.title}: $e');
    } finally {
      _paging = false;
    }
  }

  void _onPointerDown(PointerDownEvent details) {
    _startDragPosition = details.position;
    _isHorizontalSwipe = false;
    _lastTouchTime = DateTime.now();
  }

  void _onPointerMove(PointerMoveEvent details) {
    final delta = details.position - _startDragPosition;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTouchTime);

    if (timeDiff.inMilliseconds < 300 &&
        delta.dx.abs() > 8 &&
        delta.dx.abs() > delta.dy.abs() * 1.5) {
      _isHorizontalSwipe = true;
      _dragDx += details.delta.dx;
    }
    _lastTouchTime = now;
  }

  void _onPointerUp(PointerUpEvent details) {
    final delta = details.position - _startDragPosition;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTouchTime);

    if (_isHorizontalSwipe && timeDiff.inMilliseconds < 500) {
      final shouldNewer = delta.dx > _swipeDistancePx;
      final shouldOlder = delta.dx < -_swipeDistancePx;

      if (shouldNewer) {
        _pageNewer();
      } else if (shouldOlder) {
        _pageOlder();
      }
    }

    _isHorizontalSwipe = false;
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final n = dataPoints.length;
    final beginOffset =
        _lastPageDir == 0
            ? const Offset(0, 0)
            : (_lastPageDir == 1
                ? const Offset(0.12, 0)
                : const Offset(-0.12, 0));

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
                    : (n == 0)
                    ? Center(
                      child: Text(
                        'No ${widget.title} data available',
                        style: TextStyle(color: widget.textColor),
                      ),
                    )
                    : Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      child: IgnorePointer(
                        ignoring: _isHorizontalSwipe,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, anim) {
                            final slide = Tween<Offset>(
                              begin: beginOffset,
                              end: Offset.zero,
                            ).animate(anim);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: _MetricLines(
                            key: ValueKey(_animTick),
                            spots: dataPoints,
                            timestamps: timestamps,
                            color: widget.lineColor,
                            unit: widget.unit,
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _MetricLines extends StatelessWidget {
  final List<FlSpot> spots;
  final List<DateTime> timestamps;
  final Color color;
  final String unit;

  const _MetricLines({
    super.key,
    required this.spots,
    required this.timestamps,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) => Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
              return lineBarsSpot.map((spot) {
                final index = spot.spotIndex;
                final timestamp =
                    index < timestamps.length
                        ? timestamps[index]
                        : DateTime.now();
                final formattedDate = DateFormat(
                  'MMM dd, yyyy',
                ).format(timestamp);
                final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}$unit\n$formattedDate\n$formattedTime',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.4), color.withOpacity(0.05)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class SensorBarChart extends StatefulWidget {
  final String title;
  final Color barColor;
  final String unit;
  final Color bgColor;
  final Color textColor;

  const SensorBarChart({
    super.key,
    required this.title,
    required this.barColor,
    required this.unit,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<SensorBarChart> createState() => _SensorBarChartState();
}

class _SensorBarChartState extends State<SensorBarChart> {
  static const int _pageSize = 50;
  static const double _swipeDistancePx = 30;

  List<FlSpot> dataPoints = [];
  List<DateTime> timestamps = [];
  bool isLoading = true;
  String deviceStatus = 'offline';
  DateTime? lastUpdated;
  String? errorMessage;

  DateTime? _oldestTs;
  DateTime? _newestTs;
  bool _hasMoreOlder = true;
  bool _hasMoreNewer = false;

  double _dragDx = 0;
  bool _paging = false;
  int _animTick = 0;
  int _lastPageDir = 0;

  bool _isHorizontalSwipe = false;
  Offset _startDragPosition = Offset.zero;
  DateTime _lastTouchTime = DateTime.now();

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
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        isLoading = false;
        lastUpdated = DateTime.now();

        if (data.isNotEmpty) {
          _oldestTs = DateTime.parse(data.first['timestamp'].toString());
          _newestTs = DateTime.parse(data.last['timestamp'].toString());
        } else {
          _oldestTs = _newestTs = null;
        }

        _hasMoreOlder = true;
        _hasMoreNewer = false;
        _lastPageDir = 0;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error loading latest ${widget.title}: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load ${widget.title} data';
      });
    }
  }

  Future<void> _pageOlder() async {
    if (_paging || !_hasMoreOlder || _oldestTs == null) return;
    if (deviceStatus != 'online') return;
    _paging = true;

    final supabase = Supabase.instance.client;
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .lt('timestamp', _oldestTs!.toUtc().toIso8601String())
          .order('timestamp', ascending: false)
          .limit(_pageSize);

      data = data.reversed.toList();

      if (data.isEmpty) {
        setState(() => _hasMoreOlder = false);
        return;
      }

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        _oldestTs = DateTime.parse(data.first['timestamp'].toString());
        _newestTs = DateTime.parse(data.last['timestamp'].toString());
        _hasMoreNewer = true;
        _hasMoreOlder = data.length == _pageSize;
        _lastPageDir = -1;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error fetching older ${widget.title}: $e');
    } finally {
      _paging = false;
    }
  }

  Future<void> _pageNewer() async {
    if (_paging || !_hasMoreNewer || _newestTs == null) return;
    if (deviceStatus != 'online') return;
    _paging = true;

    final supabase = Supabase.instance.client;
    final columnName = widget.title.toLowerCase().split(' ')[0];

    try {
      List data = await supabase
          .from('sensor_data')
          .select('timestamp, $columnName')
          .gt('timestamp', _newestTs!.toUtc().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(_pageSize);

      if (data.isEmpty) {
        setState(() => _hasMoreNewer = false);
        return;
      }

      final points = <FlSpot>[];
      final times = <DateTime>[];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        final value = entry[columnName] as num?;
        if (value != null) {
          points.add(FlSpot(i.toDouble(), value.toDouble()));
          times.add(DateTime.parse(entry['timestamp'].toString()));
        }
      }

      setState(() {
        dataPoints = points;
        timestamps = times;
        _oldestTs = DateTime.parse(data.first['timestamp'].toString());
        _newestTs = DateTime.parse(data.last['timestamp'].toString());
        _hasMoreOlder = true;
        _hasMoreNewer = data.length == _pageSize;
        _lastPageDir = 1;
        _animTick++;
      });
    } catch (e) {
      debugPrint('Error fetching newer ${widget.title}: $e');
    } finally {
      _paging = false;
    }
  }

  void _onPointerDown(PointerDownEvent details) {
    _startDragPosition = details.position;
    _isHorizontalSwipe = false;
    _lastTouchTime = DateTime.now();
  }

  void _onPointerMove(PointerMoveEvent details) {
    final delta = details.position - _startDragPosition;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTouchTime);

    if (timeDiff.inMilliseconds < 300 &&
        delta.dx.abs() > 8 &&
        delta.dx.abs() > delta.dy.abs() * 1.5) {
      _isHorizontalSwipe = true;
      _dragDx += details.delta.dx;
    }
    _lastTouchTime = now;
  }

  void _onPointerUp(PointerUpEvent details) {
    final delta = details.position - _startDragPosition;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTouchTime);

    if (_isHorizontalSwipe && timeDiff.inMilliseconds < 500) {
      final shouldNewer = delta.dx > _swipeDistancePx;
      final shouldOlder = delta.dx < -_swipeDistancePx;

      if (shouldNewer) {
        _pageNewer();
      } else if (shouldOlder) {
        _pageOlder();
      }
    }

    _isHorizontalSwipe = false;
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final n = dataPoints.length;
    final beginOffset =
        _lastPageDir == 0
            ? const Offset(0, 0)
            : (_lastPageDir == 1
                ? const Offset(0.12, 0)
                : const Offset(-0.12, 0));

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
                    : (n == 0)
                    ? Center(
                      child: Text(
                        'No ${widget.title} data available',
                        style: TextStyle(color: widget.textColor),
                      ),
                    )
                    : Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      child: IgnorePointer(
                        ignoring: _isHorizontalSwipe,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, anim) {
                            final slide = Tween<Offset>(
                              begin: beginOffset,
                              end: Offset.zero,
                            ).animate(anim);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: _BarChartWidget(
                            key: ValueKey(_animTick),
                            spots: dataPoints,
                            timestamps: timestamps,
                            color: widget.barColor,
                            unit: widget.unit,
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final List<DateTime> timestamps;
  final Color color;
  final String unit;

  const _BarChartWidget({
    super.key,
    required this.spots,
    required this.timestamps,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();
              final timestamp =
                  index < timestamps.length
                      ? timestamps[index]
                      : DateTime.now();
              final formattedDate = DateFormat(
                'MMM dd, yyyy',
              ).format(timestamp);
              final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}$unit\n$formattedDate\n$formattedTime',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups:
            spots
                .map(
                  (e) => BarChartGroupData(
                    x: e.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: e.y,
                        color: color,
                        width: 6,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                )
                .toList(),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}
