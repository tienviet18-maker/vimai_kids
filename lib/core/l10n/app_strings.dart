import 'package:flutter/widgets.dart';

import '../../domain/models/child_profile.dart';

enum UiLang { vi, en, ja }

class AppStrings {
  final UiLang lang;
  const AppStrings(this.lang);

  static UiLang langFromProfile(ChildProfile? profile, BuildContext context) {
    final stored = profile?.settings['uiLang'] as String?;
    if (stored == 'en') return UiLang.en;
    if (stored == 'ja') return UiLang.ja;
    if (stored == 'vi') return UiLang.vi;
    return UiLang.vi;
  }

  static AppStrings of(ChildProfile? profile, BuildContext context) {
    return AppStrings(langFromProfile(profile, context));
  }

  String get helloToday => _t('Hôm nay mình học gì nhỉ?', "What shall we learn today?", 'きょうはなにをまなぶ？');
  String get todayTitle => _t('Hôm nay', 'Today', 'きょう');
  String ageLabel(int age) => _t('$age tuổi', '$age years old', '$ageさい');
  String get continueTitle => _t('Học tiếp', 'Keep learning', 'つづける');
  String get continueFriendly => _t('Tiếp tục nào!', 'Let’s continue!', 'つづけよう！');
  String get beginShort => _t('Bắt đầu', 'Start', 'はじめる');
  String get togetherWithMai => _t('Tiếp tục cùng Mai', 'Continue with Mai', 'まいとつづけよう');
  String get japaneseAction => _t('Khám phá chữ Nhật', 'Explore Japanese letters', 'にほんごをたんけん');
  String get vietnameseAction => _t('Chơi cùng chữ', 'Play with letters', 'もじであそぼう');
  String get mathAction => _t('Khám phá con số', 'Explore numbers', 'かずをたんけん');
  String get thinkingAction => _t('Giải câu đố', 'Solve a puzzle', 'パズルをとこう');
  String get creativityAction => _t('Sáng tạo', 'Create', 'そうぞうしよう');
  String get gamesAction => _t('Chơi cùng Mai', 'Play with Mai', 'まいとあそぼう');
  String get discoverWithMai => _t('Chạm để khám phá cùng Mai', 'Tap to explore with Mai', 'まいとたんけんしよう');
  String get exampleLabel => _t('Ví dụ', 'Example', 'れい');
  String get letterSoundPrimary => _t('Âm', 'Sound', 'おと');
  String get letterNameSecondary => _t('Tên chữ', 'Letter name', 'なまえ');
  String get letterNameLabel => _t('Tên chữ', 'Letter name', 'なまえ');
  String get letterSoundLabel => _t('Âm chữ', 'Letter sound', 'おん');
  String get japanesePath => _t('Nhìn → Nghe → Thứ tự nét → Viết', 'Look → Listen → Stroke order → Write', 'みる → きく → かきじゅん → かく');
  String get listenName => _t('Nghe tên chữ', 'Hear the name', 'なまえをきく');
  String get listenSound => _t('Nghe âm chữ', 'Hear the sound', 'おとをきく');
  String get explore => _t('Khám phá', 'Explore', 'たんけん');
  String get rewardTitle => _t('Ngôi sao của con', "Today's stars", 'きょうのスター');
  String get parent => _t('Phụ huynh', 'Parent', '保護者');
  String get japanese => _t('Tiếng Nhật', 'Japanese', 'にほんご');
  String get vietnamese => _t('Tiếng Việt', 'Vietnamese', 'ベトナム語');
  String get math => _t('Toán', 'Math', 'さんすう');
  String get thinking => _t('Tư duy', 'Thinking', 'かんがえる');
  String get creativity => _t('Sáng tạo', 'Create', 'そうぞう');
  String get games => _t('Trò chơi', 'Games', 'ゲーム');
  String get progress => _t('Tiến bộ', 'Progress', 'しんぽ');
  String get japaneseSub => _t('Hiragana & Katakana', 'Hiragana & Katakana', 'ひらがな・カタカナ');
  String get vietnameseSub => _t('Chữ, vần, từ, câu', 'Letters, sounds, words', 'もじ・たんご');
  String get mathSub => _t('Đếm, cộng, trừ', 'Count, add, subtract', 'かぞえる・たす・ひく');
  String get thinkingSub => _t('Hình, quy luật, logic', 'Patterns and logic', 'もよう・ロジック');
  String get creativitySub => _t('Vẽ, tô, nối, ghép', 'Draw, color, match', 'え・ぬりえ');
  String get gamesSub => _t('Học mà chơi', 'Play to learn', 'あそびながら学ぶ');
  String get welcomeHi => _t('Chào mừng con!', 'Welcome!', 'ようこそ！');
  String get welcomeSub => _t('Cùng học vui mỗi ngày nhé', 'Let’s learn something fun', 'たのしくまなぼう');
  String get start => _t('Bắt đầu nào!', "Let's go!", 'スタート！');
  String get correct => _t('Giỏi lắm!', 'Well done!', 'すごい！');
  String get tryAgain => _t('Thử lại nhé', 'Try again', 'もういちど');
  String get completed => _t('Hoàn thành!', 'Finished!', 'できた！');
  String get keepGoing => _t('Tiếp tục!', 'Keep going!', 'つづけて！');
  String starsToday(int n) => _t('Hôm nay $n ngôi sao', '$n stars today', 'きょうスター $n');
  String learnedToday(int n) => _t('Hôm nay con đã học $n mục', 'Learned $n things today', 'きょう $n こ まなんだよ');
  String get noProgressYet => _t('Mới bắt đầu — chạm một môn để học nhé', 'Just starting — pick a world to explore', 'まずはひとつの世界をえらぼう');
  String get childProfile => _t('Hồ sơ bé', 'Child profile', 'こどものプロフィール');
  String get childName => _t('Tên của con', "Child's name", 'なまえ');
  String get save => _t('Lưu', 'Save', 'ほぞん');
  String get saved => _t('Đã lưu hồ sơ', 'Profile saved', 'ほぞんしたよ');
  String get sound => _t('Âm thanh', 'Sound', 'おと');
  String get voiceVolumeLabel => _t('Âm lượng giọng đọc', 'Voice volume', 'こえのおんりょう');
  String get bgmVolumeLabel => _t('Âm lượng nhạc nền', 'BGM volume', 'BGMのおんりょう');
  String get dailyMinutes => _t('Thời gian học mỗi ngày', 'Daily learning time', 'まいにちの学習時間');
  String minutes(int n) => _t('$n phút', '$n min', '$nふん');
  String get review => _t('Ôn tập', 'Review', 'ふくしゅう');
  String get noReview => _t('Chưa có mục cần ôn', 'Nothing to review yet', 'ふくしゅうはまだないよ');
  String get resetProgress => _t('Xóa tiến độ học', 'Reset progress', 'しんぽをリセット');
  String get switchChild => _t('Đổi hồ sơ bé', 'Switch child', 'こどもをきりかえ');
  String get support => _t('Hỗ trợ', 'Support', 'サポート');
  String get sendEmail => _t('Gửi email', 'Send email', 'メールを送る');
  String get appInfo => _t('Thông tin ứng dụng', 'App information', 'アプリ情報');
  String get developer => _t('Nhà phát triển', 'Developer', '開発元');
  String get licenses => _t('Giấy phép & nguồn tài nguyên', 'Licenses & sources', 'ライセンス');
  String get licensesBody => _t(
        'Âm thanh tiếng Việt: Piper voice vais1000 (CC BY 4.0). Âm thanh tiếng Nhật: giọng ja-JP tạo lúc build (ưu tiên Tsukuyomi-chan khi chạy được piper-plus). Audio generated by ViMai Kids build pipeline. Xem assets/licenses/AUDIO_LICENSES.md',
        'Vietnamese audio: Piper vais1000 (CC BY 4.0). Japanese audio baked at build time (Tsukuyomi-chan preferred). See assets/licenses/AUDIO_LICENSES.md',
        'ベトナム語音声: Piper vais1000 (CC BY 4.0)。日本語音声はビルド時に作成。assets/licenses/AUDIO_LICENSES.md を参照。',
      );
  String get weekly => _t('Tuần này', 'This week', 'こんしゅう');
  String get activities => _t('Hoạt động', 'Activities', 'かつどう');
  String get subjects => _t('Môn học', 'Subjects', 'がくしゅう');
  String get uiLanguage => _t('Ngôn ngữ giao diện', 'App language', 'アプリの言語');
  String get chooseChild => _t('Chọn bé', 'Choose a child', 'こどもをえらぶ');
  String get addChild => _t('Thêm bé mới', 'Add a child', 'あたらしいこども');
  String get whatName => _t('Con tên là gì?', "What's your name?", 'あなたのおなまえは？');
  String get howOld => _t('Con bao nhiêu tuổi?', 'How old are you?', 'なんさい？');
  String get pickLook => _t('Chọn màu bạn đồng hành', 'Pick a companion color', 'なかまのいろ');
  String get done => _t('Xong rồi!', 'All done!', 'できた！');
  String get enterName => _t('Con hãy nhập tên nhé', 'Please enter a name', 'なまえをいれてね');
  String get noProfile => _t('Chưa có hồ sơ bé', 'No child profile yet', 'プロフィールがありません');
  String get back => _t('Quay lại', 'Back', 'もどる');
  String get contact => _t('Liên hệ & góp ý', 'Contact & feedback', 'おといあわせ');
  String get supportBody => _t(
        'Gửi email nếu con gặp lỗi, cần giúp đỡ, hoặc ba mẹ muốn góp ý cho ViMai Kids.',
        'Email us if something is wrong, you need help, or you have feedback for ViMai Kids.',
        'こまりごとやご意見はメールでどうぞ。',
      );
  String get learningSection => _t('Học tập', 'Learning', 'がくしゅう');
  String get settingsSection => _t('Cài đặt', 'Settings', 'せってい');
  String get remembered => _t('Chữ đã nhớ', 'Remembered', 'おぼえたもじ');
  String get needsReviewFriendly => _t('Cần ôn lại', 'Needs review', 'ふくしゅう');
  String get mostPracticed => _t('Môn con học nhiều nhất', 'Most practiced', 'いちばんれんしゅうした');
  String get lookMode => _t('Nhìn', 'Look', 'みる');
  String get hearMode => _t('Nghe', 'Listen', 'きく');
  String get strokeMode => _t('Thứ tự nét', 'Stroke order', 'かきじゅん');
  String get writeMode => _t('Viết', 'Write', 'かく');
  String get pickMode => _t('Chọn chữ', 'Choose', 'えらぶ');
  String get whichLetter => _t('Chữ nào đúng?', 'Which letter is right?', 'どのもじ？');
  String get needsPractice => _t('Cần luyện thêm', 'Needs practice', 'れんしゅうがひつよう');
  String strokeCountLabel(int n) => _t('Chữ này có $n nét', 'This character has $n strokes', 'このもじは $n かく');
  String get strokeHint => _t('Viết từ trên xuống, từ trái sang phải. Làm lần lượt từng nét.', 'Write top to bottom, left to right. One stroke at a time.', 'うえからした、ひだりみぎ。ひとつずつ。');
  String get traceNow => _t('Chép theo mẫu', 'Trace the model', 'なぞろう');
  String get replayStrokes => _t('Xem lại nét', 'Watch again', 'もういちど');
  String get mailMissing => _t('Không mở được email', "Couldn't open email", 'メールを開けません');
  String get mailMissingBody => _t('Thiết bị chưa có ứng dụng email.', 'No email app is installed.', 'メールアプリがありません。');
  String get close => _t('Đóng', 'Close', 'とじる');
  String get version => _t('Phiên bản', 'Version', 'バージョン');
  String get statusFresh => _t('Cùng khám phá thế giới học tập nhé', "Let's explore your learning world", 'まなびの世界をたんけんしよう');
  String get statusReview => _t('Có bài cần ôn — mình làm nhẹ nhàng nhé', 'A little review will help today', 'やさしくふくしゅうしよう');
  String get statusContinue => _t('Mình đang học rất đều!', "You're doing great — keep going", 'よくがんばってるね');
  String scoreCorrect(int n) => _t('Đúng $n câu', '$n correct', '$nもんせいかい');
  String get chooseToday => _t('Con muốn học gì hôm nay?', 'What would you like to learn today?', 'きょうはなにをまなぶ？');
  String helloName(String name) => _t('Chào $name!', 'Hi $name!', '$nameちゃん、こんにちは！');
  String get confirmReset => _t('Xóa tiến độ học của bé?', 'Reset this child’s progress?', 'しんぽをリセットしますか？');
  String get confirm => _t('Xóa', 'Reset', 'リセット');
  String get cancel => _t('Không', 'Cancel', 'キャンセル');
  String get brushThin => _t('Mảnh', 'Thin', 'ほそい');
  String get brushMedium => _t('Vừa', 'Medium', 'ふつう');
  String get brushThick => _t('Đậm', 'Thick', 'ふとい');
  String get brushHeavy => _t('Rất đậm', 'Heavy', 'とてもふとい');
  String colorName(int index) {
    const vi = ['Đỏ san hô', 'Xanh trời', 'Xanh lá', 'Cam', 'Nâu', 'Tím', 'Vàng mật', 'Xanh ngọc'];
    const en = ['Coral', 'Sky', 'Mint', 'Peach', 'Ink', 'Grape', 'Honey', 'Teal'];
    const ja = ['コーラル', 'そら', 'みどり', 'もも', 'ちゃいろ', 'ぶどう', 'はちみつ', 'ブルーグリーン'];
    final i = index.clamp(0, 7);
    return _t(vi[i], en[i], ja[i]);
  }
  String get missionToday => _t('Nhiệm vụ hôm nay', "Today's mission", 'きょうのミッション');
  String get playNow => _t('Chơi ngay', 'Play now', 'あそぼう');
  String get goNow => _t('Đi thôi!', "Let's go!", 'いこう！');
  String letterIntro(String letter) => _t('Đây là chữ $letter!', 'This is $letter!', 'これは$letterだよ！');
  String findLetterForMai(String letter) => _t('Con tìm chữ $letter giúp Mai nhé!', 'Find $letter for Mai!', '$letterをさがして！');
  String get listenWithMai => _t('Nghe Mai nhé!', 'Listen to Mai!', 'まいの声をきいてね');
  String get adventureInvite =>
      _t('Mai có một chuyến phiêu lưu cho con hôm nay!', 'Mai has an adventure for you today!', 'きょうのぼうけんがあるよ！');
  String maiSceneMission(String name, String mission) =>
      _t('Chào $name! $mission', 'Hi $name! $mission', '$name、$mission');
  String get tapToExplore => _t('Chạm vào nơi con muốn khám phá!', 'Tap a place to explore!', 'タップしてたんけん！');
  String get worldPath => _t('Các thế giới của con', 'Your worlds', 'あなたの世界');
  String get listenNow => _t('Nghe nào!', 'Listen!', 'きいてね');
  String writeLetter(String letter) => _t('Viết chữ $letter', 'Write $letter', '$letterをかく');
  String get missionFreshBody => _t('Học 3 chữ cái cùng Mai', 'Learn 3 letters with Mai', 'まいと3もじまなぼう');
  String get missionFreshTime => _t('Khoảng 2 phút', 'About 2 minutes', 'やく2ふん');
  String get strokeMissing =>
      _t('Chưa có dữ liệu thứ tự nét', 'Stroke-order data is not available', '書き順データがありません');
  String get strokeSlow => _t('Chậm', 'Slow', 'ゆっくり');
  String get strokeNormal => _t('Nhanh', 'Faster', 'はやく');
  String get freeWriteHint =>
      _t('Tự viết sau khi xem mẫu. Chưa chấm điểm nét.', 'Write freely after the model. Strokes are not scored.', 'お手本のあとじぶんでかく。採点はしません。');
  String strokeProgress(int current, int total) => _t('Nét $current/$total', 'Stroke $current/$total', '$current / $total かく');
  String get watchThisStroke => _t('Hãy xem cách viết nét này.', 'Watch how to write this stroke.', 'このかくをみてね。');
  String get strokeComplete => _t('Hoàn thành', 'Finished', 'できた');
  String get strokePrev => _t('Trước', 'Previous', 'まえ');
  String get strokeNext => _t('Tiếp', 'Next', 'つぎ');
  String get strokePlay => _t('Phát', 'Play', 'さいせい');
  String get strokePause => _t('Tạm dừng', 'Pause', 'いちじていし');
  String get writeInstruction => _t('Con hãy viết theo mẫu', 'Write following the model', 'お手本をみてかいてね');
  String get practiceMode => _t('Chế độ luyện tập', 'Practice mode', 'れんしゅうモード');
  String get clearWriting => _t('Xóa', 'Clear', 'けす');
  String get retryWriting => _t('Viết lại', 'Try again', 'もういちどかく');
  String get showModel => _t('Xem mẫu', 'Show model', 'お手本');
  String get writingDetected => _t('Đã viết', 'Writing detected', 'かけたよ');
  String get listenHint => _t('Hãy nghe nhé!', 'Listen carefully!', 'きいてね');
  String get needHelp => _t('Cần trợ giúp?', 'Need help?', 'ヘルプ');
  String get feedbackTitle => _t('Góp ý', 'Feedback', 'ご意見');
  String get aboutVimai => _t('Về ViMai Kids', 'About ViMai Kids', 'ViMai Kidsについて');
  String get todayMinutes => _t('Hôm nay', 'Today', 'きょう');
  String get strengths => _t('Điểm mạnh', 'Strengths', '得意');
  String get practicing => _t('Đang luyện', 'Practicing', 'れんしゅうちゅう');
  String learnedTodayMinutes(int n) => _t('Khoảng $n phút hôm nay', 'About $n min today', 'きょうやく$nふん');
  String activitiesToday(int n) => _t('$n hoạt động hôm nay', '$n activities today', 'きょう$nこ');
  String doingGreat(String name) => _t('$name đang học rất tốt!', '$name is doing great!', '$name、よくがんばってるね！');
  String get enoughToday => _t('Hôm nay con đã học đủ giờ rồi — chơi nhẹ cũng được.', 'Daily time is done — a light game is fine.', 'きょうのじかんはおわり。あそんでもいいよ。');
  String get kanjivgCredit =>
      _t('Thứ tự nét: KanjiVG (CC BY-SA 3.0), Ulrich Apel.', 'Stroke order: KanjiVG (CC BY-SA 3.0), Ulrich Apel.', '書き順: KanjiVG (CC BY-SA 3.0)');

  String _t(String vi, String en, String ja) {
    switch (lang) {
      case UiLang.en:
        return en;
      case UiLang.ja:
        return ja;
      case UiLang.vi:
        return vi;
    }
  }
}
