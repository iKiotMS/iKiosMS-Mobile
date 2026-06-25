import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point.
/// dotenv is loaded FIRST so kBaseUrl is available when the app starts.
/// ProviderScope is required for Riverpod to work.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the bundled .env file.
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
