import 'dart:convert';

import 'app_config.dart';

class SmartLink extends AppConfig {
  const SmartLink({
    required super.appName,
    required super.logoPath,
    required super.appStoreUrl,
    required super.googlePlayUrl,
    super.huaweiAppGalleryUrl,
    super.otherDevicesUrl,
    this.qrName,
  });

  final String? qrName;

  static SmartLink? tryParse(Uri uri) {
    final query = uri.queryParameters;
    if (query['mode'] != 'download') {
      return null;
    }

    final ios = _tryHttps(query['ios']);
    final android = _tryHttps(query['android']);
    final appName = _clean(query['appName']);
    if (ios == null || android == null || appName == null) {
      return null;
    }

    return SmartLink(
      appName: appName,
      logoPath: _decodeLogo(query['logo']) ?? 'assets/logo.png',
      appStoreUrl: ios,
      googlePlayUrl: android,
      huaweiAppGalleryUrl: _tryHttps(query['huawei']),
      otherDevicesUrl: _tryHttps(query['other']),
      qrName: _clean(query['qrName']),
    );
  }

  Uri shareUri(Uri currentUri) {
    final query = <String, String>{
      'mode': 'download',
      'ios': appStoreUrl.toString(),
      'android': googlePlayUrl.toString(),
      'appName': appName,
      if (huaweiAppGalleryUrl case final url?) 'huawei': url.toString(),
      if (otherDevicesUrl case final url?) 'other': url.toString(),
      'qrName': ?qrName,
    };

    return currentUri.replace(queryParameters: query, fragment: '');
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String? _decodeLogo(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null || !cleaned.startsWith('p.')) {
      return cleaned;
    }

    try {
      final encoded = cleaned.substring(2);
      final paddingLength = (4 - encoded.length % 4) % 4;
      final bytes = base64Url.decode(
        encoded.padRight(encoded.length + paddingLength, '='),
      );
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } on FormatException {
      return null;
    }
  }

  static Uri? _tryHttps(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
