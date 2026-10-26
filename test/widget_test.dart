import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lobsense_mobile_app/main.dart';
import 'package:lobsense_mobile_app/core/services/auth_provider.dart';

void main() {
  testWidgets('LobsenseMobileApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const LobsenseMobileApp(),
      ),
    );

    // App should build without crashing
    expect(find.byType(LobsenseMobileApp), findsOneWidget);
  });
}
