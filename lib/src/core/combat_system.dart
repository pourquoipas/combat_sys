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

class CombatSystem {
  final GameSettings settings;
  final Random _random = Random();

  CombatSystem({required this.settings});

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

      double healed1 = _performHeal(c1, log);
      if (healed1 > 0) { hp1 = min(initialHp1, hp1 + healed1); totalHealed1 += healed1; }
      double healed2 = _performHeal(c2, log);
      if (healed2 > 0) { hp2 = min(initialHp2, hp2 + healed2); totalHealed2 += healed2; }
    }

    return _createResult(CombatResultType.draw, turn - 1, initialHp1, initialHp2, hp1, hp2, totalHealed1, totalHealed2);
  }

  String _getAttackTypeFromStyle(CombatStyle style) => style.name.toLowerCase();

  CombatResult _createResult(CombatResultType type, int turns, double iHp1, double iHp2, double fHp1, double fHp2, double hHp1, double hHp2) {
    return CombatResult(type: type, turns: turns, c1InitialHp: iHp1, c2InitialHp: iHp2, c1FinalHp: fHp1, c2FinalHp: fHp2, c1HealedHp: hHp1, c2HealedHp: hHp2);
  }

  double _performHeal(Combatant c, CombatLog? log) {
    double realHealing = SkillUtils.getRealSkillValue(c.getSkill(Skill.Healing));
    if (_random.nextDouble() < (realHealing / 500.0)) { return (realHealing * 0.1) + _random.nextDouble() * 5; }
    return 0;
  }

  bool _performAttack(Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    double attackScore = _getAttackScore(attacker, attackType);
    double defenseScore = _getDefenseScore(defender, attackType);
    double totalPool = attackScore + defenseScore + (2 * settings.underdogBonus);
    if (totalPool <= 0) return false;
    double hitChance = (attackScore + settings.underdogBonus) / totalPool;
    return _random.nextDouble() < hitChance;
  }

  double _calculateDamage(Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    double baseDmg = settings.baseDamage;
    double damageBonusFactor = 0;

    if (attackType == 'magic') {
      damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.EvaluatingIntelligence)) / 100) + (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) / 100 * settings.tacticsDamageBonusFactor);
    } else {
      damageBonusFactor = (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Strength)) / 100) + (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Tactics)) / 100 * settings.tacticsDamageBonusFactor) + (SkillUtils.getRealSkillValue(attacker.getSkill(Skill.Anatomy)) / 100 * settings.anatomyDamageBonusFactor);
    }

    double realDefenderAnatomy = SkillUtils.getRealSkillValue(defender.getSkill(Skill.Anatomy));
    double damageReduction = 1 - (realDefenderAnatomy / 100 * settings.anatomyDefenseBonusFactor);
    if (attackType == 'magic') {
      damageReduction = 1 - (realDefenderAnatomy / 100 * settings.anatomyDefenseBonusFactor * (1 - settings.magicArmorPenetrationFactor));
    }

    double finalDamage = baseDmg * (1 + damageBonusFactor) * damageReduction;

    // *** NEW: Type Advantage Logic ***
    bool hasAdvantage = (attackType == 'magic' && defenderStyle == CombatStyle.Melee) ||
        (attackType == 'melee' && defenderStyle == CombatStyle.Ranged) ||
        (attackType == 'ranged' && defenderStyle == CombatStyle.Magic);

    if (hasAdvantage) {
      finalDamage *= settings.typeAdvantageMultiplier;
    }

    return finalDamage < 1.0 ? 1.0 : finalDamage;
  }

  double _getAttackScore(Combatant c, String type) {
    Skill primarySkill;
    switch (type) {
      case 'ranged': primarySkill = Skill.RangedCombat; break;
      case 'magic': primarySkill = Skill.MagicCombat; break;
      default: primarySkill = Skill.MeleeCombat; break;
    }
    double score = SkillUtils.getRealSkillValue(c.getSkill(primarySkill));
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Tactics)) * 0.5;
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Anatomy)) * 0.3;
    if (type != 'magic') { score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity)) * 0.3; }
    else { score += SkillUtils.getRealSkillValue(c.getSkill(Skill.EvaluatingIntelligence)) * 0.4; }
    return score;
  }

  double _getDefenseScore(Combatant c, String attackType) {
    double score;
    if (attackType == 'magic') {
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.ResistingSpells));
      score += SkillUtils.getRealSkillValue(c.getSkill(Skill.EvaluatingIntelligence)) * 0.4;
    } else {
      score = SkillUtils.getRealSkillValue(c.getSkill(Skill.Parrying));
      // Parrying is less effective vs Melee than vs Ranged, creating the advantage for Melee.
      if (attackType == 'melee') { score *= 0.8; }
    }
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Dexterity)) * 0.4;
    score += SkillUtils.getRealSkillValue(c.getSkill(Skill.Anatomy)) * 0.2;
    return score;
  }
}
