import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_service.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  /// Initializes the local notifications service for Android & iOS.
  static Future<void> init() async {
    if (kIsWeb) {
      // Set up auth state change listener to start/stop listening to Firestore notifications on Web
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          startListeningToNotifications(user.uid);
        } else {
          stopListeningToNotifications();
        }
      });
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Request permissions on Android 13+ (API 33+)
    try {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Error requesting Android permission: $e');
    }

    // Request FCM notification permissions
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] Error requesting FCM permission: $e');
    }

    try {
      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );
      debugPrint('[LocalNotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[LocalNotificationService] Initialization error: $e');
    }

    // Set up auth state change listener to start/stop listening to Firestore notifications
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        startListeningToNotifications(user.uid);
        _setupFcmToken(user.uid);
      } else {
        stopListeningToNotifications();
      }
    });
  }

  /// Sets up FCM token retrieval and Firestore persistence
  static Future<void> _setupFcmToken(String uid) async {
    try {
      if (kIsWeb) return;
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        debugPrint('[LocalNotificationService] FCM token saved to Firestore: $fcmToken');
      }

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          debugPrint('[LocalNotificationService] FCM token refreshed and saved');
        } catch (e) {
          debugPrint('[LocalNotificationService] Error updating refreshed FCM token: $e');
        }
      });
    } catch (e) {
      debugPrint('[LocalNotificationService] Error setting up FCM token: $e');
    }
  }

  /// Starts listening to Firestore notifications for the logged-in user in real-time.
  static void startListeningToNotifications(String uid) {
    stopListeningToNotifications();

    final DateTime startTime = DateTime.now();
    debugPrint('[LocalNotificationService] Started listening to notifications for $uid at $startTime');

    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final Timestamp? timestamp = data['timestamp'] as Timestamp?;
            final bool isRead = data['isRead'] as bool? ?? false;
            final String? title = data['title'] as String?;
            final String? body = data['body'] as String?;

            if (timestamp != null &&
                !isRead &&
                title != null &&
                body != null &&
                timestamp.toDate().isAfter(startTime)) {
              
              // Double check preferences before showing native notification
              try {
                final prefs = await SharedPreferences.getInstance();
                final pushEnabled = prefs.getBool('setting_push_notifications') ?? true;
                if (!pushEnabled) return;
              } catch (_) {}

              await showNotification(title: title, body: body);
            }
          }
        }
      }
    }, onError: (e) {
      debugPrint('[LocalNotificationService] Notifications stream error: $e');
    });
  }

  /// Stops listening to Firestore notifications.
  static void stopListeningToNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  /// Triggers a native system notification.
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      debugPrint('[LocalNotificationService] Web notification: $title - $body');
      return;
    }

    final bool isDark = ThemeService.instance.isDark;
    
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'rakni_channel_id',
      'Rakni Notifications',
      channelDescription: 'Notification channel for Rakni parking service updates',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: isDark ? const Color(0xFFBDE500) : const Color(0xFF8CA800),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    try {
      final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] Error showing notification: $e');
    }
  }
}
