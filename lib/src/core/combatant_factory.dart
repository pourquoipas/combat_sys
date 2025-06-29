import 'package:combat_sys/src/models/combatant.dart';
import 'package:combat_sys/src/models/game_settings.dart';
import 'package:combat_sys/src/models/skills.dart';
import 'package:portable_rng/portable_rng.dart';

/// A factory for creating random Player and Monster instances for testing,
/// using the PortableRNG for deterministic generation.
class CombatantFactory {
  final GameSettings settings;

  CombatantFactory({required this.settings});

  /// Creates a random Player.
  /// Requires the current RNGState and returns the new Player and the next RNGState.
  RNGResult<Player> createRandomPlayer(RNGState currentState, String name, double minExp, double maxExp, {CombatStyle style = CombatStyle.None}) {
    var expResult = PortableRNG.next(currentState);
    double experience = minExp + RNGValueConverter.asDouble(expResult.value) * (maxExp - minExp);

    Player player = Player(name: name, experience: experience, settings: settings);

    var finalState = _distributeCombatantSkills(expResult.nextState, player, (player.combatExp * (settings.playerSkillCapTotal / settings.playerCombatExpLimit)).floor(), style, isPlayer: true);

    return RNGResult(player, finalState);
  }

  /// Creates a random Monster.
  RNGResult<Monster> createRandomMonster(RNGState currentState, String name, double minExp, double maxExp, double minCombatExp, double maxCombatExp, {CombatStyle style = CombatStyle.None}) {
    var expResult = PortableRNG.next(currentState);
    double experience = minExp + RNGValueConverter.asDouble(expResult.value) * (maxExp - minExp);

    var combatExpResult = PortableRNG.next(expResult.nextState);
    double combatExp = minCombatExp + RNGValueConverter.asDouble(combatExpResult.value) * (maxCombatExp - minCombatExp);

    Monster monster = Monster(name: name, experience: experience, combatExp: combatExp, settings: settings);
    var finalState = _distributeCombatantSkills(combatExpResult.nextState, monster, (monster.combatExp * (settings.playerSkillCapTotal / settings.playerCombatExpLimit)).floor(), style, isPlayer: false);

    return RNGResult(monster, finalState);
  }

  /// Generic, robust, and efficient skill distribution logic using PortableRNG.
  /// It now returns the final RNGState after all operations.
  RNGState _distributeCombatantSkills(RNGState currentState, Combatant combatant, int pointsToDistribute, CombatStyle style, {required bool isPlayer}) {
    combatant.skills = {for (var skill in Skill.values) skill: 0};
    RNGState state = currentState;

    final List<Skill> availableSkills = Skill.values.where((s) => isPlayer || !utilitySkillsForPlayerOnly.contains(s)).toList();

    List<Skill> highSkillPool = [];
    if (style != CombatStyle.None) {
      // ... (style selection logic is the same)
    } else {
      highSkillPool = List<Skill>.from(availableSkills);
    }

    // Manual shuffle using the PRNG
    var shuffleResult1 = _shuffleList(state, highSkillPool);
    highSkillPool = shuffleResult1.value;
    state = shuffleResult1.nextState;

    var countResult = PortableRNG.next(state);
    int highSkillsToSet = (style == CombatStyle.None) ? 2 : (3 + RNGValueConverter.asIntRange(countResult.value, 0, 2));
    state = countResult.nextState;

    for (int i = 0; i < highSkillsToSet && highSkillPool.isNotEmpty; i++) {
      if (pointsToDistribute >= settings.skillCap) {
        Skill skillToMax = highSkillPool.removeAt(0);
        combatant.skills[skillToMax] = settings.skillCap;
        pointsToDistribute -= settings.skillCap;
      } else { break; }
    }

    List<Skill> distributableSkills = availableSkills.where((s) => combatant.skills[s]! < settings.skillCap).toList();
    var shuffleResult2 = _shuffleList(state, distributableSkills);
    distributableSkills = shuffleResult2.value;
    state = shuffleResult2.nextState;

    if (distributableSkills.isEmpty) return state;

    var secondaryCountResult = PortableRNG.next(state);
    int secondarySkillsCount = 5 + RNGValueConverter.asIntRange(secondaryCountResult.value, 0, 2);
    state = secondaryCountResult.nextState;
    List<Skill> secondaryPool = distributableSkills.take(secondarySkillsCount).toList();

    while (pointsToDistribute > 0 && secondaryPool.isNotEmpty) {
      var indexResult = PortableRNG.next(state);
      int skillIndex = RNGValueConverter.asIntRange(indexResult.value, 0, secondaryPool.length);
      state = indexResult.nextState;

      Skill skillToIncrement = secondaryPool[skillIndex];
      combatant.skills[skillToIncrement] = combatant.skills[skillToIncrement]! + 1;
      pointsToDistribute--;

      if (combatant.skills[skillToIncrement]! >= settings.skillCap) {
        secondaryPool.removeAt(skillIndex);
      }
    }
    return state; // Return the final state
  }

  /// A deterministic list shuffle (Fisher-Yates) using PortableRNG.
  RNGResult<List<T>> _shuffleList<T>(RNGState currentState, List<T> list) {
    RNGState state = currentState;
    for (int i = list.length - 1; i > 0; i--) {
      var indexResult = PortableRNG.next(state);
      int j = RNGValueConverter.asIntRange(indexResult.value, 0, i + 1);
      state = indexResult.nextState;

      T temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return RNGResult(list, state);
  }
}
