import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/models/notification_model.dart';
import 'package:fyp/services/auth_service.dart';
import 'package:fyp/services/notification_service.dart';
import 'package:fyp/services/user_service.dart';
import 'package:fyp/services/sound_service.dart';
import 'package:fyp/widgets/account_menu.dart';
import 'package:fyp/widgets/notification_menu.dart';
import 'package:fyp/services/audio_service.dart'; // Import the new audio service

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  int _unreadNotifications = 0;
  int _previousUnreadCount = 0;
  bool _soundEnabled = true;
  bool _hasStreamError = false;
  Map<String, dynamic>? _userData;
  StreamSubscription<List<SystemNotification>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadInitialNotifications();
    _setupNotificationListener();
    _loadSoundPreference();
    SoundService.initialize();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    SoundService.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _userService.getUserData();
      setState(() => _userData = data);
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadInitialNotifications() async {
    try {
      final notifications = await _notificationService.getUnreadNotifications();
      setState(() {
        _unreadNotifications = notifications.length;
        _previousUnreadCount = notifications.length;
      });
    } catch (e) {
      print('Error loading initial notifications: $e');
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService
        .unreadNotificationsStream()
        .listen(
          (notifications) {
            final newCount = notifications.length;

            print(
              'Notification count updated: $newCount (was: $_previousUnreadCount)',
            );

            if (_soundEnabled &&
                newCount > _previousUnreadCount &&
                _previousUnreadCount > 0) {
              print('Playing notification sound');
              _playNotificationSound();
            }

            setState(() {
              _previousUnreadCount = _unreadNotifications;
              _unreadNotifications = newCount;
            });
          },
          onError: (error) {
            print('Error in notification stream: $error');
            setState(() => _hasStreamError = true);
          },
          onDone: () {
            print('Notification stream closed');
          },
        );
  }

  void _onNotificationRead() {
    setState(() {
      if (_unreadNotifications > 0) {
        _unreadNotifications--;
      }
    });
    _loadInitialNotifications();
  }

  void _playNotificationSound() {
    AudioService.playNotificationSound();
  }

  Future<void> _loadSoundPreference() async {
    // Implement your preference loading logic here
  }

  Future<void> _saveSoundPreference() async {
    // Implement your preference saving logic here
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Image.asset('assets/images/netstruct_logo.png', height: 50),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            _soundEnabled ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          onPressed: _toggleSound,
        ),
        if (_userData != null && MediaQuery.of(context).size.width > 600)
          _buildWelcomeText(),
        if (_hasStreamError)
          IconButton(
            icon: Icon(Icons.error, color: Colors.orange),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification stream error. Pull to refresh.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        NotificationMenu(
          unreadCount: _unreadNotifications,
          notificationService: _notificationService,
          onNotificationRead: _onNotificationRead,
        ),
        AccountMenu(userData: _userData, authService: AuthService()),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff19084C),
              Color.fromARGB(255, 101, 26, 117),
              Color.fromARGB(255, 101, 25, 118),
              Color.fromARGB(255, 99, 26, 80),
              Color.fromARGB(255, 163, 42, 131),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
    );
  }

  Widget _buildWelcomeText() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Welcome, ',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
              TextSpan(
                text: _userData?['username']?.split(' ')[0] ?? 'User',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSound() {
    setState(() => _soundEnabled = !_soundEnabled);

    // Play a test sound when enabling
    if (_soundEnabled) {
      _playNotificationSound();
    }

    _saveSoundPreference();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _soundEnabled
              ? 'Notification sounds enabled'
              : 'Notification sounds disabled',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
