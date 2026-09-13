/// Replaceable illustration catalog. Real PNG assets, not geometric stand-ins.
class VimaiArt {
  static const homeWorld = 'assets/illustrations/home_world_bg.png';
  static const japaneseVillage = 'assets/illustrations/world_japanese.png';
  static const vietnameseGarden = 'assets/illustrations/world_vietnamese.png';
  static const mathValley = 'assets/illustrations/world_math.png';
  static const thinkingCave = 'assets/illustrations/world_thinking.png';
  static const creativeStudio = 'assets/illustrations/world_creativity.png';
  static const gamesPlayground = 'assets/illustrations/world_games.png';
  static const fish = 'assets/illustrations/object_fish.png';
  static const japanLesson = 'assets/illustrations/lesson_japan.png';
  static const gardenLesson = 'assets/illustrations/home_world_bg.png';

  static String? objectForWord(String word) {
    switch (word.trim().toLowerCase()) {
      case 'cá':
        return fish;
      default:
        return null;
    }
  }
}

enum WorldVisit { available, inProgress, completed, mastered }

WorldVisit worldVisitFromProgress(double progress) {
  if (progress >= 0.85) return WorldVisit.mastered;
  if (progress >= 0.4) return WorldVisit.completed;
  if (progress > 0) return WorldVisit.inProgress;
  return WorldVisit.available;
}
