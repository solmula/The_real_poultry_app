
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS handles notification tray automatically
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'poultry_alerts';
  static const _channelName = 'Poultry Alerts';
  static const _channelDesc = 'Critical alerts from your poultry house';

  /// Navigation key (set from main.dart)
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Foreground banner callback
  static void Function(String title, String body, String severity)?
      onForegroundAlert;

  Future<void> initialize() async {
    /// 1 — Background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    /// 2 — Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    /// 3 — Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    /// 4 — Local notifications initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    /// 5 — Foreground message listener
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    /// 6 — App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

    /// 7 — App opened from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToAlerts();
      });
    }

    /// 8 — iOS foreground presentation
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /// 9 — Topic subscriptions
    await _fcm.subscribeToTopic('alerts_critical');
    await _fcm.subscribeToTopic('alerts_all');

    /// 10 — Save token
    await _saveTokenToFirestore();
    _fcm.onTokenRefresh.listen((_) => _saveTokenToFirestore());

    debugPrint('[FCM] Initialized. Token: ${await _fcm.getToken()}');
  }

  /// ───────────────── Foreground Message ─────────────────
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'Poultry Alert';
    final body = notification.body ?? '';
    final severity = message.data['severity'] ?? 'INFO';

    onForegroundAlert?.call(title, body, severity);

    _local.show(
      notification.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: _severityColor(severity),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// ───────────────── Notification Opened ─────────────────
  void _onNotificationOpened(RemoteMessage message) {
    _navigateToAlerts();
  }

  /// ───────────────── Local Notification Tap ─────────────────
  void _onNotificationTap(NotificationResponse response) {
    _navigateToAlerts();
  }

  /// ───────────────── Navigation ─────────────────
  void _navigateToAlerts() {
    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      '/shell',
      (route) => false,
      arguments: 3,
    );
  }

  /// ───────────────── Save Token ─────────────────
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcm_token': token}, SetOptions(merge: true));

      debugPrint('[FCM] Token saved');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// ───────────────── Severity Color ─────────────────
  Color _severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFB71C1C);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'WARNING':
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Future<String?> getToken() => _fcm.getToken();
}