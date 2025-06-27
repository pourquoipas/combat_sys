import 'dart:math';
import 'game_settings.dart';
import 'skills.dart';

/// Abstract base class for any entity participating in combat.
abstract class Combatant {
  final String name;
  double experience;
  late Map<Skill, int> skills;

  Combatant({required this.name, this.experience = 0}) {
    // Initialize all skills to 0
    skills = {for (var skill in Skill.values) skill: 0};
  }

  /// The combat-effective experience. Calculated differently for Players vs Monsters.
  double get combatExp;

  /// The total Hit Points of the combatant.
  double get maxHp;

  // Helper to get a skill's value, defaulting to 0 if not present.
  int getSkill(Skill skill) => skills[skill] ?? 0;

  @override
  String toString() {
    return '$name (Exp: ${experience.toStringAsFixed(0)}, CombatExp: ${combatExp.toStringAsFixed(0)})';
  }
}

/// Represents a Player character.
class Player extends Combatant {
  final GameSettings settings;

  Player({
    required super.name,
    super.experience,
    required this.settings,
  });

  @override
  double get combatExp {
    // Inverse exponential function: grows fast at low exp, then approaches the limit.
    return settings.playerCombatExpLimit * (1 - exp(-settings.expToCombatExpFactor * experience));
  }

  @override
  double get maxHp {
    return (SkillUtils.getRealSkillValue(getSkill(Skill.Strength)) * settings.hpPerStrengthPoint) + 50;
  }

  /// Distributes skill points based on combatExp.
  void distributeSkillPoints() {
    // Normalize combatExp from its limit (e.g., 1000) to the total skill points cap (e.g., 700)
    double ratio = settings.playerSkillCapTotal / settings.playerCombatExpLimit;
    int pointsToDistribute = (combatExp * ratio).floor();

    // Reset skills before distribution
    skills = {for (var skill in Skill.values) skill: 0};

    // Simple random distribution for testing purposes. A real implementation
    // would let the player choose.
    var random = Random();
    List<Skill> allSkills = Skill.values.toList();

    for (int i = 0; i < pointsToDistribute; i++) {
      Skill randomSkill = allSkills[random.nextInt(allSkills.length)];
      if (skills[randomSkill]! < settings.skillCap) {
        skills[randomSkill] = skills[randomSkill]! + 1;
      } else {
        // If skill is capped, try to find another one.
        // This is a naive approach, could loop forever if all skills are capped.
        // A better approach would be to pick from a list of non-capped skills.
        i--; // Retry with another skill
      }
    }
  }
}

/// Represents a Monster or NPC.
class Monster extends Combatant {
  double _combatExp;

  Monster({
    required super.name,
    super.experience,
    required double combatExp,
    required this.settings,
  }) : _combatExp = combatExp;

  final GameSettings settings;


  @override
  double get combatExp => _combatExp;

  // Monsters can have their combat exp set directly.
  set combatExp(double value) {
    _combatExp = value;
  }

  @override
  double get maxHp {
    return (SkillUtils.getRealSkillValue(getSkill(Skill.Strength)) * settings.hpPerStrengthPoint) + 50;
  }
}

