import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ikiotms_mobile/app.dart';

void main() {
  testWidgets('App shell smoke test — bottom nav visible', (WidgetTester tester) async {
    // Wrap in ProviderScope just like main.dart does.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // The bottom navigation bar should show the three Vietnamese tab labels.
    expect(find.text('Lịch làm'), findsOneWidget);
    expect(find.text('Chấm công'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
  });
}
