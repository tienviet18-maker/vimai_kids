import 'package:mai_an_learning/core/in_app_browser/in_app_browser_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('in-app browsers are recognised, normal ones are not', () {
    const fb = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 '
        '[FBAN/FBIOS;FBAV/480.0.0;FBBV/1]';
    const messenger = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 '
        '[FBAN/MessengerForiOS;FBAV/480.0.0]';
    const zalo =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/128.0 '
        'Mobile Safari/537.36 Zalo android/12';
    const safari = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
        'Mobile/15E148 Safari/604.1';
    expect(inAppBrowserName(fb), 'Facebook');
    expect(inAppBrowserName(messenger), 'Messenger');
    expect(inAppBrowserName(zalo), 'Zalo');
    expect(inAppBrowserName(safari), isNull);
  });

  testWidgets('the in-app banner copies the link and can be closed', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    // Where the apps put it: MaterialApp.builder, above the navigator.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Stack(
          children: [
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InAppBrowserBanner(appName: 'Zalo', languageCode: 'vi'),
            ),
          ],
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    expect(find.text('Bạn đang mở trong ứng dụng Zalo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('in-app-copy')));
    await tester.pumpAndSettle();
    expect(find.text('Đã chép link'), findsOneWidget);
    expect(copied, isNotEmpty);
    await tester.tap(find.byKey(const Key('in-app-close')));
    await tester.pump();
    expect(find.byKey(const Key('in-app-banner')), findsNothing);
  });

  testWidgets('no banner in a normal browser or app', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InAppBrowserBanner())),
    );
    expect(find.byKey(const Key('in-app-banner')), findsNothing);
  });
}
