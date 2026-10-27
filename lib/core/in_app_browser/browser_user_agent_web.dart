import 'dart:js_interop';

@JS('navigator.userAgent')
external String get _userAgent;

/// The browser's user agent, or '' outside the web.
String browserUserAgent() {
  try {
    return _userAgent;
  } catch (_) {
    return '';
  }
}
