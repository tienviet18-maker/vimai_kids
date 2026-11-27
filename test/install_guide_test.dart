import 'package:mai_an_learning/install/app_install.dart';
import 'package:mai_an_learning/install/install_env.dart';
import 'package:mai_an_learning/install/install_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, InstallEnv env, {bool en = false, Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('x'), bottom: InstallAppBarBottom(app: appInstall, en: en, env: env)),
      ),
    ));
    await tester.tap(find.byKey(const Key('install-pill')));
    await tester.pumpAndSettle();
  }

  testWidgets('no pill outside the web or once installed', (tester) async {
    for (final env in const [InstallEnv(web: false), InstallEnv(standalone: true)]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(bottom: InstallAppBarBottom(app: appInstall, en: false, env: env)))));
      expect(find.byKey(const Key('install-pill')), findsNothing);
    }
  });

  testWidgets('iPhone: three Safari steps; Android tab switches to Chrome', (tester) async {
    await open(tester, const InstallEnv());
    expect(find.text('Cài ViMai Kids lên điện thoại'), findsOneWidget);
    expect(find.text('Mở bằng Safari'), findsOneWidget);
    expect(find.text('Bấm Chia sẻ'), findsOneWidget);
    expect(find.byKey(const Key('install-step-3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('install-android')));
    await tester.pumpAndSettle();
    expect(find.text('Mở bằng Chrome'), findsOneWidget);
    await tester.tap(find.byKey(const Key('install-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('install-guide')), findsNothing);
  });

  testWidgets('Android with Chrome prompt: one-tap button; Facebook: copy link', (tester) async {
    await open(tester, const InstallEnv(platform: InstallPlatform.android, canPrompt: true, inAppBrowser: true));
    expect(find.byKey(const Key('install-now')), findsOneWidget);
    expect(find.byKey(const Key('install-copy-link')), findsOneWidget);
  });

  for (final en in [false, true]) {
    for (final size in const [Size(320, 568), Size(360, 640), Size(430, 932)]) {
      testWidgets('fits ${en ? 'English' : 'Vietnamese'} at ${size.width.toInt()}x${size.height.toInt()}, large text', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await open(tester, const InstallEnv(platform: InstallPlatform.android, canPrompt: true, inAppBrowser: true), en: en, size: size);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const Key('install-step-1')), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('follows the phone language: Japanese phone, Japanese guide', (tester) async {
    await open(tester, const InstallEnv(deviceLang: 'ja-JP'));
    expect(find.text('Safariで開く'), findsOneWidget);
    expect(find.text('共有をタップ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('install-android')));
    await tester.pumpAndSettle();
    expect(find.text('Chromeで開く'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown phone language falls back to the app language', (tester) async {
    await open(tester, const InstallEnv(deviceLang: 'ne-NP'));
    expect(find.text('Mở bằng Safari'), findsOneWidget);
  });

  for (final lang in ['ja', 'id', 'zh', 'ko', 'th']) {
    testWidgets('fits in $lang at 320x568, large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, InstallEnv(platform: InstallPlatform.android, canPrompt: true, inAppBrowser: true, deviceLang: lang), size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('install-ios')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
