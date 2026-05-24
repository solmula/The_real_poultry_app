import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
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

  static GlobalKey<NavigatorState>? navigatorKey;
  static void Function(String title, String body, String severity)?
      onForegroundAlert;

  // ─────────────────────────────────────────────────────────────────────
  // STEP 1 — Called before runApp(). Offline-safe. No network calls.
  // ─────────────────────────────────────────────────────────────────────
  Future<void> initializeLocal() async {
    // Background handler — no network
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Android notification channel — local only
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    // Local notifications init — no network
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Message listeners — no network
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
  }

  // ─────────────────────────────────────────────────────────────────────
  // STEP 2 — Called after runApp(). Needs network. Never blocks startup.
  // App is already open and running before any of this executes.
  // ─────────────────────────────────────────────────────────────────────
  Future<void> initializeRemote() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );
    } catch (_) {}

    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () => _navigateToAlerts(),
        );
      }
    } catch (_) {}

    try {
      await _fcm.subscribeToTopic('alerts_critical');
      await _fcm.subscribeToTopic('alerts_all');
    } catch (_) {}

    try {
      await _saveTokenToFirestore();
      _fcm.onTokenRefresh.listen((_) => _saveTokenToFirestore());
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────
  // Kept for backward compatibility — not used in main.dart anymore
  // ─────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    await initializeLocal();
    initializeRemote(); // no await — background only
  }

  // ─────────────────────────────────────────────────────────────────────
  // Foreground message handler
  // ─────────────────────────────────────────────────────────────────────
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'Poultry Alert';
    final body = notification.body ?? '';
    final severity = message.data['severity'] ?? 'INFO';

    if (onForegroundAlert != null) {
      onForegroundAlert!(title, body, severity);
    }

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

  // ─────────────────────────────────────────────────────────────────────
  // Navigation handlers
  // ─────────────────────────────────────────────────────────────────────
  void _onNotificationOpened(RemoteMessage message) {
    _navigateToAlerts();
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateToAlerts();
  }

  void _navigateToAlerts() {
    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      '/shell',
      (route) => false,
      arguments: 3,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Token management
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final token = await _fcm.getToken();
      if (token == null) return;
      print('FCM TOKEN: $token');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final farmId = userDoc.data()?['farm_id']?.toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          if (farmId != null) 'farm_id': farmId,
          'fcm_token': token,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Silently ignore — will retry on next token refresh
    }
  }

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