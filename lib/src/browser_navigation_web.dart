import 'package:web/web.dart' as web;

enum VisitorPlatform { android, huawei, ios, desktop }

VisitorPlatform detectVisitorPlatform() {
  final navigator = web.window.navigator;
  final userAgent = navigator.userAgent.toLowerCase();

  if (userAgent.contains('huawei') || userAgent.contains('honor')) {
    return VisitorPlatform.huawei;
  }

  if (userAgent.contains('android')) {
    return VisitorPlatform.android;
  }

  final isIos =
      userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod') ||
      (userAgent.contains('macintosh') && navigator.maxTouchPoints > 1);

  return isIos ? VisitorPlatform.ios : VisitorPlatform.desktop;
}

void replaceLocation(Uri url) => web.window.location.replace(url.toString());

void assignLocation(Uri url) => web.window.location.assign(url.toString());

void openInNewTab(Uri url) =>
    web.window.open(url.toString(), '_blank', 'noopener,noreferrer');
