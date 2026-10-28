import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'browser_user_agent.dart';

/// The browser built into another app (Messenger, Facebook, Zalo, LINE,
/// Instagram, TikTok...), or null. Google refuses to sign in there and
/// "Add to Home Screen" is missing, so [InAppBrowserBanner] points to
/// Safari / Chrome. Same list as vimai.jp.
String? inAppBrowserName([String? userAgent]) {
  final ua = userAgent ?? browserUserAgent();
  final lower = ua.toLowerCase();
  // Messenger also sends FBAN / FB_IAB, so it is checked first.
  if (lower.contains('messenger')) return 'Messenger';
  const apps = {
    'FBAN': 'Facebook',
    'FBAV': 'Facebook',
    'FB_IAB': 'Facebook',
    'Instagram': 'Instagram',
    'Zalo': 'Zalo',
    'Line/': 'LINE',
    'musical_ly': 'TikTok',
    'BytedanceWebview': 'TikTok',
    'TikTok': 'TikTok',
    'Threads': 'Threads',
  };
  for (final e in apps.entries) {
    if (ua.contains(e.key)) return e.value;
  }
  return null;
}

/// Closable card over the top of the app when the web build is opened
/// inside Messenger, Facebook, Zalo...: open in Safari / Chrome, with a
/// "copy link" button. Same message as vimai.jp; every ViMai app has it.
/// Lives in `MaterialApp.builder`, above the navigator, so it brings its
/// own [Material] and uses no tooltips (there is no overlay up there).
class InAppBrowserBanner extends StatefulWidget {
  const InAppBrowserBanner({
    super.key,
    this.signIn = false,
    this.languageCode,
    this.appName,
  });

  /// Whether the app has Google sign-in, which is the main thing that
  /// breaks in those browsers.
  final bool signIn;

  /// 'vi', 'en' or 'ja'. Defaults to the app's locale.
  final String? languageCode;

  /// Overrides detection (tests).
  final String? appName;

  @override
  State<InAppBrowserBanner> createState() => _InAppBrowserBannerState();
}

class _InAppBrowserBannerState extends State<InAppBrowserBanner> {
  late final String? _app =
      widget.appName ?? (kIsWeb ? inAppBrowserName() : null);
  bool _closed = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    if (app == null || _closed) return const SizedBox.shrink();
    final t = _Copy.of(
      widget.languageCode ??
          Localizations.maybeLocaleOf(context)?.languageCode ??
          'vi',
    );
    return SafeArea(
      bottom: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              key: const Key('in-app-banner'),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF2C94C)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                        height: 1.45,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title(app),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.signIn ? t.bodySignIn : t.body),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('in-app-copy'),
                            onPressed: _copy,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1F2937),
                              side: const BorderSide(color: Color(0xFFF2C94C)),
                              backgroundColor: Colors.white,
                            ),
                            icon: Icon(
                              _copied ? Icons.check : Icons.copy_rounded,
                              size: 18,
                            ),
                            label: Text(_copied ? t.copied : t.copy),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Semantics(
                    label: t.close,
                    button: true,
                    child: IconButton(
                      key: const Key('in-app-close'),
                      onPressed: () => setState(() => _closed = true),
                      icon: const Icon(Icons.close, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Copy {
  const _Copy(
    this.title,
    this.bodySignIn,
    this.body,
    this.copy,
    this.copied,
    this.close,
  );

  final String Function(String app) title;
  final String bodySignIn;
  final String body;
  final String copy;
  final String copied;
  final String close;

  static _Copy of(String lang) => switch (lang) {
        'en' => _en,
        'ja' => _ja,
        _ => _vi,
      };

  static final _vi = _Copy(
    (app) => 'Bạn đang mở trong ứng dụng $app',
    'Bấm nút ⋯ rồi chọn "Mở bằng trình duyệt" (Safari/Chrome) để đăng nhập '
        'Google và thêm app ra màn hình chính.',
    'Bấm nút ⋯ rồi chọn "Mở bằng trình duyệt" (Safari/Chrome) để thêm app '
        'ra màn hình chính và giữ dữ liệu học không bị mất.',
    'Sao chép link',
    'Đã chép link',
    'Đóng',
  );

  static final _en = _Copy(
    (app) => 'You are inside the $app app',
    'Tap ⋯ and choose "Open in browser" (Safari/Chrome) to sign in with '
        'Google and add the app to your home screen.',
    'Tap ⋯ and choose "Open in browser" (Safari/Chrome) to add the app to '
        'your home screen and keep your data safe.',
    'Copy link',
    'Link copied',
    'Close',
  );

  static final _ja = _Copy(
    (app) => '$appのアプリ内ブラウザで開いています',
    '「⋯」をタップして「ブラウザで開く」（Safari/Chrome）を選ぶと、Googleで'
        'ログインしたり、ホーム画面に追加したりできます。',
    '「⋯」をタップして「ブラウザで開く」（Safari/Chrome）を選ぶと、ホーム画面に'
        '追加でき、データも消えにくくなります。',
    'リンクをコピー',
    'コピーしました',
    '閉じる',
  );
}
