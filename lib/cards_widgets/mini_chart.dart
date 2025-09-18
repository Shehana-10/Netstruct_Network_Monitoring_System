import 'dart:math';

import 'package:flutter/material.dart';

class MiniChart extends StatefulWidget {
  const MiniChart({super.key});

  @override
  State<MiniChart> createState() => _MiniChartState();
}

class _MiniChartState extends State<MiniChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(painter: LineChartPainter(_controller.value));
        },
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final double animationValue;

  LineChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 =
        Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final paint2 =
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path1 = Path();
    final path2 = Path();

    for (double x = 0; x < size.width; x++) {
      double y1 = size.height / 2 + 6 * sin((x + animationValue * 100) * 0.05);
      double y2 = size.height / 2 + 4 * cos((x + animationValue * 100) * 0.07);
      if (x == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}
