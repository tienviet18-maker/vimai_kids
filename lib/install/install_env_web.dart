import 'dart:js_interop';

@JS('vimaiInstallState')
external JSString _installState();

@JS('vimaiInstall')
external JSPromise<JSString> _install();

/// Comma-separated flags from web/index.html: ios, android, standalone,
/// prompt (Chrome's install prompt is ready), inapp.
String installState() {
  try {
    return _installState().toDart;
  } catch (_) {
    return '';
  }
}

/// Shows Chrome's own install prompt: 'accepted', 'dismissed' or
/// 'unavailable'.
Future<String> promptInstall() async {
  try {
    return (await _install().toDart).toDart;
  } catch (_) {
    return 'unavailable';
  }
}
