// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:pesacrowadmin_app/providers/auth_provider.dart';
import 'package:pesacrowadmin_app/providers/deal_provider.dart';
import 'package:pesacrowadmin_app/providers/fee_provider.dart';
import 'package:pesacrowadmin_app/providers/blacklist_provider.dart';
import 'package:pesacrowadmin_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DealProvider()),
          ChangeNotifierProvider(create: (_) => FeeProvider()),
          ChangeNotifierProvider(create: (_) => BlacklistProvider()),
        ],
        child: const PesaCrowAdminApp(),
      ),
    );

    // Verify that the login page title appears.
    expect(find.text('PesaCrow Admin'), findsOneWidget);
  });
}
