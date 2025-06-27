import 'dart:math';
import 'package:combat_sys/src/models/combatant.dart';
import 'package:combat_sys/src/models/game_settings.dart';
import 'package:combat_sys/src/models/skills.dart';

/// A factory for creating random Player and Monster instances for testing.
class CombatantFactory {
  final GameSettings settings;
  final Random _random = Random();

  CombatantFactory({required this.settings});

  /// Creates a random Player, with optional templates for combat style.
  Player createRandomPlayer(String name, double minExp, double maxExp, {CombatStyle style = CombatStyle.None}) {
    double experience = minExp + _random.nextDouble() * (maxExp - minExp);
    Player player = Player(name: name, experience: experience, settings: settings);
    _distributeCombatantSkills(player, (player.combatExp * (settings.playerSkillCapTotal / settings.playerCombatExpLimit)).floor(), style, isPlayer: true);
    return player;
  }

  /// Creates a random Monster, with optional templates for combat style.
  Monster createRandomMonster(String name, double minExp, double maxExp, double minCombatExp, double maxCombatExp, {CombatStyle style = CombatStyle.None}) {
    double experience = minExp + _random.nextDouble() * (maxExp - minExp);
    double combatExp = minCombatExp + _random.nextDouble() * (maxCombatExp - minCombatExp);

    Monster monster = Monster(name: name, experience: experience, combatExp: combatExp, settings: settings);
    _distributeCombatantSkills(monster, (monster.combatExp * (settings.playerSkillCapTotal / settings.playerCombatExpLimit)).floor(), style, isPlayer: false);
    return monster;
  }

  /// **UPDATED**: Generic, robust, and efficient skill distribution logic.
  void _distributeCombatantSkills(Combatant combatant, int pointsToDistribute, CombatStyle style, {required bool isPlayer}) {
    combatant.skills = {for (var skill in Skill.values) skill: 0};

    final List<Skill> availableSkills = Skill.values.where((s) => isPlayer || !utilitySkillsForPlayerOnly.contains(s)).toList();

    // --- Step 1: Define the primary skill pool based on the chosen style ---
    List<Skill> highSkillPool = [];
    if (style != CombatStyle.None) {
      switch(style) {
        case CombatStyle.Melee:
        // Offensive: MeleeCombat, Str, Tactics, Anatomy. Defensive: Parrying
          highSkillPool = [Skill.MeleeCombat, Skill.Strength, Skill.Tactics, Skill.Anatomy, Skill.Parrying];
          break;
        case CombatStyle.Ranged:
        // Offensive: RangedCombat, Dex, Tactics, DetectingHidden. Defensive: Parrying
          highSkillPool = [Skill.RangedCombat, Skill.Dexterity, Skill.Tactics, Skill.DetectingHidden, Skill.Parrying];
          break;
        case CombatStyle.Magic:
        // Offensive: MagicCombat, EvalInt, Tactics, SpiritSpeak. Defensive: ResistingSpells
          highSkillPool = [Skill.MagicCombat, Skill.EvaluatingIntelligence, Skill.Tactics, Skill.SpiritSpeak, Skill.ResistingSpells];
          break;
        case CombatStyle.None:
        // Generalist pool
          highSkillPool = [Skill.MeleeCombat, Skill.RangedCombat, Skill.MagicCombat, Skill.Parrying, Skill.ResistingSpells, Skill.Tactics];
          break;
      }
    } else {
      highSkillPool = List<Skill>.from(availableSkills);
    }

    // --- Step 2: Max out 3-4 "high skills" from the defined pool ---
    highSkillPool.shuffle(_random);
    int highSkillsToSet = (style == CombatStyle.None) ? 2 : (3 + _random.nextInt(2));

    for (int i = 0; i < highSkillsToSet && highSkillPool.isNotEmpty; i++) {
      if (pointsToDistribute >= settings.skillCap) {
        Skill skillToMax = highSkillPool.removeAt(0);
        combatant.skills[skillToMax] = settings.skillCap;
        pointsToDistribute -= settings.skillCap;
      } else {
        break;
      }
    }

    // --- Step 3: Distribute remaining points into a smaller, focused pool ---
    List<Skill> distributableSkills = availableSkills.where((s) => combatant.skills[s]! < settings.skillCap).toList();
    distributableSkills.shuffle(_random);

    if (distributableSkills.isEmpty) return;

    int secondarySkillsCount = 5 + _random.nextInt(2);
    List<Skill> secondaryPool = distributableSkills.take(secondarySkillsCount).toList();

    // --- Step 4: Robust distribution loop ---
    while (pointsToDistribute > 0 && secondaryPool.isNotEmpty) {
      int skillIndex = _random.nextInt(secondaryPool.length);
      Skill skillToIncrement = secondaryPool[skillIndex];

      combatant.skills[skillToIncrement] = combatant.skills[skillToIncrement]! + 1;
      pointsToDistribute--;

      if (combatant.skills[skillToIncrement]! >= settings.skillCap) {
        secondaryPool.removeAt(skillIndex);
      }
    }
  }
}
