import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // İzin iste (iOS için gerekli, Android 13+ için de çıkar)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi.');
      
      // Token al
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _apiService.updateFcmToken(token);
      }

      // Token yenilenirse veritabanında güncelle
      _fcm.onTokenRefresh.listen((newToken) {
        _apiService.updateFcmToken(newToken);
      });

      // Ön plandayken gelen mesajlar (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Ön planda mesaj geldi: ${message.notification?.title}');
        // Gerekirse local_notifications ile göster
      });

      // Arka plandayken bildirime tıklanıp açıldığında (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Bildirime tıklanıp açıldı: ${message.notification?.title}');
        // İlgili chat ekranına yönlendirilebilir
      });

    } else {
      debugPrint('Kullanıcı bildirim iznini reddetti.');
    }
  }
}

// Kapalıyken (Terminated) gelen mesajları işlemek için top-level fonksiyon
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Arka plan mesajı geldi: ${message.messageId}");
}