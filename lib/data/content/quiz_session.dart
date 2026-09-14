import '../../domain/content/content_item.dart';

/// Shared quiz/session loop state for mini-games and skill drills.
class QuizSession {
  QuizSession({
    required this.totalQuestions,
    required ContentItem Function() generate,
  })  : _generate = generate,
        item = generate();

  final int totalQuestions;
  final ContentItem Function() _generate;

  ContentItem item;
  int currentIndex = 0;
  int score = 0;
  int wrong = 0;
  bool finished = false;
  bool busy = false;
  String? lastChoice;
  bool? lastCorrect;
  String? feedback;

  void generateNewQuestion() {
    item = _generate();
    lastChoice = null;
    lastCorrect = null;
    feedback = null;
    busy = false;
  }

  /// Returns true when the session should show the celebration screen.
  bool registerAnswer({required bool correct, String? choice}) {
    lastChoice = choice;
    lastCorrect = correct;
    feedback = correct ? 'Giỏi lắm!' : 'Thử lại nhé';
    if (!correct) {
      wrong++;
      return false;
    }
    score++;
    currentIndex++;
    if (currentIndex >= totalQuestions || score >= totalQuestions) {
      finished = true;
      return true;
    }
    generateNewQuestion();
    return false;
  }

  void restart() {
    currentIndex = 0;
    score = 0;
    wrong = 0;
    finished = false;
    busy = false;
    generateNewQuestion();
  }
}
