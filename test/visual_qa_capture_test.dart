import 'package:flutter_test/flutter_test.dart';

/// Automated PNG capture via RepaintBoundary.toImage hung on this Windows host
/// (large room PNG decode). Visual QA must be done on the live Chrome app.
///
/// Keep this file so CI knows capture is intentional-skip until a stable harness exists.
void main() {
  test('visual QA capture harness placeholder', () {
    expect(true, isTrue);
  }, skip: 'RepaintBoundary.toImage hangs with full room assets; inspect live flutter run -d chrome');
}
