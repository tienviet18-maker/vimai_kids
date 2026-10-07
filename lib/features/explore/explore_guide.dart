/// What Mai says in "Khám phá thế giới".
///
/// Every line is voiced by `assets/audio/vi_say_<hash>.mp3` (see SpeechId);
/// `tool/speech/export_speech_lines_test.dart` exports [all] together with
/// every category title, item name, fact and quiz question.
class ExploreGuide {
  ExploreGuide._();

  static const hub = 'Chào bé! Mình cùng đi khám phá thế giới nhé. Bé chọn một chủ đề nào!';
  static const category = 'Bé chạm vào từng hình để nghe Mai kể nhé!';
  static const swipe = 'Bé vuốt sang hoặc chạm mũi tên để xem hình tiếp theo nhé.';
  static const quizStart = 'Đố bé nào! Bé nghe Mai hỏi rồi chạm vào hình đúng nhé.';
  static const correct1 = 'Đúng rồi! Bé giỏi quá!';
  static const correct2 = 'Chính xác! Bé được một ngôi sao!';
  static const correct3 = 'Tuyệt vời! Bé đoán đúng rồi!';
  static const wrong1 = 'Chưa đúng rồi, bé thử lại nhé!';
  static const wrong2 = 'Bé nhìn kỹ lại nhé!';
  static const quizDone = 'Bé đã trả lời xong rồi! Mai tặng bé những ngôi sao lấp lánh!';
  static const quizPerfect = 'Bé đúng hết tất cả! Bé là nhà thám hiểm siêu giỏi!';
  static const playAgain = 'Mình chơi lại nhé!';

  static const correct = [correct1, correct2, correct3];
  static const wrong = [wrong1, wrong2];

  static const all = [
    hub,
    category,
    swipe,
    quizStart,
    correct1,
    correct2,
    correct3,
    wrong1,
    wrong2,
    quizDone,
    quizPerfect,
    playAgain,
  ];
}
