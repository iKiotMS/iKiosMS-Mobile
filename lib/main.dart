import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Handles push messages while the app is terminated or in the background.
/// Must be a top-level function annotated with `@pragma('vm:entry-point')`
/// so it survives tree-shaking and can run in its own isolate. We don't need
/// to do anything here — the OS renders the notification — but registering a
/// handler is required for background delivery to work.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty.
}

/// Entry point.
/// dotenv is loaded FIRST so kBaseUrl is available when the app starts.
/// ProviderScope is required for Riverpod to work.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the bundled .env file.
  await dotenv.load(fileName: '.env');

  // Initialize Firebase (Google sign-in + FCM push). Guarded so the app still
  // boots with phone/password login if Firebase isn't configured yet — see
  // FIREBASE_SETUP.md and firebase_options.dart.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase chưa được cấu hình / khởi tạo thất bại: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
