import 'package:deeplinks_qr/app_config.dart';
import 'package:deeplinks_qr/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop landing page shows both store choices', (tester) async {
    final config = AppConfig(
      appName: 'Example App',
      logoPath: 'assets/logo.png',
      appStoreUrl: Uri.parse('https://apps.apple.com/app/id123'),
      googlePlayUrl: Uri.parse(
        'https://play.google.com/store/apps/details?id=com.example.app',
      ),
    );

    await tester.pumpWidget(DownloadLandingApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Get Example App'), findsOneWidget);
    expect(find.text('App Store'), findsOneWidget);
    expect(find.text('Google Play'), findsOneWidget);
  });
}
