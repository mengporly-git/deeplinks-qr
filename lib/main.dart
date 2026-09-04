import 'package:flutter/material.dart';

import 'app_config.dart';
import 'browser_navigation.dart';

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
  const DownloadLandingApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6558F5)),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        useMaterial3: true,
      ),
      home: DownloadLandingPage(config: config),
    );
  }
}

class DownloadLandingPage extends StatefulWidget {
  const DownloadLandingPage({super.key, required this.config});

  final AppConfig config;

  @override
  State<DownloadLandingPage> createState() => _DownloadLandingPageState();
}

class _DownloadLandingPageState extends State<DownloadLandingPage> {
  late final VisitorPlatform _platform = detectVisitorPlatform();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectMobile());
  }

  void _redirectMobile() {
    switch (_platform) {
      case VisitorPlatform.android:
        replaceLocation(widget.config.googlePlayUrl);
        return;
      case VisitorPlatform.ios:
        replaceLocation(widget.config.appStoreUrl);
        return;
      case VisitorPlatform.desktop:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _PageBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _DownloadCard(
                    config: widget.config,
                    platform: _platform,
                    onAppStorePressed: () =>
                        assignLocation(widget.config.appStoreUrl),
                    onGooglePlayPressed: () =>
                        assignLocation(widget.config.googlePlayUrl),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({
    required this.config,
    required this.platform,
    required this.onAppStorePressed,
    required this.onGooglePlayPressed,
  });

  final AppConfig config;
  final VisitorPlatform platform;
  final VoidCallback onAppStorePressed;
  final VoidCallback onGooglePlayPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(compact ? 28 : 36),
            border: Border.all(color: const Color(0xFFE9EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A27335D),
                blurRadius: 50,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 28 : 56),
            child: compact
                ? Column(
                    children: [
                      _AppLogo(path: config.logoPath, size: 112),
                      const SizedBox(height: 28),
                      _CardContent(
                        config: config,
                        platform: platform,
                        onAppStorePressed: onAppStorePressed,
                        onGooglePlayPressed: onGooglePlayPressed,
                        centered: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: _AppLogo(path: config.logoPath, size: 190),
                        ),
                      ),
                      const SizedBox(width: 52),
                      Expanded(
                        flex: 6,
                        child: _CardContent(
                          config: config,
                          platform: platform,
                          onAppStorePressed: onAppStorePressed,
                          onGooglePlayPressed: onGooglePlayPressed,
                          centered: false,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.config,
    required this.platform,
    required this.onAppStorePressed,
    required this.onGooglePlayPressed,
    required this.centered,
  });

  final AppConfig config;
  final VisitorPlatform platform;
  final VoidCallback onAppStorePressed;
  final VoidCallback onGooglePlayPressed;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final isRedirecting = platform != VisitorPlatform.desktop;
    final titleStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
      color: const Color(0xFF171A2B),
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1.2,
    );

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Get ${config.appName}',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: titleStyle,
        ),
        const SizedBox(height: 14),
        Text(
          isRedirecting
              ? 'Taking you to the right app store…'
              : 'Choose your device to download the app.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF62677F),
            height: 1.5,
          ),
        ),
        if (isRedirecting) ...[
          const SizedBox(height: 18),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
        const SizedBox(height: 28),
        _StoreButtons(
          platform: platform,
          onAppStorePressed: onAppStorePressed,
          onGooglePlayPressed: onGooglePlayPressed,
        ),
        const SizedBox(height: 22),
        Text(
          'Available for iPhone, iPad, and Android',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9296A8)),
        ),
      ],
    );
  }
}

class _StoreButtons extends StatelessWidget {
  const _StoreButtons({
    required this.platform,
    required this.onAppStorePressed,
    required this.onGooglePlayPressed,
  });

  final VisitorPlatform platform;
  final VoidCallback onAppStorePressed;
  final VoidCallback onGooglePlayPressed;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (platform != VisitorPlatform.android)
        _StoreButton(
          icon: Icons.apple,
          eyebrow: 'Download on the',
          label: 'App Store',
          onPressed: onAppStorePressed,
        ),
      if (platform != VisitorPlatform.ios)
        _StoreButton(
          icon: Icons.shop_rounded,
          eyebrow: 'Get it on',
          label: 'Google Play',
          onPressed: onGooglePlayPressed,
        ),
    ];

    if (platform == VisitorPlatform.desktop) {
      return Wrap(spacing: 12, runSpacing: 12, children: buttons);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.icon,
    required this.eyebrow,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String eyebrow;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$eyebrow $label',
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF181A24),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(eyebrow, style: const TextStyle(fontSize: 10, height: 1.1)),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F6558F5),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.apps_rounded,
            size: size * 0.55,
            color: const Color(0xFF6558F5),
          ),
        ),
      ),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0EEFF), Color(0xFFF8F9FD), Color(0xFFEAF8FF)],
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            top: -110,
            left: -80,
            child: _Glow(color: Color(0x406A5BF7), size: 330),
          ),
          Positioned(
            right: -100,
            bottom: -130,
            child: _Glow(color: Color(0x4039BDE8), size: 380),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
