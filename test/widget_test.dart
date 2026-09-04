import 'package:deeplinks_qr/app_config.dart';
import 'package:deeplinks_qr/main.dart';
import 'package:deeplinks_qr/smart_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final config = AppConfig(
  appName: 'Example App',
  logoPath: 'assets/logo.png',
  appStoreUrl: Uri.parse('https://apps.apple.com/app/id123'),
  googlePlayUrl: Uri.parse(
    'https://play.google.com/store/apps/details?id=com.acme.demo',
  ),
);

void main() {
  testWidgets('root page shows smart-link input form', (tester) async {
    await tester.pumpWidget(
      DownloadLandingApp(
        config: config,
        initialUri: Uri.parse('https://example.com/downloads/'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your smart download QR'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Link for App Store'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Link for Google Play'),
      findsOneWidget,
    );
    expect(find.text('Link for Huawei AppGallery'), findsNothing);
    expect(find.text('Link for other devices'), findsNothing);
    expect(find.text('Name your QR (optional)'), findsNothing);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.text('Create QR code'), findsOneWidget);

    const help =
        'Enter the link to the application in the App Store for iOS devices.';
    expect(find.byTooltip(help), findsOneWidget);
    await tester.tap(find.byTooltip(help));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(help), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'App name'),
      'Example App',
    );
    await tester.ensureVisible(find.text('Create QR code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create QR code'));
    await tester.pumpAndSettle();
    expect(find.text('Your smart QR is ready'), findsOneWidget);
    expect(find.text('Download QR'), findsOneWidget);
    expect(find.byKey(const ValueKey('generated-qr')), findsOneWidget);
  });

  testWidgets('generated destination shows desktop store choices', (
    tester,
  ) async {
    final destination = SmartLink(
      appName: config.appName,
      logoPath: config.logoPath,
      appStoreUrl: config.appStoreUrl,
      googlePlayUrl: config.googlePlayUrl,
    ).shareUri(Uri.parse('https://example.com/downloads/'));

    await tester.pumpWidget(
      DownloadLandingApp(config: config, initialUri: destination),
    );
    await tester.pumpAndSettle();

    expect(find.text('Get Example App'), findsOneWidget);
    expect(find.text('App Store'), findsOneWidget);
    expect(find.text('Google Play'), findsOneWidget);
  });

  test('smart-link URLs round-trip through query parameters', () {
    final link = SmartLink(
      appName: 'Example App',
      logoPath: 'assets/logo.png',
      appStoreUrl: config.appStoreUrl,
      googlePlayUrl: config.googlePlayUrl,
      huaweiAppGalleryUrl: Uri.parse('https://appgallery.huawei.com/app/test'),
      otherDevicesUrl: Uri.parse('https://example.com/download'),
      qrName: 'Launch QR',
    );

    final uri = link.shareUri(Uri.parse('https://example.com/downloads/'));
    final parsed = SmartLink.tryParse(uri)!;

    expect(parsed.appName, 'Example App');
    expect(parsed.huaweiAppGalleryUrl, link.huaweiAppGalleryUrl);
    expect(parsed.otherDevicesUrl, link.otherDevicesUrl);
    expect(parsed.qrName, 'Launch QR');
  });
}
