import 'dart:math';
import 'package:combat_sys/src/models/game_settings.dart';
import 'package:combat_sys/src/models/skills.dart';

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
  /// **UPDATED**: HP is now decoupled from Strength and based on experience.
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
    return settings.baseHp + (experience / settings.expToHpFactor);
  }

  /// Distributes skill points based on combatExp.
  void distributeSkillPoints() {
    // This logic is now in the CombatantFactory.
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
    return settings.baseHp + (experience / settings.expToHpFactor);
  }
}
