/// Pedagogical context sent to Mai AI to orchestrate contextual assistance.
///
/// Strictly captures educational metadata only. Raw database states, private
/// identifiers, and sensitive user data must never be passed to the model.
class MaiContext {
  final String currentModule;
  final String currentLesson;
  final String currentActivity;
  final String currentQuestion;
  final int attemptNumber;
  final String targetLanguage;
  final String learningObjective;
  final int hintLevel;
  final int childAge;
  final String? phoneticRule;
  final List<String>? choices;
  final String? expectedAnswer;

  const MaiContext({
    required this.currentModule,
    required this.currentLesson,
    required this.currentActivity,
    required this.currentQuestion,
    this.attemptNumber = 1,
    this.targetLanguage = 'vi',
    required this.learningObjective,
    this.hintLevel = 0,
    this.childAge = 5,
    this.phoneticRule,
    this.choices,
    this.expectedAnswer,
  });

  /// Minimalist payload for Gemini API.
  /// Omits raw database records, PII, and internal IDs.
  Map<String, dynamic> toMinimalistPayload() {
    return {
      'currentModule': currentModule,
      'currentLesson': currentLesson,
      'currentActivity': currentActivity,
      'currentQuestion': currentQuestion,
      'attemptNumber': attemptNumber,
      'targetLanguage': targetLanguage,
      'learningObjective': learningObjective,
      'hintLevel': hintLevel.clamp(0, 4),
      'childAge': childAge,
      if (phoneticRule != null && phoneticRule!.isNotEmpty) 'phoneticRule': phoneticRule,
      if (choices != null && choices!.isNotEmpty) 'choices': choices,
    };
  }

  MaiContext copyWith({
    String? currentModule,
    String? currentLesson,
    String? currentActivity,
    String? currentQuestion,
    int? attemptNumber,
    String? targetLanguage,
    String? learningObjective,
    int? hintLevel,
    int? childAge,
    String? phoneticRule,
    List<String>? choices,
    String? expectedAnswer,
  }) {
    return MaiContext(
      currentModule: currentModule ?? this.currentModule,
      currentLesson: currentLesson ?? this.currentLesson,
      currentActivity: currentActivity ?? this.currentActivity,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      learningObjective: learningObjective ?? this.learningObjective,
      hintLevel: hintLevel ?? this.hintLevel,
      childAge: childAge ?? this.childAge,
      phoneticRule: phoneticRule ?? this.phoneticRule,
      choices: choices ?? this.choices,
      expectedAnswer: expectedAnswer ?? this.expectedAnswer,
    );
  }

  @override
  String toString() {
    return 'MaiContext(module: $currentModule, lesson: $currentLesson, activity: $currentActivity, q: $currentQuestion, attempt: $attemptNumber, hintLevel: $hintLevel)';
  }
}
