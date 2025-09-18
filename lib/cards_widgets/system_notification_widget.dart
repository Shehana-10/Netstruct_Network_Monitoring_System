//system_notification_widget.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

class SystemNotificationWidget extends StatefulWidget {
  const SystemNotificationWidget({Key? key}) : super(key: key);

  @override
  _SystemNotificationWidgetState createState() =>
      _SystemNotificationWidgetState();
}

class _SystemNotificationWidgetState extends State<SystemNotificationWidget> {
  final DatabaseReference _notificationRef = FirebaseDatabase.instance
      .ref()
      .child('notifications');
  List<SystemNotification> _notifications = [];
  OverlayEntry? _overlayEntry;

  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() {
    _notificationRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<SystemNotification> tempList = [];
        data.forEach((key, value) {
          if (value['read'] == false) {
            final item = SystemNotification(
              id: key, // use key as id!
              message: value['message'],
              timestamp:
                  DateTime.tryParse(value['timestamp']) ?? value['timestamp'],
              read: value['read'],
              type: value['type'],
            );
            tempList.add(item);
          }
        });
        setState(() {
          _notifications = tempList;
        });
      }
    });
  }

  void _markAsRead(String id) {
    _notificationRef.child(id).update({'read': true});
  }

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx - 250 + size.width,
            top: offset.dy + size.height + 10,
            width: 300,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-250, 40),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _notifications.isEmpty
                          ? const Text('No new notifications')
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.notifications,
                                  color: Colors.deepOrange,
                                ),
                                title: Text(notification.message),
                                subtitle: Text(
                                  // ignore: unnecessary_type_check
                                  notification.timestamp is DateTime
                                      ? DateFormat(
                                        'MMM dd, HH:mm',
                                      ).format(notification.timestamp)
                                      : notification.timestamp.toString(),
                                ),
                                onTap: () {
                                  _markAsRead(notification.id);
                                  setState(() {
                                    _notifications.removeAt(index);
                                  });
                                  _overlayEntry?.remove();
                                  _overlayEntry = null;
                                },
                              );
                            },
                          ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _toggleOverlay,
          ),
          if (_notifications.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_notifications.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
