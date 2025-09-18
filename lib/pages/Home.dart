import 'package:flutter/material.dart';
import 'package:fyp/cards_widgets/cpu_card.dart';
import 'package:fyp/cards_widgets/memory_card.dart';
import 'package:fyp/cards_widgets/network_card.dart';
import 'package:fyp/cards_widgets/service_card.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {
      'icon': Icons.thermostat,
      'title': 'Environmental Monitoring',
      'description':
          'Real-time temperature, humidity, gas levels, vibration, fire detection and sound detection to ensure optimal physical conditions.',
      'benefits': [
        'Prevent overheating',
        'Detect gas leaks',
        'Early vibration alerts',
        'Noise level auditing',
        'Fire detection',
      ],
    },
    {
      'icon': Icons.network_check,
      'title': 'Network Monitoring',
      'description':
          'Continuous latency, packet loss, uptime/network traffic tracking to guarantee connectivity and performance.',
      'benefits': [
        'Minimize downtime',
        'Quick fault identification',
        'Performance optimization',
      ],
    },
    {
      'icon': Icons.memory,
      'title': 'Infrastructure Monitoring',
      'description':
          'Monitoring CPU load,memory usage ,disk usage, CPU utilization trend of the server.',
      'benefits': [
        'Capacity planning',
        'Predictive maintenance',
        'Resource utilization',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Made responsive
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: isLargeScreen ? 250 : 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 188, 28, 124),
                      Color.fromARGB(255, 145, 10, 148),
                      Color(0xff5B0D85),
                      Color(0xff19084C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLargeScreen)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 140,
                                ),
                                child: Image.asset(
                                  "assets/images/image1.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: isLargeScreen ? 35 : 20,
                                left: isLargeScreen ? 0 : 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'Welcome To',
                                      style: GoogleFonts.outfit(
                                        color: Colors.blueGrey,
                                        fontSize: isLargeScreen ? 52 : 36,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: isLargeScreen ? 70 : 50,
                                    width: isLargeScreen ? 360 : 240,
                                    child: Center(
                                      child: Image.asset(
                                        "assets/images/netstruct_logo.png",
                                        width: isLargeScreen ? 500 : 300,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isLargeScreen) ...[
                              const SizedBox(width: 20),
                              Padding(
                                padding: const EdgeInsets.only(top: 133),
                                child: Container(
                                  height: 50,
                                  width: 5,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (isLargeScreen)
                              Padding(
                                padding: const EdgeInsets.only(top: 130),
                                child: Text(
                                  "Our Services Empower Data Centers With \nReal-Time Insights and Proactive Alerts..! ",
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Responsive Row with cards and services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  isMediumScreen
                      ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cards Section - Horizontal scroll on medium screens
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 350,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: const CpuCard(),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 300,
                                      child: const NetworkCard(),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 300,
                                      child: const TemperatureCard(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Services Section - Vertical layout
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children:
                                  services
                                      .map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 25,
                                          ),
                                          child: ServiceCard(
                                            icon: s['icon'],
                                            title: s['title'],
                                            description: s['description'],
                                            benefits: List<String>.from(
                                              s['benefits'],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        // Mobile layout - stacked vertically
                        children: [
                          // Cards Section - Vertical scroll on small screens
                          SizedBox(
                            height: 250,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(width: 250, child: const CpuCard()),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 250,
                                    child: const NetworkCard(),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 250,
                                    child: const TemperatureCard(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Services Section
                          ...services
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 25),
                                  child: ServiceCard(
                                    icon: s['icon'],
                                    title: s['title'],
                                    description: s['description'],
                                    benefits: List<String>.from(s['benefits']),
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
