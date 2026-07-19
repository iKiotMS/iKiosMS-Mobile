import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/push_api_service.dart';

part 'push_service.g.dart';

/// Android notification channel used for foreground display. The id must match
/// `com.google.firebase.messaging.default_notification_channel_id` in the
/// AndroidManifest so background/system-tray pushes land on the same channel.
const AndroidNotificationChannel kAndroidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Thông báo quan trọng',
  description: 'Kênh thông báo đẩy của iKiot',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@Riverpod(keepAlive: true)
PushService pushService(Ref ref) => PushService(ref);

/// Orchestrates FCM push: requesting permission, obtaining the device token,
/// and registering/unregistering it with the backend. Mirrors the web
/// `fcm.ts`. Every method no-ops gracefully when Firebase isn't configured, so
/// the rest of the app keeps working.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _refreshHooked = false;
  bool _foregroundHooked = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// Sets up foreground display: FCM does NOT auto-show `notification` messages
  /// while the app is open, so we render them ourselves via a local
  /// notification. Safe to call multiple times (hooks only once).
  Future<void> initForeground() async {
    if (!_firebaseReady || _foregroundHooked) return;
    _foregroundHooked = true;
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      // Android 8+ requires a channel; create it up front.
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(kAndroidChannel);

      // iOS shows foreground notifications itself once we opt in.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (e) {
      debugPrint('Khởi tạo thông báo foreground thất bại: $e');
    }
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // data-only message: nothing to show

    // iOS already displays it via setForegroundNotificationPresentationOptions,
    // so only render manually on Android to avoid a duplicate.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kAndroidChannel.id,
          kAndroidChannel.name,
          channelDescription: kAndroidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Requests notification permission, gets the FCM token and registers it.
  /// Returns true if a token was registered. Safe to call more than once.
  Future<bool> register() async {
    if (!_firebaseReady) return false;
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      final token = await messaging.getToken();
      if (token == null) return false;

      await _ref.read(pushApiServiceProvider).registerToken(token);

      // FCM rotates tokens; re-register on refresh (hook only once).
      if (!_refreshHooked) {
        _refreshHooked = true;
        messaging.onTokenRefresh.listen((newToken) async {
          try {
            await _ref.read(pushApiServiceProvider).registerToken(newToken);
          } catch (e) {
            debugPrint('Đăng ký lại FCM token thất bại: $e');
          }
        });
      }
      return true;
    } catch (e) {
      debugPrint('Bật thông báo thất bại: $e');
      return false;
    }
  }

  /// Whether the OS notification permission is currently granted.
  Future<bool> isEnabled() async {
    if (!_firebaseReady) return false;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;
      return status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Removes this device's token from the backend and deletes it locally.
  /// Call on logout so the next account on this device doesn't receive pushes
  /// meant for the previous one.
  Future<void> unregister() async {
    if (!_firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        await _ref.read(pushApiServiceProvider).removeToken(token);
      }
      await messaging.deleteToken();
    } catch (e) {
      debugPrint('Gỡ FCM token thất bại: $e');
    }
  }
}
