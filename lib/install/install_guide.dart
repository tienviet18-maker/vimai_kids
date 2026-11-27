import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'install_env.dart';
import 'install_strings.dart';

/// Colours of the guide; each ViMai app passes its own palette.
class InstallGuideStyle {
  const InstallGuideStyle({
    required this.sheet,
    required this.card,
    required this.line,
    required this.text,
    required this.muted,
    required this.accent,
    required this.action,
    this.onAction = Colors.white,
  });

  /// A light app (white pages).
  const InstallGuideStyle.light({required Color accent, Color? action})
      : this(
          sheet: Colors.white,
          card: const Color(0xFFF3F5F8),
          line: const Color(0xFFE2E6EC),
          text: const Color(0xFF0F172A),
          muted: const Color(0xFF5B6576),
          accent: accent,
          action: action ?? accent,
        );

  /// A dark app.
  const InstallGuideStyle.dark({required Color accent, Color? action})
      : this(
          sheet: const Color(0xFF161B22),
          card: const Color(0xFF1F2630),
          line: const Color(0xFF2D3540),
          text: const Color(0xFFECEFF3),
          muted: const Color(0xFF98A2B0),
          accent: accent,
          action: action ?? accent,
        );

  /// Sheet background.
  final Color sheet;

  /// Illustration cards.
  final Color card;
  final Color line;
  final Color text;
  final Color muted;

  /// Eyebrow, step numbers.
  final Color accent;

  /// The one-tap install button.
  final Color action;
  final Color onAction;
}

/// What the guide shows for one app.
class InstallGuideApp {
  const InstallGuideApp({
    required this.name,
    required this.style,
    this.icon = const NetworkImage('icons/Icon-192.png'),
  });

  /// Name under the home-screen icon (manifest `short_name`).
  final String name;

  /// The app icon, drawn as on the home screen. Default: the web icon the
  /// home screen will really use (web/icons/Icon-192.png).
  final ImageProvider icon;
  final InstallGuideStyle style;
}

/// Opens "Cài ứng dụng": three illustrated steps for iPhone (Safari) or
/// Android (Chrome), plus Chrome's one-tap install when the browser offers it.
Future<void> showInstallGuide(
  BuildContext context, {
  required InstallGuideApp app,
  required bool en,
  String? appLang,
  InstallEnv? env,
}) {
  final e = env ?? InstallEnv.current();
  final lang = InstallStrings.pick(device: e.deviceLang, app: appLang ?? (en ? 'en' : 'vi'));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Above the tab bar, not inside the tab.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => InstallGuideSheet(app: app, lang: lang, env: e),
  );
}

class InstallGuideSheet extends StatefulWidget {
  const InstallGuideSheet({super.key, required this.app, required this.lang, required this.env});

  final InstallGuideApp app;

  /// One of [InstallStrings.supported].
  final String lang;
  final InstallEnv env;

  @override
  State<InstallGuideSheet> createState() => _InstallGuideSheetState();
}

class _InstallGuideSheetState extends State<InstallGuideSheet> {
  late InstallPlatform _platform = widget.env.platform;
  bool _copied = false;
  String? _installResult;

  late final InstallStrings t = InstallStrings.of(widget.lang);
  String f(String text) => InstallStrings.fill(text, widget.app.name);
  InstallGuideStyle get s => widget.app.style;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
    if (mounted) setState(() => _copied = true);
  }

  Future<void> _install() async {
    final r = await promptInstall();
    if (mounted) setState(() => _installResult = r);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .92;
    final name = widget.app.name;
    final ios = _platform == InstallPlatform.ios;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH, maxWidth: 640),
      child: Material(
        key: const Key('install-guide'),
        color: s.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: s.text),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: s.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.eyebrow,
                            style: TextStyle(
                              color: s.accent,
                              fontSize: 11.5,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f(t.title),
                            style: TextStyle(
                              color: s.text,
                              fontSize: 25,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CloseButton(style: s, tooltip: t.close),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        f(t.intro),
                        style: TextStyle(color: s.muted, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(Icons.touch_app_outlined, t.chipOneTap, s),
                          _Chip(Icons.fullscreen_rounded, t.chipFullScreen, s),
                          _Chip(Icons.cloud_done_outlined, t.chipProgress, s),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _PlatformSwitch(
                        value: _platform,
                        style: s,
                        onChanged: (p) => setState(() => _platform = p),
                      ),
                      if (widget.env.canPrompt) ...[
                        const SizedBox(height: 16),
                        _OneTap(
                          name: name,
                          style: s,
                          t: t,
                          result: _installResult,
                          onTap: _install,
                        ),
                      ],
                      const SizedBox(height: 6),
                      ..._steps(ios, name),
                      const SizedBox(height: 14),
                      Text(
                        t.note,
                        style: TextStyle(color: s.muted, fontSize: 12, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _steps(bool ios, String name) {
    final inApp = widget.env.inAppBrowser;
    final copy = inApp
        ? Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              key: const Key('install-copy-link'),
              onPressed: _copyLink,
              style: OutlinedButton.styleFrom(
                foregroundColor: s.text,
                side: BorderSide(color: s.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_copied ? Icons.check_rounded : Icons.link_rounded, size: 18),
              label: Text(_copied ? t.copied : t.copyLink),
            ),
          )
        : null;
    final texts = ios ? t.iosSteps : t.androidSteps;
    final arts = <Widget>[
      _BrowserArt(style: s, label: ios ? 'Safari' : 'Chrome', safari: ios),
      ios
          ? _ShareSheetArt(
              style: s,
              share: t.share,
              swipe: t.swipeUp,
              rows: [
                (Icons.star_border_rounded, t.favourites),
                (Icons.find_in_page_outlined, t.findOnPage),
              ],
              target: t.addToHome,
            )
          : _MenuArt(
              style: s,
              icon: Icons.more_vert_rounded,
              label: t.menu,
              row: t.installApp,
              rowIcon: Icons.install_mobile_outlined,
            ),
      _AppArt(style: s, icon: widget.app.icon, name: name),
    ];
    final steps = [
      for (var i = 0; i < 3; i++)
        _StepData(
          title: texts[i].$1,
          body: _T.parse(f(texts[i].$2)),
          art: arts[i],
          extra: i == 0 ? copy : null,
        ),
    ];
    return [
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0) Divider(height: 1, color: s.line),
        _Step(no: i + 1, data: steps[i], style: s),
      ],
    ];
  }
}

class _T {
  const _T(this.text, {this.bold = false});
  final String text;
  final bool bold;

  /// `**bold**` parts are button names.
  static List<_T> parse(String text) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty) _T(parts[i], bold: i.isOdd),
    ];
  }
}

class _StepData {
  const _StepData({required this.title, required this.body, required this.art, this.extra});
  final String title;
  final List<_T> body;
  final Widget art;
  final Widget? extra;
}

class _Step extends StatelessWidget {
  const _Step({required this.no, required this.data, required this.style});

  final int no;
  final _StepData data;
  final InstallGuideStyle style;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          no.toString().padLeft(2, '0'),
          style: TextStyle(color: s.accent, fontSize: 30, height: 1, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 10),
        Text(data.title, style: TextStyle(color: s.text, fontSize: 18, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            for (final t in data.body)
              TextSpan(
                text: t.text,
                style: t.bold ? TextStyle(color: s.text, fontWeight: FontWeight.w700) : null,
              ),
          ]),
          style: TextStyle(color: s.muted, fontSize: 14.5, height: 1.55),
        ),
        if (data.extra != null) data.extra!,
      ],
    );
    return Padding(
      key: Key('install-step-$no'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          // Side by side like a printed guide; stacked on very narrow phones.
          if (box.maxWidth < 330) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 14), data.art],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 11, child: text),
              const SizedBox(width: 16),
              Expanded(flex: 9, child: Padding(padding: const EdgeInsets.only(top: 34), child: data.art)),
            ],
          );
        },
      ),
    );
  }
}

class _ArtCard extends StatelessWidget {
  const _ArtCard({required this.style, required this.child});
  final InstallGuideStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: style.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.line.withValues(alpha: .6)),
        ),
        alignment: Alignment.center,
        child: child,
      );
}

/// Safari's compass or a generic browser globe, with its name.
class _BrowserArt extends StatelessWidget {
  const _BrowserArt({required this.style, required this.label, required this.safari});
  final InstallGuideStyle style;
  final String label;
  final bool safari;

  @override
  Widget build(BuildContext context) => _ArtCard(
        style: style,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: safari
                  ? CustomPaint(painter: _CompassPainter(ring: style.text, needle: const Color(0xFFD9534F)))
                  : DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: style.text, width: 2.5)),
                      child: Icon(Icons.language_rounded, size: 34, color: style.text),
                    ),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: style.text, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.ring, required this.needle});
  final Color ring;
  final Color needle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..color = ring);
    final a = -math.pi / 4;
    Offset at(double ang, double len) => c + Offset(math.cos(ang), math.sin(ang)) * len;
    final tip = at(a, r * .72);
    final tail = at(a + math.pi, r * .72);
    final left = at(a + math.pi / 2, r * .17);
    final right = at(a - math.pi / 2, r * .17);
    canvas.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(), Paint()..color = needle);
    canvas.drawPath(
      Path()..moveTo(tail.dx, tail.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.ring != ring || old.needle != needle;
}

/// A toolbar button and the menu row it opens.
class _MenuArt extends StatelessWidget {
  const _MenuArt({
    required this.style,
    required this.icon,
    required this.label,
    required this.row,
    required this.rowIcon,
  });
  final InstallGuideStyle style;
  final IconData icon;
  final String label;
  final String row;
  final IconData rowIcon;

  @override
  Widget build(BuildContext context) => _ArtCard(
        style: style,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: style.text),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label, style: TextStyle(color: style.text, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Icon(rowIcon, size: 18, color: const Color(0xFF1F2A2E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row,
                      style: const TextStyle(color: Color(0xFF1F2A2E), fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// iOS share sheet: the Share button, swipe up, then the highlighted
/// "Thêm vào Màn hình chính" at the end of the list.
class _ShareSheetArt extends StatelessWidget {
  const _ShareSheetArt({
    required this.style,
    required this.share,
    required this.swipe,
    required this.rows,
    required this.target,
  });
  final InstallGuideStyle style;
  final String share;
  final String swipe;
  final List<(IconData, String)> rows;
  final String target;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF2F2F4);
    const dim = Color(0xFF9A9AA0);
    Widget row(IconData icon, String label, {bool on = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: on
              ? BoxDecoration(
                  color: const Color(0xFF4A4A50),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: style.accent, width: 1.6),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 15, color: on ? ink : dim),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: on ? ink : dim,
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
    return _ArtCard(
      style: style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ios_share_rounded, size: 24, color: style.text),
              const SizedBox(width: 6),
              Flexible(
                child: Text(share, style: TextStyle(color: style.text, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The share sheet, pulled up.
          Container(
            padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C30),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: style.accent),
                    Flexible(
                      child: Text(
                        swipe,
                        style: TextStyle(color: style.accent, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                for (final r in rows) row(r.$1, r.$2),
                row(Icons.add_box_outlined, target, on: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The app icon as it will sit on the home screen.
class _AppArt extends StatelessWidget {
  const _AppArt({required this.style, required this.icon, required this.name});
  final InstallGuideStyle style;
  final ImageProvider icon;
  final String name;

  @override
  Widget build(BuildContext context) => _ArtCard(
        style: style,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 5))],
                image: DecorationImage(image: icon, fit: BoxFit.cover, onError: (e, st) {}),
              ),
            ),
            const SizedBox(height: 10),
            Text(name, style: TextStyle(color: style.text, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label, this.style);
  final IconData icon;
  final String label;
  final InstallGuideStyle style;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.line.withValues(alpha: .6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: style.accent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: style.text, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _PlatformSwitch extends StatelessWidget {
  const _PlatformSwitch({required this.value, required this.style, required this.onChanged});
  final InstallPlatform value;
  final InstallGuideStyle style;
  final ValueChanged<InstallPlatform> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(InstallPlatform p, IconData icon, String label) {
      final on = p == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: InkWell(
            key: Key('install-${p.name}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: on ? style.sheet : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: on ? const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: on ? style.text : style.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: on ? style.text : style.muted,
                        fontSize: 13.5,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: style.card, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          tab(InstallPlatform.ios, Icons.phone_iphone_rounded, 'iPhone · iPad'),
          tab(InstallPlatform.android, Icons.android_rounded, 'Android'),
        ],
      ),
    );
  }
}

/// Chrome's own install dialog, when the browser offers it.
class _OneTap extends StatelessWidget {
  const _OneTap({
    required this.name,
    required this.style,
    required this.t,
    required this.result,
    required this.onTap,
  });
  final String name;
  final InstallGuideStyle style;
  final InstallStrings t;
  final String? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String f(String text) => InstallStrings.fill(text, name);
    if (result == 'accepted') {
      return Row(
        children: [
          Icon(Icons.check_circle_rounded, color: style.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              f(t.installed),
              style: TextStyle(color: style.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('install-now'),
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: style.action,
            foregroundColor: style.onAction,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.download_rounded),
          label: Text(f(t.installNow)),
        ),
        const SizedBox(height: 6),
        Text(
          t.oneTapNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: style.muted, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.style, required this.tooltip});
  final InstallGuideStyle style;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          key: const Key('install-close'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.line),
            ),
            child: Icon(Icons.close_rounded, color: style.text),
          ),
        ),
      );
}

/// The small "Cài ứng dụng" pill for the top of the app. Hidden when the app
/// already runs from the home screen or outside the web.
class InstallPill extends StatelessWidget {
  const InstallPill({super.key, required this.app, required this.en, this.appLang, this.env});

  final InstallGuideApp app;
  final bool en;

  /// The app's language code (vi, en, ja...) when it has more than vi/en.
  final String? appLang;
  final InstallEnv? env;

  @override
  Widget build(BuildContext context) {
    final e = env ?? InstallEnv.current();
    if (!e.offer) return const SizedBox.shrink();
    final s = app.style;
    return Semantics(
      button: true,
      child: InkWell(
        key: const Key('install-pill'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => showInstallGuide(context, app: app, en: en, appLang: appLang, env: e),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.install_mobile_outlined, size: 15, color: s.text),
              const SizedBox(width: 6),
              Text(
                InstallStrings.of(InstallStrings.pick(device: e.deviceLang, app: appLang ?? (en ? 'en' : 'vi'))).pill,
                maxLines: 1,
                style: TextStyle(color: s.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pill on the right, on its own slim row at the top of a page.
class InstallPillRow extends StatelessWidget {
  const InstallPillRow({
    super.key,
    required this.app,
    required this.en,
    this.appLang,
    this.env,
    this.padding = const EdgeInsets.only(top: 6),
  });

  final InstallGuideApp app;
  final bool en;
  final String? appLang;
  final InstallEnv? env;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final e = env ?? InstallEnv.current();
    if (!e.offer) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Align(alignment: Alignment.centerRight, child: InstallPill(app: app, en: en, appLang: appLang, env: e)),
    );
  }
}

/// For an [AppBar]'s `bottom:`: a slim row with the pill on the right, zero
/// height when the guide is not offered (app opened from the home screen,
/// iOS/Android build, tests).
class InstallAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  InstallAppBarBottom({super.key, required this.app, required this.en, this.appLang, InstallEnv? env})
      : env = env ?? InstallEnv.current();

  final InstallGuideApp app;
  final bool en;
  final String? appLang;
  final InstallEnv env;

  @override
  Size get preferredSize => Size.fromHeight(env.offer ? 42 : 0);

  @override
  Widget build(BuildContext context) {
    if (!env.offer) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Align(alignment: Alignment.centerRight, child: InstallPill(app: app, en: en, appLang: appLang, env: env)),
    );
  }
}
