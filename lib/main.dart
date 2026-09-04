import 'package:flutter/material.dart';

import 'app_config.dart';
import 'download_landing_page.dart';
import 'link_builder_page.dart';
import 'smart_link.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final config = await AppConfig.load();
    runApp(DownloadLandingApp(config: config));
  } on Object catch (error) {
    runApp(ConfigurationErrorApp(message: error.toString()));
  }
}

class DownloadLandingApp extends StatelessWidget {
  const DownloadLandingApp({super.key, required this.config, this.initialUri});

  final AppConfig config;
  final Uri? initialUri;

  @override
  Widget build(BuildContext context) {
    final currentUri = initialUri ?? Uri.base;
    final smartLink = SmartLink.tryParse(currentUri);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: smartLink?.qrName ?? smartLink?.appName ?? 'Smart download QR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6558F5)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
        inputDecorationTheme: const InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        useMaterial3: true,
      ),
      home: smartLink == null
          ? LinkBuilderPage(defaultConfig: config, currentUri: currentUri)
          : DownloadLandingPage(config: smartLink),
    );
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
