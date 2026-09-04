import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.logoPath,
    required this.appStoreUrl,
    required this.googlePlayUrl,
    this.huaweiAppGalleryUrl,
    this.otherDevicesUrl,
  });

  final String appName;
  final String logoPath;
  final Uri appStoreUrl;
  final Uri googlePlayUrl;
  final Uri? huaweiAppGalleryUrl;
  final Uri? otherDevicesUrl;

  static Future<AppConfig> load() async {
    final source = await rootBundle.loadString('assets/config.json');
    final json = jsonDecode(source);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('assets/config.json must contain an object.');
    }

    return AppConfig(
      appName: _optionalString(json, 'appName') ?? '',
      logoPath: _requiredString(json, 'logoPath'),
      appStoreUrl: _requiredHttpsUrl(json, 'appStoreUrl'),
      googlePlayUrl: _requiredHttpsUrl(json, 'googlePlayUrl'),
      huaweiAppGalleryUrl: _optionalHttpsUrl(json, 'huaweiAppGalleryUrl'),
      otherDevicesUrl: _optionalHttpsUrl(json, 'otherDevicesUrl'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('"$key" must be a non-empty string.');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value == '') {
      return null;
    }
    if (value is! String) {
      throw FormatException('"$key" must be text or empty.');
    }
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static Uri _requiredHttpsUrl(Map<String, dynamic> json, String key) {
    final value = _requiredString(json, key);
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('"$key" must be a valid HTTPS URL.');
    }
    return uri;
  }

  static Uri? _optionalHttpsUrl(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value == '') {
      return null;
    }
    if (value is! String) {
      throw FormatException('"$key" must be a valid HTTPS URL or empty.');
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('"$key" must be a valid HTTPS URL or empty.');
    }
    return uri;
  }
}
