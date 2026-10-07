/// What Mai says to guide a child through each screen.
///
/// Every line is voiced by `assets/audio/vi_say_<hash>.mp3` (see [SpeechId]);
/// `tool/speech/export_speech_lines_test.dart` exports [all] so the generator
/// produces a clip for each. Keep lines short, warm and action-first: a
/// 3-year-old should know what to tap after hearing one line.
class KidGuide {
  KidGuide._();

  // Onboarding & home
  static const profileSelect = 'Bé là ai nhỉ? Chạm vào ảnh của bé nhé!';
  static const home = 'Chào bé! Hôm nay mình khám phá đảo nào? Chạm vào một hòn đảo nhé!';
  static const homeContinue = 'Chạm vào nút to để học tiếp bài hôm trước nhé!';
  static const progress = 'Đây là khu vườn sao của bé. Mỗi bài học xong, vườn lại nở thêm hoa!';

  // Subject hubs
  static const vietnameseHub = 'Đảo Tiếng Việt đây rồi! Bé chọn một bài để học chữ và đọc từ nhé.';
  static const japaneseHub = 'Đảo Tiếng Nhật đây rồi! Bé chọn chữ Hiragana hoặc Katakana nhé.';
  static const mathHub = 'Đảo Toán học đây rồi! Mình cùng đếm và tính nhé. Bé chọn một bài nào!';
  static const thinkingHub = 'Đảo Tư duy đây rồi! Mình cùng giải câu đố nhé.';
  static const gamesHub = 'Khu vui chơi đây rồi! Bé chọn một trò chơi nhé.';
  static const creativityHub = 'Xưởng sáng tạo đây rồi! Bé muốn vẽ, tô màu hay chơi nhạc?';

  // Shared quiz guidance
  static const quizHowTo = 'Bé nghe câu hỏi, rồi chạm vào đáp án đúng nhé!';
  static const tapSpeaker = 'Chạm vào cái loa để nghe lại nhé.';
  static const nextQuestion = 'Câu tiếp theo nào!';
  static const sessionDone = 'Bé đã hoàn thành bài học! Mai rất tự hào về bé.';
  static const almost = 'Gần đúng rồi! Bé thử lại nhé.';
  static const hint = 'Bé nhìn kỹ hình nhé, đáp án ở ngay đây thôi.';

  // Vietnamese letters & reading
  static const letterSee = 'Bé nhìn chữ này nhé.';
  static const letterHear = 'Bé nghe Mai đọc âm của chữ nào.';
  static const letterTrace = 'Bé dùng ngón tay tô theo nét chữ nhé.';
  static const letterFind = 'Bé tìm đúng chữ vừa học nhé!';
  static const letterSay = 'Bé đọc to theo Mai nào!';
  static const blendHowTo = 'Bé nghe từng âm, rồi ghép lại thành tiếng nhé.';
  static const wordHowTo = 'Bé nhìn hình, nghe Mai đọc, rồi chọn chữ đúng nhé.';
  static const sentenceHowTo = 'Bé nghe Mai đọc cả câu, rồi đọc theo nhé.';
  static const rimeHowTo = 'Bé nghe vần, rồi chọn tiếng có vần đó nhé.';
  static const listenPickLetter = 'Nghe rồi chọn chữ đúng nhé.';
  static const hearLetterName = 'Nghe tên chữ, rồi chọn chữ đúng nhé.';
  static const hearLetterSound = 'Nghe âm của chữ, rồi chọn chữ đúng nhé.';
  static const letterWhichSound = 'Chữ này đọc âm nào?';
  static const letterInWord = 'Chữ này có trong từ nào?';
  static const findLetter = 'Bé nghe rồi tìm đúng chữ nhé!';

  // Japanese kana lesson (SEE → HEAR → WATCH → TRACE → WRITE → REPEAT → REWARD)
  static const kanaSee = 'Bé nhìn chữ tiếng Nhật này nhé.';
  static const kanaHear = 'Bé nghe cách đọc nào.';
  static const kanaWatch = 'Bé xem Mai viết từng nét theo thứ tự nhé.';
  static const kanaTrace = 'Bé tô theo nét chấm, nét số một trước nhé.';
  static const kanaWrite = 'Giờ bé tự viết chữ nhé!';
  static const kanaRepeat = 'Bé đọc lại theo Mai nào!';
  static const kanaReward = 'Tuyệt vời! Bé đã học xong chữ này và được một ngôi sao!';

  // Games
  static const gameCatchKana = 'Nghe Mai đọc, rồi chạm bắt chữ đúng đang rơi xuống nhé!';
  static const gameListenKana = 'Bé nghe thật kỹ, rồi chạm vào chữ Mai vừa đọc nhé.';
  static const gameMatchKana = 'Bé lật thẻ và tìm hai thẻ giống nhau nhé.';
  static const gameFeedAnimal = 'Bạn gấu trúc đói bụng rồi! Bé chọn đúng đáp án để cho bạn ăn nhé.';
  static const gameFindSimilar = 'Bé tìm hình giống với hình mẫu nhé.';
  static const gameMathRocket = 'Tính đúng để phóng tên lửa lên vũ trụ nào!';
  static const gameNumberTrain = 'Bé xếp số còn thiếu vào toa tàu nhé!';
  static const gameWin = 'Bé thắng rồi! Giỏi quá!';

  // Creativity
  static const drawHowTo = 'Bé chọn một màu, rồi dùng ngón tay vẽ lên giấy nhé.';
  static const colorHowTo = 'Bé chọn màu, rồi chạm vào từng phần để tô nhé.';
  static const musicHowTo = 'Bé chạm vào các phím để tạo ra bản nhạc của mình nhé!';
  static const puzzleHowTo = 'Bé suy nghĩ, rồi chọn hình đúng nhé.';
  static const saved = 'Mai đã cất bức tranh của bé rồi!';

  static const all = [
    profileSelect, home, homeContinue, progress,
    vietnameseHub, japaneseHub, mathHub, thinkingHub, gamesHub, creativityHub,
    quizHowTo, tapSpeaker, nextQuestion, sessionDone, almost, hint,
    letterSee, letterHear, letterTrace, letterFind, letterSay, blendHowTo, wordHowTo, sentenceHowTo,
    rimeHowTo, listenPickLetter, hearLetterName, hearLetterSound, letterWhichSound, letterInWord, findLetter,
    kanaSee, kanaHear, kanaWatch, kanaTrace, kanaWrite, kanaRepeat, kanaReward,
    gameCatchKana, gameListenKana, gameMatchKana, gameFeedAnimal, gameFindSimilar, gameMathRocket,
    gameNumberTrain, gameWin,
    drawHowTo, colorHowTo, musicHowTo, puzzleHowTo, saved,
  ];
}
