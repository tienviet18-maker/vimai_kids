/// Where the web app runs, for the "install on your phone" guide.
library;

import 'package:flutter/foundation.dart';

import 'install_env_stub.dart'
    if (dart.library.js_interop) 'install_env_web.dart' as impl;

enum InstallPlatform { ios, android }

/// What the browser allows. Tests build their own.
class InstallEnv {
  const InstallEnv({
    this.web = true,
    this.platform = InstallPlatform.ios,
    this.standalone = false,
    this.canPrompt = false,
    this.inAppBrowser = false,
    this.deviceLang,
  });

  /// Read from the page (web/index.html defines `vimaiInstallState`).
  factory InstallEnv.current() {
    if (!kIsWeb) return const InstallEnv(web: false);
    final parts = impl.installState().split(',');
    final flags = parts.toSet();
    String? lang;
    for (final p in parts) {
      if (p.startsWith('lang=')) lang = p.substring(5);
    }
    return InstallEnv(
      platform: flags.contains('android') ? InstallPlatform.android : InstallPlatform.ios,
      standalone: flags.contains('standalone'),
      canPrompt: flags.contains('prompt'),
      inAppBrowser: flags.contains('inapp'),
      deviceLang: lang,
    );
  }

  final bool web;
  final InstallPlatform platform;

  /// Already opened from the home screen icon.
  final bool standalone;

  /// Chrome can install in one tap.
  final bool canPrompt;

  /// Inside Facebook, Zalo, Messenger...: must open in Safari / Chrome first.
  final bool inAppBrowser;

  /// The phone's language (navigator.language, e.g. `ja-JP`); the guide
  /// speaks it when it can.
  final String? deviceLang;

  /// Whether to offer the guide at all.
  bool get offer => web && !standalone;
}

/// Chrome's install prompt: 'accepted', 'dismissed' or 'unavailable'.
Future<String> promptInstall() => impl.promptInstall();
