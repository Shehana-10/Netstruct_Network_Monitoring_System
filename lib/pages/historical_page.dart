import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp/pages/network_data_tab.dart';
import 'package:fyp/pages/sensor_data_tab.dart';
import 'package:fyp/pages/system_data_tab.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoricalPage extends StatefulWidget {
  const HistoricalPage({super.key});

  @override
  State<HistoricalPage> createState() => _HistoricalPageState();
}

class _HistoricalPageState extends State<HistoricalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String deviceStatus = 'offline';
  DateTime? lastUpdated;
  StreamSubscription? _deviceStatusSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenToDeviceStatus();
  }

  void _listenToDeviceStatus() {
    final supabase = Supabase.instance.client;
    _deviceStatusSubscription = supabase
        .from('netstruct')
        .stream(primaryKey: ['uuid'])
        .order('timestamp', ascending: false)
        .limit(1)
        .listen(
          (data) {
            if (data.isNotEmpty && mounted) {
              setState(() {
                deviceStatus =
                    data.last['status']?.toString().toLowerCase() ?? 'offline';
                lastUpdated = DateTime.now();
              });
            }
          },
          onError: (error) {
            print('Device status stream error: $error');
          },
        );
  }

  @override
  void dispose() {
    _deviceStatusSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatusIndicator() {
    final isOnline = deviceStatus == 'online';
    final color = isOnline ? Colors.green : Colors.red;
    final icon = isOnline ? Icons.check_circle : Icons.error_outline;
    final text = 'Device: ${deviceStatus.toUpperCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    if (lastUpdated == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Last updated: ${DateFormat('MMM dd, HH:mm:ss').format(lastUpdated!)}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0D1117) : Colors.white;
    final appBarColor = isDark ? const Color(0xFF161B22) : Colors.grey[100];
    final titleColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.yellow : Colors.blueAccent;
    final unselectedLabelColor = isDark ? Colors.grey : Colors.black54;
    final indicatorColor = isDark ? Colors.green : Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            _buildLastUpdated(),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildStatusIndicator(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: labelColor,
          isScrollable: true,
          unselectedLabelColor: unselectedLabelColor,
          indicatorColor: indicatorColor,
          tabAlignment: TabAlignment.start,
          indicatorWeight: 4,
          tabs: const [
            Tab(child: Text("Sensor Data", style: TextStyle(fontSize: 18))),
            Tab(child: Text("System Data", style: TextStyle(fontSize: 18))),
            Tab(child: Text("Network Data", style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pass device status to tabs if they need it
          SensorDataTab(),
          SystemDataTab(),
          NetworkDataTab(),
        ],
      ),
    );
  }
}
