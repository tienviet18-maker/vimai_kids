# Master product pass — changelog

Date: 2026-08-29  
Git: workspace is not a git repository (no commit).

## Added

- KanjiVG basic 92 kana SVGs + `catalog.json` + `assets/licenses/KANJIVG_LICENSE.md`
- Stroke path player: numbers, replay, slow, prev/next, geometric guided tracing, free write
- Home subject chooser when mastery is empty
- Continue-learning prefers `lastWorld` among recent/review items
- Parent today / learning minutes / strengths / needs-practice / split support-about
- `SessionBinder` records elapsed seconds into `dailyLearningState`
- Human audio inventory + recording spec + 150-item manifest (all NOT_RECORDED)
- Tests: KanjiVG 46+46 paths, human recordings = 0, lastWorld recommendation

## Changed

- Progress: “Đang luyện” chip (internal IDs still hidden)
- Thinking / Math / Japanese / Vietnamese hubs: AppStrings titles where it did not break tests
- LessonFeedback: icon + text (not color alone)
- README.md product identity; README_DEV_AUDIO documents TTS fallback honestly
- Creativity: VimaiColor instead of Material accents

## Protected / not rewritten

- `lib/core/audio/audio_service.dart` architecture
- `lib/features/games/logic/game_board_metrics.dart`
- `lib/features/games/logic/falling_layout.dart`
- `MathQuestionGenerator`
- 913 existing WAV paths (no bulk regen, no `--force-vi`)
- Branding ViMai Kids / vimai.support@gmail.com
- Navigation routes

## Deliberately not done

- No human WAV files created or faked
- No invented stroke paths for dakuten/yoon
- No force-quit when daily minutes are met (soft Home banner only)
