/// Structured actions supported by the Mai AI Companion architecture.
enum MaiAction {
  speak,
  encourage,
  hint,
  celebrate,
  ask,
  demonstrate;

  static MaiAction fromString(String? raw) {
    if (raw == null) return MaiAction.speak;
    switch (raw.trim().toUpperCase()) {
      case 'SPEAK':
        return MaiAction.speak;
      case 'ENCOURAGE':
        return MaiAction.encourage;
      case 'HINT':
        return MaiAction.hint;
      case 'CELEBRATE':
        return MaiAction.celebrate;
      case 'ASK':
        return MaiAction.ask;
      case 'DEMONSTRATE':
        return MaiAction.demonstrate;
      default:
        return MaiAction.speak;
    }
  }

  String toUppercaseString() => name.toUpperCase();
}
