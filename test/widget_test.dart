import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mai_an_learning/main.dart';
import 'package:mai_an_learning/core/branding/config.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/repositories/kana_repository_impl.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanaRepositoryProvider.overrideWithValue(KanaRepositoryImpl()),
          contentRepositoryProvider.overrideWithValue(ContentRepository()),
          profileRepositoryProvider.overrideWithValue(ProfileRepository()),
          masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
          audioServiceProvider.overrideWithValue(AudioService()),
        ],
        child: const MaiAnApp(),
      ),
    );
    await tester.pump();
    expect(find.text(AppBrand.productBrand), findsNothing);
    expect(find.textContaining('Phạm Tiến Việt'), findsNothing);
    expect(find.textContaining('Tạo bởi'), findsNothing);
    expect(find.textContaining('tienviet18'), findsNothing);
  });
}
