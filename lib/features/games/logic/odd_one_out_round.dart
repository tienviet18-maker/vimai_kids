import 'dart:math';

import '../../../core/audio/kid_guide.dart';
import '../../explore/data/explore_catalog.dart';

/// "Cái nào khác nhóm?": all pictures but one come from the same explore
/// topic. Mai asks the topic's question ([KidGuide.oddOneOutQuestions]) and,
/// when the child finds the odd one, explains why ([oddOneOutExplanation]).
///
/// Pairs of topics are chosen so the answer is never debatable for a small
/// child: a pet parrot, a toy car, a sea turtle in "wild animals" and the like
/// are kept out (see [_excluded], [_majorityOnlyOut] and [_closePairs]).
class OddOneOutRound {
  const OddOneOutRound({
    required this.majority,
    required this.oddCategory,
    required this.odd,
    required this.cards,
    this.majorityKind,
  });

  /// The topic most cards belong to; its question is asked.
  final ExploreCategory majority;
  final ExploreCategory oddCategory;
  final ExploreItem odd;

  /// Every card in play order (the [odd] one included).
  final List<ExploreItem> cards;

  /// For "bugs_birds": whether the matching pictures are all [birdKind]s
  /// or all [bugKind]s. Null for every other topic.
  final String? majorityKind;

  static const birdKind = 'birds';
  static const bugKind = 'bugs';

  String get question => majorityKind == bugKind ? KidGuide.oddOutBugs : KidGuide.oddOneOutQuestions[majority.id]!;

  /// Picture for the question banner and the matching cards' badges: a bird
  /// for a birds-only round (the topic's own emoji is a butterfly).
  String get majorityEmoji => majorityKind == birdKind ? '🐦' : majority.emoji;

  /// Badge on the answer card once found.
  String get oddEmoji => oddCategory.id == 'bugs_birds' && _birds.contains(odd.id) ? '🐦' : oddCategory.emoji;

  /// Every question a round can ask.
  static List<String> get allQuestions => [...KidGuide.oddOneOutQuestions.values, KidGuide.oddOutBugs];
  String get explanation => oddOneOutExplanation(odd, oddCategory.id);
  bool isOdd(ExploreItem item) => item.id == odd.id;

  /// Highest difficulty level.
  static const maxLevel = 2;

  /// Pictures on the table: 3 at the easiest level, 4 after that.
  static int cardCount(int level) => level <= 0 ? 3 : 4;

  /// Starting level from the child's age: little ones begin with three
  /// very different pictures.
  static int startLevel(int age) => age <= 5 ? 0 : 1;

  /// Level 0–1 mix far-apart topics (animals vs vehicles); level 2 uses close
  /// ones (pets vs wild animals, fruit vs vegetables).
  static bool usesClosePairs(int level) => level >= maxLevel;

  /// All (majority, odd) topic pairs playable at [level] in [catalog].
  static List<(ExploreCategory, ExploreCategory)> pairsFor(ExploreCatalog catalog, int level) {
    final usable = [
      for (final c in catalog.categories)
        if (KidGuide.oddOneOutQuestions.containsKey(c.id) && _group.containsKey(c.id)) c,
    ];
    final close = usesClosePairs(level);
    return [
      for (final a in usable)
        for (final b in usable)
          if (a.id != b.id && (close ? _closePairs.contains((a.id, b.id)) : _farAllowed(a.id, b.id))) (a, b),
    ];
  }

  /// Builds one round. [avoidMajority] keeps the same question from coming
  /// twice in a row.
  static OddOneOutRound generate(ExploreCatalog catalog, {required int level, Random? random, String? avoidMajority}) {
    final rnd = random ?? Random();
    final count = cardCount(level);
    var pairs = pairsFor(catalog, level.clamp(0, maxLevel));
    final fresh = pairs.where((p) => p.$1.id != avoidMajority).toList();
    if (fresh.isNotEmpty) pairs = fresh;
    pairs.shuffle(rnd);
    for (final (majority, oddCat) in pairs) {
      var majorityPool = [
        for (final item in majority.items)
          if (canBeMajority(majority.id, item) && _pairAllowsMajority(majority.id, oddCat.id, item)) item,
      ]..shuffle(rnd);
      String? kind;
      if (majority.id == 'bugs_birds') {
        // Only birds or only insects, so Mai can ask one simple question.
        kind = rnd.nextBool() ? birdKind : bugKind;
        majorityPool = [
          for (final item in majorityPool)
            if (_birds.contains(item.id) == (kind == birdKind)) item,
        ];
      }
      final oddPool = [
        for (final item in oddCat.items)
          if (canBeOdd(oddCat.id, item) && _pairAllowsOdd(majority.id, oddCat.id, item)) item,
      ]..shuffle(rnd);
      if (majorityPool.length < count - 1 || oddPool.isEmpty) continue;
      final odd = oddPool.first;
      final cards = [...majorityPool.take(count - 1), odd]..shuffle(rnd);
      return OddOneOutRound(majority: majority, oddCategory: oddCat, odd: odd, cards: cards, majorityKind: kind);
    }
    throw StateError('No odd-one-out round possible for level $level');
  }

  /// Whether [item] may be the odd picture (and so has an explanation line).
  static bool canBeOdd(String categoryId, ExploreItem item) =>
      _group.containsKey(categoryId) && !_excluded.contains('$categoryId/${item.id}');

  /// Whether [item] may stand among the pictures that share the question's topic.
  static bool canBeMajority(String categoryId, ExploreItem item) =>
      canBeOdd(categoryId, item) && !_majorityOnlyOut.contains('$categoryId/${item.id}');

  static bool _farAllowed(String majority, String odd) {
    final gm = _group[majority]!;
    final go = _group[odd]!;
    if (gm == go) return false;
    // "Cái nào không có sẵn trong thiên nhiên?" only makes sense against made things.
    if (majority == 'nature' && go != _G.things) return false;
    // Animals and food come from nature too: never make the sun the odd one there.
    if (odd == 'nature' && gm != _G.things && gm != _G.people) return false;
    return true;
  }

  static bool _pairAllowsOdd(String majority, String oddCat, ExploreItem item) {
    // "Quả cà chua" looks like a fruit to a child: keep "quả …" vegetables out of fruit rounds.
    if (majority == 'fruits' && oddCat == 'veggies' && item.name.startsWith('quả')) return false;
    // Fish and turtles are kept at home too: never the "not a pet" answer.
    if (majority == 'pets' && oddCat == 'sea' && _petLikeSea.contains(item.id)) return false;
    return true;
  }

  static bool _pairAllowsMajority(String majority, String oddCat, ExploreItem item) {
    // "Cái nào không phải là rau củ?" with an apple as the answer: a tomato or
    // cucumber beside it would look like a second fruit, so only clear
    // vegetables stay on the table.
    if (majority == 'veggies' && oddCat == 'fruits' && item.name.startsWith('quả')) return false;
    return true;
  }
}

/// "Con sư tử là động vật hoang dã, không giống các bạn kia." — what Mai says
/// when the child finds [item] (from topic [categoryId]). Shared with the
/// speech exporter so every line gets a clip.
String oddOneOutExplanation(ExploreItem item, String categoryId) {
  final name = item.name.isEmpty ? item.name : item.name[0].toUpperCase() + item.name.substring(1);
  return '$name ${_why(categoryId, item)}, không giống các bạn kia.';
}

String _why(String categoryId, ExploreItem item) {
  switch (categoryId) {
    case 'pets':
      return 'là con vật nuôi';
    case 'wild':
      return 'là động vật hoang dã';
    case 'sea':
      return 'sống dưới biển';
    case 'bugs_birds':
      return _birds.contains(item.id) ? 'là một loài chim' : 'là côn trùng';
    case 'fruits':
      return 'là hoa quả';
    case 'veggies':
      return 'là rau củ';
    case 'vehicles':
      return 'là phương tiện giao thông';
    case 'home':
      return 'là đồ dùng trong nhà';
    case 'body':
      return 'là một bộ phận cơ thể';
    case 'nature':
      return 'có sẵn trong thiên nhiên';
    case 'jobs':
      return 'là người làm nghề';
    case 'play':
      return _instruments.contains(item.id) ? 'là nhạc cụ' : 'là đồ chơi';
  }
  return 'khác nhóm';
}

enum _G { animals, food, things, people, nature }

const _group = {
  'pets': _G.animals,
  'wild': _G.animals,
  'sea': _G.animals,
  'bugs_birds': _G.animals,
  'fruits': _G.food,
  'veggies': _G.food,
  'vehicles': _G.things,
  'home': _G.things,
  'play': _G.things,
  'body': _G.people,
  'jobs': _G.people,
  'nature': _G.nature,
};

/// Close (majority, odd) pairs for the hardest level. Directional on purpose:
/// "Con nào không phải là động vật hoang dã?" cannot have a crab as answer
/// (crabs are wild too), but "Con nào không sống dưới biển?" can have a lion.
const _closePairs = {
  ('pets', 'wild'),
  ('wild', 'pets'),
  ('pets', 'sea'),
  ('sea', 'pets'),
  ('sea', 'bugs_birds'),
  ('bugs_birds', 'sea'),
  ('bugs_birds', 'wild'),
  ('fruits', 'veggies'),
  ('veggies', 'fruits'),
  ('vehicles', 'play'),
  ('vehicles', 'home'),
  ('home', 'vehicles'),
  ('play', 'home'),
  ('body', 'jobs'),
  ('jobs', 'body'),
};

/// Pictures that would make a question debatable, never used.
const _excluded = {
  'pets/fish_pet', // a fish among sea animals
  'bugs_birds/penguin', // swims in the sea
  'bugs_birds/snail', // neither insect nor bird
  'sea/shell', // not an animal
  'home/teddy', // a toy
  'veggies/peanut', // a nut
};

/// Instruments are fine as the odd one ("là nhạc cụ") but not as "đồ chơi".
const _majorityOnlyOut = {
  'play/drum',
  'play/guitar',
  'play/piano',
  'play/trumpet',
  'play/violin',
  'play/bell',
};

/// Sea animals a child may well have at home (goldfish bowl, pet turtle).
const _petLikeSea = {'fish', 'turtle'};

const _instruments = {'drum', 'guitar', 'piano', 'trumpet', 'violin', 'bell'};

const _birds = {'bird', 'parrot', 'owl', 'eagle', 'penguin', 'peacock', 'flamingo', 'dove', 'swan'};
