import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'browser_navigation.dart';

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
    final destination = switch (_platform) {
      VisitorPlatform.ios => widget.config.appStoreUrl,
      VisitorPlatform.android => widget.config.googlePlayUrl,
      VisitorPlatform.huawei =>
        widget.config.huaweiAppGalleryUrl ?? widget.config.googlePlayUrl,
      VisitorPlatform.desktop => null,
    };

    if (destination != null) {
      replaceLocation(destination);
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
  const _DownloadCard({required this.config, required this.platform});

  final AppConfig config;
  final VisitorPlatform platform;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final logo = _AppLogo(path: config.logoPath, size: compact ? 112 : 190);
        final content = _CardContent(config: config, platform: platform);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(compact ? 28 : 36),
            border: Border.all(color: const Color(0xFFE4E7ED)),
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
                ? Column(children: [logo, const SizedBox(height: 28), content])
                : Row(
                    children: [
                      Expanded(flex: 4, child: Center(child: logo)),
                      const SizedBox(width: 52),
                      Expanded(flex: 6, child: content),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.config, required this.platform});

  final AppConfig config;
  final VisitorPlatform platform;

  @override
  Widget build(BuildContext context) {
    final isRedirecting = platform != VisitorPlatform.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get ${config.appName}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: const Color(0xFF171A2B),
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isRedirecting
              ? 'Taking you to the right app store…'
              : 'Choose your device to download the app.',
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
        _StoreButtons(config: config, platform: platform),
        const SizedBox(height: 22),
        Text(
          isRedirecting
              ? 'If nothing happens, use the button above.'
              : 'Available for iOS, Android, and Huawei devices',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9296A8)),
        ),
      ],
    );
  }
}

class _StoreButtons extends StatelessWidget {
  const _StoreButtons({required this.config, required this.platform});

  final AppConfig config;
  final VisitorPlatform platform;

  @override
  Widget build(BuildContext context) {
    final desktop = platform == VisitorPlatform.desktop;
    final buttons = <Widget>[
      if (desktop || platform == VisitorPlatform.ios)
        _StoreButton(
          icon: Icons.apple,
          eyebrow: 'Download on the',
          label: 'App Store',
          onPressed: () => assignLocation(config.appStoreUrl),
        ),
      if (desktop ||
          platform == VisitorPlatform.android ||
          (platform == VisitorPlatform.huawei &&
              config.huaweiAppGalleryUrl == null))
        _StoreButton(
          icon: Icons.shop_rounded,
          eyebrow: 'Get it on',
          label: 'Google Play',
          onPressed: () => assignLocation(config.googlePlayUrl),
        ),
      if (config.huaweiAppGalleryUrl case final url?)
        if (desktop || platform == VisitorPlatform.huawei)
          _StoreButton(
            icon: Icons.apps_rounded,
            eyebrow: 'Explore it on',
            label: 'AppGallery',
            onPressed: () => assignLocation(url),
          ),
      if (desktop)
        if (config.otherDevicesUrl case final url?)
          _StoreButton(
            icon: Icons.language_rounded,
            eyebrow: 'Open on',
            label: 'Other devices',
            onPressed: () => assignLocation(url),
          ),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
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
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 27),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF181A24),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = switch (path) {
      final value when value.startsWith('data:image/') => Image.memory(
        base64Decode(value.substring(value.indexOf(',') + 1)),
        fit: BoxFit.contain,
        errorBuilder: _errorBuilder,
      ),
      final value when value.startsWith('https://') => Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: _errorBuilder,
      ),
      _ => Image.asset(path, fit: BoxFit.contain, errorBuilder: _errorBuilder),
    };

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
        child: image,
      ),
    );
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stack) {
    return Icon(
      Icons.apps_rounded,
      size: size * 0.55,
      color: const Color(0xFF6558F5),
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
