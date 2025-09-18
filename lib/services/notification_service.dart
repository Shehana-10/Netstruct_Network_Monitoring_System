import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SystemNotification>> getUnreadNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('read', false)
        .order('timestamp', ascending: false)
        .limit(10);

    return (response as List)
        .map((item) => SystemNotification.fromMap(item))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // NEW: real-time stream of unread notifications
  Stream<List<SystemNotification>> unreadNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('read', false)
        .order('timestamp', ascending: false)
        .map((list) {
          return list
              .map<SystemNotification>(
                (item) => SystemNotification.fromMap(item),
              )
              .toList();
        });
  }
}
