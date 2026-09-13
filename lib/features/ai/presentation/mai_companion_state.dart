import '../../shared/widgets/vimai_mascot.dart';

/// Reactive UI states for Mai AI Companion.
enum MaiState {
  idle,
  listening,
  thinking,
  speaking,
  hinting,
  celebrating,
  encouraging;

  MascotMood get mascotMood {
    switch (this) {
      case MaiState.idle:
      case MaiState.listening:
        return MascotMood.happy;
      case MaiState.thinking:
      case MaiState.hinting:
        return MascotMood.thinking;
      case MaiState.speaking:
        return MascotMood.excited;
      case MaiState.celebrating:
        return MascotMood.celebrating;
      case MaiState.encouraging:
        return MascotMood.encouraging;
    }
  }

  String get labelVi {
    switch (this) {
      case MaiState.idle:
        return 'Mai đồng hành';
      case MaiState.listening:
        return 'Mai đang lắng nghe...';
      case MaiState.thinking:
        return 'Mai đang suy nghĩ...';
      case MaiState.speaking:
        return 'Mai đang nói';
      case MaiState.hinting:
        return 'Gợi ý từ Mai';
      case MaiState.celebrating:
        return 'Hoan hô!';
      case MaiState.encouraging:
        return 'Cố lên bé nhé!';
    }
  }
}
