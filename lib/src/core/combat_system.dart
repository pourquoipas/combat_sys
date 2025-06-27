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
/// have been moved to the `GameSettings` class for complete tunability.
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

    log?.add("--- FIGHT START: ${c1.name} [${c1Style.name}] vs ${c2.name} [${c2Style.name}] ---");

    int turn = 0;
    for (turn = 1; turn <= settings.maxTurns; turn++) {
      log?.add("\n--- Turn $turn ---");
      if (_performAttack(c1, c2, c1AttackType, c2Style, log)) {
        double damage = _calculateDamage(c1, c2, c1AttackType, c2Style, log);
        log?.add("${c1.name} hits ${c2.name} for ${damage.toStringAsFixed(1)} damage.");
        hp2 -= damage;
        if (hp2 <= 0) return _createResult(CombatResultType.combatant1Wins, turn, initialHp1, initialHp2, hp1, 0, totalHealed1, totalHealed2);
      } else {
        log?.add("${c1.name} misses ${c2.name}.");
      }

      if (_performAttack(c2, c1, c2AttackType, c1Style, log)) {
        double damage = _calculateDamage(c2, c1, c2AttackType, c1Style, log);
        log?.add("${c2.name} hits ${c1.name} for ${damage.toStringAsFixed(1)} damage.");
        hp1 -= damage;
        if (hp1 <= 0) return _createResult(CombatResultType.combatant2Wins, turn, initialHp1, initialHp2, 0, hp2, totalHealed1, totalHealed2);
      } else {
        log?.add("${c2.name} misses ${c1.name}.");
      }

      double healed1 = _performHeal(c1);
      if (healed1 > 0) {
        log?.add("${c1.name} heals for ${healed1.toStringAsFixed(1)} HP.");
        hp1 = min(initialHp1, hp1 + healed1);
        totalHealed1 += healed1;
      }
      double healed2 = _performHeal(c2);
      if (healed2 > 0) {
        log?.add("${c2.name} heals for ${healed2.toStringAsFixed(1)} HP.");
        hp2 = min(initialHp2, hp2 + healed2);
        totalHealed2 += healed2;
      }
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
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Strength)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Anatomy))) / settings.damageBonusNormalizer;
        break;
      case 'ranged':
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Dexterity)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.DetectingHidden))) / settings.damageBonusNormalizer;
        break;
      case 'magic':
        damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.EvaluatingIntelligence)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) + SkillUtils.getRealSkillValue(attacker.getSkill(Skill.SpiritSpeak))) / settings.damageBonusNormalizer;
        break;
    }

    double damageReductionFactor = 0;
    if (attackType == 'magic') {
      damageReductionFactor = (SkillUtils.getRealSkillValue(defender.getSkill(Skill.ResistingSpells)) + SkillUtils.getRealSkillValue(defender.getSkill(Skill.SpiritSpeak))) / settings.damageReductionNormalizer;
    } else {
      damageReductionFactor = (SkillUtils.getRealSkillValue(defender.getSkill(Skill.Strength)) + SkillUtils.getRealSkillValue(defender.getSkill(Skill.Anatomy))) / settings.damageReductionNormalizer;
    }
    double damageReduction = 1.0 - damageReductionFactor.clamp(0.0, settings.damageReductionCap);

    double finalDamage = settings.baseDamage * (1 + damageBonusFactor) * damageReduction;

    bool hasAdvantage = (attackType == 'magic' && defenderStyle == CombatStyle.Melee) || (attackType == 'melee' && defenderStyle == CombatStyle.Ranged) || (attackType == 'ranged' && defenderStyle == CombatStyle.Magic);

    if (hasAdvantage) {
      finalDamage *= settings.typeAdvantageMultiplier;
    }
    return finalDamage < 1.0 ? 1.0 : finalDamage;
  }

  /// Calculates the attacker's total score for a specific attack type (hit chance).
  double _getAttackScore(Combatant c, String type) {
    Skill primarySkill = (type == 'ranged') ? Skill.RangedCombat : (type == 'magic') ? Skill.MagicCombat : Skill.MeleeCombat;
    double score = SkillUtils.getRealSkillValue(c.getSkill(primarySkill));
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Tactics)) * 0.5;
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Anatomy)) * 0.3;
    if (type != 'magic') { score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity)) * 0.3; }
    else { score += SkillUtils.getRealSkillValue(c.getSkill(Skill.EvaluatingIntelligence)) * 0.4; }
    return score;
  }

  /// **UPDATED**: Calculates the defender's total score against a specific attack type (evasion).
  double _getDefenseScore(Combatant c, String attackType) {
    double score;
    double dexEvade = SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity));

    if (attackType == 'magic') {
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.ResistingSpells));
      // Dex-based evasion is less effective against magic
      score += dexEvade * settings.defenseDexEvadeVsMagicMultiplier;
    } else { // melee or ranged
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.Parrying));
      // Parrying is more effective against ranged attacks
      if (attackType == 'ranged') {
        score *= settings.defenseParryingVsRangedMultiplier;
      }
      score += dexEvade; // Full dexterity evasion against physical attacks
    }
    return score;
  }

  double _performHeal(Combatant c) {
    double realHealing = SkillUtils.getRealSkillValue(c.getSkill(Skill.Healing));
    if (_random.nextDouble() < (realHealing / settings.healChanceDivisor)) {
      return (realHealing * settings.healBaseMultiplier) + _random.nextDouble() * settings.healRandomBonus;
    }
    return 0;
  }

  String _getAttackTypeFromStyle(CombatStyle style) => style.name.toLowerCase();

  CombatResult _createResult(CombatResultType type, int turns, double iHp1, double iHp2, double fHp1, double fHp2, double hHp1, double hHp2) {
    return CombatResult(type: type, turns: turns, c1InitialHp: iHp1, c2InitialHp: iHp2, c1FinalHp: fHp1, c2FinalHp: fHp2, c1HealedHp: hHp1, c2HealedHp: hHp2);
  }
}
