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

  /// **REWRITTEN**: Generic, robust, and efficient skill distribution logic.
  void _distributeCombatantSkills(Combatant combatant, int pointsToDistribute, CombatStyle style, {required bool isPlayer}) {
    combatant.skills = {for (var skill in Skill.values) skill: 0};

    // --- Step 1: Define the available skill pool for this combatant ---
    final List<Skill> availableSkills = Skill.values.where((s) => isPlayer || !utilitySkillsForPlayerOnly.contains(s)).toList();

    // --- Step 2: Set 3-4 "high skills" to the cap ---
    List<Skill> highSkillPool = [];
    if (style != CombatStyle.None) {
      switch(style) {
        case CombatStyle.Melee: highSkillPool = [Skill.MeleeCombat, Skill.Parrying, Skill.Strength, Skill.Tactics]; break;
        case CombatStyle.Ranged: highSkillPool = [Skill.RangedCombat, Skill.Dexterity, Skill.Anatomy, Skill.Tactics]; break;
        case CombatStyle.Magic: highSkillPool = [Skill.MagicCombat, Skill.ResistingSpells, Skill.EvaluatingIntelligence, Skill.SpiritSpeak]; break;
        case CombatStyle.None: // Use all primary combat skills if None is selected
          highSkillPool = [Skill.MeleeCombat, Skill.RangedCombat, Skill.MagicCombat, Skill.Parrying, Skill.ResistingSpells];
          break;
      }
    } else {
      // If no style, pick from all available skills
      highSkillPool = List<Skill>.from(availableSkills);
    }

    highSkillPool.shuffle(_random);
    int highSkillsToSet = (style == CombatStyle.None) ? 2 : (3 + _random.nextInt(2)); // Set 2 if None, else 3 or 4

    for (int i = 0; i < highSkillsToSet && highSkillPool.isNotEmpty; i++) {
      if (pointsToDistribute >= settings.skillCap) {
        Skill skillToMax = highSkillPool.removeAt(0);
        combatant.skills[skillToMax] = settings.skillCap;
        pointsToDistribute -= settings.skillCap;
      } else {
        break; // Not enough points to max out more skills
      }
    }

    // --- Step 3: Distribute remaining points into a smaller, focused pool ---
    // Create a pool of skills that are not yet capped.
    List<Skill> distributableSkills = availableSkills.where((s) => combatant.skills[s]! < settings.skillCap).toList();
    distributableSkills.shuffle(_random);

    if (distributableSkills.isEmpty) return; // All skills are capped, nothing left to do.

    // Focus points on a smaller group of 5-6 secondary skills
    int secondarySkillsCount = 5 + _random.nextInt(2);
    List<Skill> secondaryPool = distributableSkills.take(secondarySkillsCount).toList();

    // Add any primary combat skills that weren't maxed out to this pool to prioritize them
    final primaryCombatSkills = [Skill.MeleeCombat, Skill.RangedCombat, Skill.MagicCombat];
    for (var pSkill in primaryCombatSkills) {
      if (combatant.skills[pSkill]! < settings.skillCap && !secondaryPool.contains(pSkill)) {
        secondaryPool.add(pSkill);
      }
    }

    // --- Step 4: Robust distribution loop ---
    // This loop is guaranteed to terminate because either points run out or the pool becomes empty.
    while (pointsToDistribute > 0 && secondaryPool.isNotEmpty) {
      int skillIndex = _random.nextInt(secondaryPool.length);
      Skill skillToIncrement = secondaryPool[skillIndex];

      combatant.skills[skillToIncrement] = combatant.skills[skillToIncrement]! + 1;
      pointsToDistribute--;

      // If a skill reaches the cap, remove it from the pool so it's not chosen again.
      if (combatant.skills[skillToIncrement]! >= settings.skillCap) {
        secondaryPool.removeAt(skillIndex);
      }
    }
  }
}
