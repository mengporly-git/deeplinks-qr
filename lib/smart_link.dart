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
      logoPath: _clean(query['logo']) ?? 'assets/logo.png',
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
      'logo': logoPath,
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

  static Uri? _tryHttps(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
