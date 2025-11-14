// lib/services/notification_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    if (kIsWeb) {
      print("Push notifications are not supported on web.");
      return;
    }

    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Get the token and send it to the server
    await _sendTokenToServer(context);

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) {
      _sendTokenToServer(context, token: token);
    });
  }

  Future<void> _sendTokenToServer(BuildContext context, {String? token}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Only send token if user is authenticated
      if (authProvider.isAuthenticated) {
        String? tokenToSend = token ?? await _fcm.getToken();
        if (tokenToSend != null) {
          print("FCM Token: $tokenToSend");
          await authProvider.sendPushToken(tokenToSend);
        }
      }
    } catch (e) {
      print("Error sending FCM token to server: $e");
    }
  }
}