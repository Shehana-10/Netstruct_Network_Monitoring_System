import 'package:flutter/material.dart';
import 'package:fyp/services/notification_service.dart';
import 'package:fyp/models/notification_model.dart';
import 'package:fyp/widgets/notification_dialog_box.dart';
import 'package:intl/intl.dart';

class NotificationMenu extends StatefulWidget {
  final int unreadCount;
  final NotificationService notificationService;
  final VoidCallback onNotificationRead;

  const NotificationMenu({
    Key? key,
    required this.unreadCount,
    required this.notificationService,
    required this.onNotificationRead,
  }) : super(key: key);

  @override
  _NotificationMenuState createState() => _NotificationMenuState();
}

class _NotificationMenuState extends State<NotificationMenu> {
  List<SystemNotification> _notifications = [];
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _previousUnreadCount = widget.unreadCount;
  }

  @override
  void didUpdateWidget(NotificationMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.unreadCount > oldWidget.unreadCount) {
      _loadNotifications();
    }

    _previousUnreadCount = widget.unreadCount;
  }

  Future<void> _loadNotifications() async {
    final notifications =
        await widget.notificationService.getUnreadNotifications();
    setState(() => _notifications = notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => _showNotificationMenu(context),
        ),
        if (widget.unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  widget.unreadCount > 9 ? '9+' : widget.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final offset = button.localToGlobal(Offset(0, button.size.height));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: backgroundColor,
            child: SizedBox(
              width: 350,
              height: 400,
              child: NotificationMenuContent(
                notifications: _notifications,
                onNotificationTap: (notificationId) async {
                  await widget.notificationService.markAsRead(notificationId);
                  widget.onNotificationRead();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationMenuContent extends StatefulWidget {
  final List<SystemNotification> notifications;
  final Function(String) onNotificationTap;

  const NotificationMenuContent({
    Key? key,
    required this.notifications,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  State<NotificationMenuContent> createState() =>
      _NotificationMenuContentState();
}

class _NotificationMenuContentState extends State<NotificationMenuContent> {
  late List<SystemNotification> _localNotifications;

  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(widget.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final tileBackgroundColor = isDark ? Colors.grey[850]! : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
              if (_localNotifications.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_localNotifications.length} New',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: dividerColor),
        Expanded(
          child:
              _localNotifications.isEmpty
                  ? Center(
                    child: Text(
                      'No notifications available',
                      style: TextStyle(color: secondaryColor),
                    ),
                  )
                  : ListView.separated(
                    itemCount: _localNotifications.length,
                    separatorBuilder:
                        (context, index) =>
                            Divider(height: 1, color: dividerColor),
                    itemBuilder: (context, index) {
                      final notification = _localNotifications[index];

                      return GestureDetector(
                        onTap: () async {
                          widget.onNotificationTap(notification.id);
                          await showDialog(
                            context: context,
                            builder:
                                (_) => NotificationDetailDialog(
                                  notification: notification,
                                ),
                          );
                          setState(() {
                            _localNotifications.removeAt(index);
                          });
                        },
                        child: Container(
                          color: tileBackgroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      notification.read
                                          ? Colors.grey.withOpacity(0.2)
                                          : _getNotificationColor(
                                            notification.type,
                                          ).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getNotificationIcon(notification.message),
                                  color: _getNotificationColor(
                                    notification.type,
                                  ),
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color:
                                            notification.read
                                                ? secondaryColor
                                                : primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('MMM d, yyyy - HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    notification
                                        .timestamp
                                        .millisecondsSinceEpoch,
                                    isUtc: true,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
        Divider(color: dividerColor),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'View All Notifications',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(String message) {
    final lowerMsg = message.toLowerCase();
    if (lowerMsg.contains('gas')) return Icons.co2;
    if (lowerMsg.contains('temp') || lowerMsg.contains('temperature'))
      return Icons.thermostat;
    if (lowerMsg.contains('network')) return Icons.network_check;
    return Icons.notifications;
  }

  Color _getNotificationColor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('warning')) return Colors.orange;
    if (lowerType.contains('critical')) return Colors.red;
    return Colors.blue;
  }
}
