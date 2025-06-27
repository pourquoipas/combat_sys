import 'dart:math';
import 'package:combat_sys/src/models/combatant.dart';
import 'package:combat_sys/src/models/game_settings.dart';
import 'package:combat_sys/src/models/skills.dart';

enum CombatResultType { combatant1Wins, combatant2Wins, draw }

class CombatResult {
  final CombatResultType type;
  final int turns;
  final double c1InitialHp, c2InitialHp, c1FinalHp, c2FinalHp, c1HealedHp, c2HealedHp;
  CombatResult({ required this.type, required this.turns, required this.c1InitialHp, required this.c2InitialHp, required this.c1FinalHp, required this.c2FinalHp, this.c1HealedHp = 0, this.c2HealedHp = 0 });
}

class CombatLog {
  final List<String> entries = [];
  void add(String entry) => entries.add(entry);
}


/// ## Combat System Core Logic (v8)
///
/// This class orchestrates a fight between two combatants. All balancing values
/// ("magic numbers") have been moved to the `GameSettings` class for complete
/// tunability of the combat formulas.
///
/// 1.  **Score-Based Hit Chance**: The probability of an attack succeeding is based on a
///     comparison of the attacker's "Attack Score" vs the defender's "Defense Score" (evasion).
/// 2.  **Specialized Damage Sources**: Each combat style (Melee, Ranged, Magic) now derives its
///     damage bonus from a distinct trio of skills, making builds more unique.
/// 3.  **Specialized Damage Reduction**: Damage reduction is calculated based on the
///     incoming attack type, making defensive builds more strategic.
/// 4.  **Direct Type Advantage**: The `typeAdvantageMultiplier` provides a clear and tunable
///     bonus to reinforce the Rock-Paper-Scissors triangle (Magic > Melee > Ranged > Magic).
class CombatSystem {
  final GameSettings settings;
  final Random _random = Random();

  CombatSystem({required this.settings});

  /// Executes a full combat simulation between two combatants.
  CombatResult fight(Combatant c1, Combatant c2, {CombatLog? log, CombatStyle c1Style = CombatStyle.Melee, CombatStyle c2Style = CombatStyle.Melee}) {
    double hp1 = c1.maxHp, hp2 = c2.maxHp;
    final double initialHp1 = hp1, initialHp2 = hp2;
    double totalHealed1 = 0, totalHealed2 = 0;

    String c1AttackType = _getAttackTypeFromStyle(c1Style);
    String c2AttackType = _getAttackTypeFromStyle(c2Style);

    int turn = 0;
    for (turn = 1; turn <= settings.maxTurns; turn++) {
      if (_performAttack(c1, c2, c1AttackType, c2Style, log)) {
        hp2 -= _calculateDamage(c1, c2, c1AttackType, c2Style, log);
        if (hp2 <= 0) return _createResult(CombatResultType.combatant1Wins, turn, initialHp1, initialHp2, hp1, 0, totalHealed1, totalHealed2);
      }
      if (_performAttack(c2, c1, c2AttackType, c1Style, log)) {
        hp1 -= _calculateDamage(c2, c1, c2AttackType, c1Style, log);
        if (hp1 <= 0) return _createResult(CombatResultType.combatant2Wins, turn, initialHp1, initialHp2, 0, hp2, totalHealed1, totalHealed2);
      }

      double healed1 = _performHeal(c1);
      if (healed1 > 0) { hp1 = min(initialHp1, hp1 + healed1); totalHealed1 += healed1; }
      double healed2 = _performHeal(c2);
      if (healed2 > 0) { hp2 = min(initialHp2, hp2 + healed2); totalHealed2 += healed2; }
    }

    return _createResult(CombatResultType.draw, turn - 1, initialHp1, initialHp2, hp1, hp2, totalHealed1, totalHealed2);
  }

  /// Determines if an attack is successful.
  bool _performAttack(Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    double attackScore = _getAttackScore(attacker, attackType);
    double defenseScore = _getDefenseScore(defender, attackType);
    double totalPool = attackScore + defenseScore + (2 * settings.underdogBonus);
    if (totalPool <= 0) return false;
    double hitChance = (attackScore + settings.underdogBonus) / totalPool;
    return _random.nextDouble() < hitChance;
  }

  /// Calculates the final damage after a successful hit.
  double _calculateDamage(Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    double damageBonusFactor = 0;

    switch (attackType) {
      case 'melee':
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Strength)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Anatomy))) / settings.damageBonusNormalizer;
        break;
      case 'ranged':
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Dexterity)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.DetectingHidden))) / settings.damageBonusNormalizer;
        break;
      case 'magic':
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.EvaluatingIntelligence)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) +
            SkillUtils.getRealSkillValue(attacker.getSkill(Skill.SpiritSpeak))) / settings.damageBonusNormalizer;
        break;
    }

    double damageReductionFactor = 0;
    if (attackType == 'magic') {
      damageReductionFactor = (SkillUtils.getRealSkillValue(defender.getSkill(Skill.ResistingSpells)) +
          SkillUtils.getRealSkillValue(defender.getSkill(Skill.SpiritSpeak))) / settings.damageReductionNormalizer;
    } else {
      damageReductionFactor = (SkillUtils.getRealSkillValue(defender.getSkill(Skill.Strength)) +
          SkillUtils.getRealSkillValue(defender.getSkill(Skill.Anatomy))) / settings.damageReductionNormalizer;
    }
    double damageReduction = 1.0 - damageReductionFactor.clamp(0.0, settings.damageReductionCap);

    double finalDamage = settings.baseDamage * (1 + damageBonusFactor) * damageReduction;

    bool hasAdvantage = (attackType == 'magic' && defenderStyle == CombatStyle.Melee) ||
        (attackType == 'melee' && defenderStyle == CombatStyle.Ranged) ||
        (attackType == 'ranged' && defenderStyle == CombatStyle.Magic);

    if (hasAdvantage) {
      finalDamage *= settings.typeAdvantageMultiplier;
    }

    return finalDamage < 1.0 ? 1.0 : finalDamage;
  }

  /// Calculates the attacker's total score for a specific attack type.
  double _getAttackScore(Combatant c, String type) {
    Skill primarySkill;
    switch (type) {
      case 'ranged': primarySkill = Skill.RangedCombat; break;
      case 'magic': primarySkill = Skill.MagicCombat; break;
      default: primarySkill = Skill.MeleeCombat; break;
    }
    double score = SkillUtils.getRealSkillValue(c.getSkill(primarySkill));
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Tactics)) * settings.scoreTacticsMultiplier;
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Anatomy)) * settings.scoreAnatomyMultiplier;
    if (type != 'magic') {
      score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity)) * settings.scoreDexterityMultiplier;
    } else {
      score += SkillUtils.getRealSkillValue(c.getSkill(Skill.EvaluatingIntelligence)) * settings.scoreEvalIntMultiplier;
    }
    return score;
  }

  /// Calculates the defender's total score against a specific attack type.
  double _getDefenseScore(Combatant c, String attackType) {
    double score;
    if (attackType == 'magic') {
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.ResistingSpells));
      score += SkillUtils.getRealSkillValue(c.getSkill(Skill.SpiritSpeak)) * settings.defenseSpiritSpeakMultiplier;
    } else {
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.Parrying));
      if (attackType == 'melee') {
        score *= settings.defenseParryingVsMeleeMultiplier;
      }
    }
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity)) * settings.defenseDexterityMultiplier;
    return score;
  }

  /// Simulates a chance for a combatant to heal a small amount of HP in a turn.
  double _performHeal(Combatant c) {
    double realHealing = SkillUtils.getRealSkillValue(c.getSkill(Skill.Healing));
    if (_random.nextDouble() < (realHealing / settings.healChanceDivisor)) {
      return (realHealing * settings.healBaseMultiplier) + _random.nextDouble() * settings.healRandomBonus;
    }
    return 0;
  }

  /// Converts a CombatStyle enum to a string representing the attack type.
  String _getAttackTypeFromStyle(CombatStyle style) => style.name.toLowerCase();

  /// Creates a CombatResult object with all the final data from a fight.
  CombatResult _createResult(CombatResultType type, int turns, double iHp1, double iHp2, double fHp1, double fHp2, double hHp1, double hHp2) {
    return CombatResult(type: type, turns: turns, c1InitialHp: iHp1, c2InitialHp: iHp2, c1FinalHp: fHp1, c2FinalHp: fHp2, c1HealedHp: hHp1, c2HealedHp: hHp2);
  }
}
