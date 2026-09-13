import '../audio/vietnamese_speech_catalog.dart';
import 'mai_action.dart';
import 'mai_context.dart';
import 'mai_response.dart';

/// Instant offline fallback engine providing safe, pedagogical responses
/// without requiring internet connectivity or external API access.
class MaiOfflineFallback {
  const MaiOfflineFallback();

  /// Generates a local, pedagogically sound response based on context and hint level.
  MaiResponse generate(MaiContext context, {MaiAction? requestedAction}) {
    final action = requestedAction ?? (context.hintLevel > 0 ? MaiAction.hint : MaiAction.speak);

    switch (action) {
      case MaiAction.celebrate:
        return _celebrate(context);
      case MaiAction.encourage:
        return _encourage(context);
      case MaiAction.hint:
      case MaiAction.demonstrate:
        return _hint(context);
      case MaiAction.ask:
      case MaiAction.speak:
        return _greeting(context);
    }
  }

  MaiResponse _celebrate(MaiContext context) {
    final phrases = [
      'Tuyệt cú mèo! Bé làm đúng rồi đấy!',
      'Hoan hô bé! Bé thông minh quá đi!',
      'Xuất sắc luôn! Mai rất tự hào về bé!',
      'Bé giỏi thật đấy! Cùng khám phá tiếp nào!',
    ];
    final text = phrases[(context.attemptNumber - 1).abs() % phrases.length];
    return MaiResponse.fallback(
      action: MaiAction.celebrate,
      text: text,
      hintLevel: context.hintLevel,
    );
  }

  MaiResponse _encourage(MaiContext context) {
    final phrases = [
      'Gần đúng rồi, bé thử lại lần nữa xem nào!',
      'Không sao đâu bé ơi, cùng Mai làm lại nhé!',
      'Bé nhìn kỹ lại một chút là làm được ngay thôi!',
      'Cố lên nào bé yêu, Mai luôn ở bên cạnh bé!',
    ];
    final text = phrases[(context.attemptNumber - 1).abs() % phrases.length];
    return MaiResponse.fallback(
      action: MaiAction.encourage,
      text: text,
      hintLevel: context.hintLevel,
    );
  }

  MaiResponse _greeting(MaiContext context) {
    final module = context.currentModule.toLowerCase();
    String text;
    if (module.contains('vietnamese')) {
      text = 'Chào bé! Cùng Mai khám phá tiếng Việt diệu kỳ nhé!';
    } else if (module.contains('japanese')) {
      text = 'Konnichiwa! Cùng Mai học chữ tiếng Nhật thật vui nhé!';
    } else if (module.contains('math')) {
      text = 'Chào bạn nhỏ! Cùng Mai làm quen với những con số đáng yêu nào!';
    } else if (module.contains('thinking')) {
      text = 'Hôm nay chúng mình cùng giải những câu đố thông minh nhé!';
    } else {
      text = 'Chào bé yêu! Mai đã sẵn sàng học cùng bé rồi đây!';
    }

    return MaiResponse.fallback(
      action: MaiAction.speak,
      text: text,
      hintLevel: context.hintLevel,
    );
  }

  /// Implements the Progressive Hint Model (Levels 0 through 4)
  MaiResponse _hint(MaiContext context) {
    final module = context.currentModule.toLowerCase();
    final level = context.hintLevel.clamp(0, 4);

    if (module.contains('math')) {
      return _mathHint(context, level);
    } else if (module.contains('thinking')) {
      return _thinkingHint(context, level);
    } else if (module.contains('vietnamese')) {
      return _vietnameseHint(context, level);
    } else if (module.contains('japanese')) {
      return _japaneseHint(context, level);
    }

    return _genericHint(context, level);
  }

  MaiResponse _mathHint(MaiContext context, int level) {
    final q = context.currentQuestion;
    final isAddition = q.contains('+') || context.currentLesson.contains('addition');
    final isSubtraction = q.contains('−') || q.contains('-') || context.currentLesson.contains('subtraction');
    final isCounting = context.currentLesson.contains('count') || q.contains('Đếm');
    final answer = context.expectedAnswer;

    String text;
    MaiAction action = MaiAction.hint;

    switch (level) {
      case 0:
        // Nudge / Attention
        text = 'Bé hãy nhìn kỹ lại các con số và dấu phép tính nhé!';
        break;
      case 1:
        // Concept Cue / Guiding Question
        if (isAddition) {
          text = 'Dấu cộng (+) nghĩa là mình cùng gộp thêm vào đấy bé!';
        } else if (isSubtraction) {
          text = 'Dấu trừ (−) nghĩa là mình bớt đi một số lượng nhé!';
        } else if (isCounting) {
          text = 'Bé hãy dùng ngón tay chỉ vào từng hình rồi đếm lần lượt từ trái sang phải nào!';
        } else {
          text = 'Bé thử so sánh xem số nào nhiều hơn hoặc lớn hơn nhé!';
        }
        break;
      case 2:
        // Elimination / Strategy
        if (isAddition) {
          text = 'Khi cộng thêm, kết quả chắc chắn sẽ lớn hơn số ban đầu đấy!';
        } else if (isSubtraction) {
          text = 'Khi bớt đi, kết quả chắc chắn sẽ nhỏ hơn số ban đầu bé nhé!';
        } else {
          text = 'Bé hãy loại trừ các con số quá lớn hoặc quá nhỏ xem sao!';
        }
        break;
      case 3:
        // Step-by-Step Walkthrough
        if (isAddition) {
          text = 'Bé giữ số đầu tiên trong đầu, rồi đếm thêm số tiếp theo bằng ngón tay nhé!';
        } else if (isSubtraction) {
          text = 'Bé có số ban đầu, giờ đếm lùi từng bước để tìm kết quả nào!';
        } else {
          text = 'Cùng đếm từng nhóm một với Mai nhé: 1, 2, 3... rồi tiếp theo là số nào?';
        }
        break;
      case 4:
      default:
        // Direct Demonstration / Model Solution
        action = MaiAction.demonstrate;
        if (answer != null && answer.isNotEmpty) {
          text = 'Mai cùng bé giải nhé: đáp án đúng là $answer! Bé chọn số $answer nào!';
        } else {
          text = 'Mai mách nhỏ cho bé nhé: kết quả đã ở rất gần rồi, bé bấm chọn đáp án đúng nào!';
        }
        break;
    }

    return MaiResponse.fallback(
      action: action,
      text: text,
      hintLevel: level,
      suggestedChoice: level == 4 ? answer : null,
    );
  }

  MaiResponse _thinkingHint(MaiContext context, int level) {
    final answer = context.expectedAnswer;
    String text;
    MaiAction action = MaiAction.hint;

    switch (level) {
      case 0:
        // Nudge
        text = 'Bé hãy quan sát thật kỹ các hình vẽ xem có điều gì thú vị nhé!';
        break;
      case 1:
        // Concept Cue
        text = 'Bé để ý xem quy luật ở đây là thay đổi màu sắc, hình dạng hay vị trí nhỉ?';
        break;
      case 2:
        // Elimination / Strategy
        text = 'Các hình đang lặp lại theo nhịp điệu đấy! Bé hãy loại trừ những hình không theo quy luật nhé!';
        break;
      case 3:
        // Step-by-Step Walkthrough
        text = 'Bé hãy đọc to tên từng hình từ trái qua phải xem hình nào sẽ xuất hiện tiếp theo!';
        break;
      case 4:
      default:
        // Demonstration
        action = MaiAction.demonstrate;
        if (answer != null && answer.isNotEmpty) {
          text = 'Quy luật dẫn đến hình $answer đấy! Bé chọn $answer giúp Mai nhé!';
        } else {
          text = 'Mai tìm thấy quy luật rồi! Bé bấm chọn hình tiếp theo nào!';
        }
        break;
    }

    return MaiResponse.fallback(
      action: action,
      text: text,
      hintLevel: level,
      suggestedChoice: level == 4 ? answer : null,
    );
  }

  MaiResponse _vietnameseHint(MaiContext context, int level) {
    // Preserves Vietnamese phonics rules strictly from VietnameseSpeechCatalog
    final lesson = context.currentLesson.toUpperCase();
    for (final entry in VietnameseSpeechCatalog.letters.entries) {
      final glyph = entry.key;
      final speech = entry.value;

      if (lesson.contains(glyph) || context.currentQuestion.toUpperCase().contains(glyph)) {
        if (level >= 3) {
          return MaiResponse.fallback(
            action: MaiAction.demonstrate,
            text: 'Chữ cái này là chữ "$glyph", phát âm là "${speech.phonicsSpoken}" bé nhé!',
            hintLevel: level,
            suggestedChoice: glyph,
          );
        } else if (level == 2) {
          return MaiResponse.fallback(
            action: MaiAction.hint,
            text: 'Chữ này phát âm là "${speech.phonicsSpoken}". Bé nhìn xem nét chữ giống chữ nào?',
            hintLevel: level,
          );
        } else {
          return MaiResponse.fallback(
            action: MaiAction.hint,
            text: 'Bé lắng nghe thật kỹ âm "${speech.phonicsSpoken}" để tìm chữ cái nhé!',
            hintLevel: level,
          );
        }
      }
    }

    // Generic Vietnamese hint
    if (level >= 3) {
      return MaiResponse.fallback(
        action: MaiAction.demonstrate,
        text: 'Bé ghép từng âm lại với nhau để đọc nhé!',
        hintLevel: level,
      );
    }
    return MaiResponse.fallback(
      action: MaiAction.hint,
      text: 'Bé nghe kỹ âm thanh và quan sát các chữ cái trên màn hình nào!',
      hintLevel: level,
    );
  }

  MaiResponse _japaneseHint(MaiContext context, int level) {
    if (level >= 3) {
      return MaiResponse.fallback(
        action: MaiAction.demonstrate,
        text: 'Bé nhớ lại từng nét bút viết từ trên xuống dưới, từ trái sang phải nhé!',
        hintLevel: level,
      );
    }
    return MaiResponse.fallback(
      action: MaiAction.hint,
      text: 'Bé lắng nghe âm đọc thật kỹ để chọn ký tự kana đúng nhé!',
      hintLevel: level,
    );
  }

  MaiResponse _genericHint(MaiContext context, int level) {
    if (level >= 3) {
      return MaiResponse.fallback(
        action: MaiAction.demonstrate,
        text: 'Mai ở ngay đây giúp bé này, bé chọn ô màu sắc rực rỡ nhất nhé!',
        hintLevel: level,
      );
    }
    return MaiResponse.fallback(
      action: MaiAction.hint,
      text: 'Bé nhìn kỹ câu hỏi một lần nữa nhé, câu trả lời ở ngay trước mắt thôi!',
      hintLevel: level,
    );
  }
}
