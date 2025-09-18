import 'package:flutter/material.dart';

class NotificationIconWithPanel extends StatefulWidget {
  final List<String> notifications;

  const NotificationIconWithPanel({super.key, required this.notifications});

  @override
  _NotificationIconWithPanelState createState() =>
      _NotificationIconWithPanelState();
}

class _NotificationIconWithPanelState extends State<NotificationIconWithPanel> {
  bool showPanel = false;

  void togglePanel() {
    setState(() {
      showPanel = !showPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: togglePanel,
        ),
        if (showPanel)
          Positioned(
            top: 40,
            right: 0,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.notifications
                      .map((msg) => ListTile(title: Text(msg)))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
