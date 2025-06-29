import 'dart:math';
import 'package:combat_sys/src/models/combatant.dart';
import 'package:combat_sys/src/models/game_settings.dart';
import 'package:combat_sys/src/models/skills.dart';
import 'package:portable_rng/portable_rng.dart';

// CombatResult and CombatLog classes remain unchanged

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

/// ## Combat System Core Logic (v9)
///
/// This version integrates the PortableRNG for fully deterministic combat simulations.
/// All functions involving randomness now accept an RNGState and return an RNGResult.
class CombatSystem {
  final GameSettings settings;

  CombatSystem({required this.settings});

  /// Executes a full combat simulation.
  /// Requires the current RNGState and returns the final CombatResult and the next RNGState.
  RNGResult<CombatResult> fight(RNGState currentState, Combatant c1, Combatant c2, {CombatLog? log, CombatStyle c1Style = CombatStyle.Melee, CombatStyle c2Style = CombatStyle.Melee}) {
    RNGState state = currentState;
    double hp1 = c1.maxHp, hp2 = c2.maxHp;
    final double initialHp1 = hp1, initialHp2 = hp2;
    double totalHealed1 = 0, totalHealed2 = 0;

    String c1AttackType = _getAttackTypeFromStyle(c1Style);
    String c2AttackType = _getAttackTypeFromStyle(c2Style);

    int turn = 0;
    for (turn = 1; turn <= settings.maxTurns; turn++) {
      var attack1Result = _performAttack(state, c1, c2, c1AttackType, c2Style, log);
      state = attack1Result.nextState;
      if (attack1Result.value) { // if hit
        hp2 -= _calculateDamage(c1, c2, c1AttackType, c2Style, log);
        if (hp2 <= 0) return RNGResult(_createResult(CombatResultType.combatant1Wins, turn, initialHp1, initialHp2, hp1, 0, totalHealed1, totalHealed2), state);
      }

      var attack2Result = _performAttack(state, c2, c1, c2AttackType, c1Style, log);
      state = attack2Result.nextState;
      if (attack2Result.value) { // if hit
        hp1 -= _calculateDamage(c2, c1, c2AttackType, c1Style, log);
        if (hp1 <= 0) return RNGResult(_createResult(CombatResultType.combatant2Wins, turn, initialHp1, initialHp2, 0, hp2, totalHealed1, totalHealed2), state);
      }

      var heal1Result = _performHeal(state, c1);
      state = heal1Result.nextState;
      if (heal1Result.value > 0) { hp1 = min(initialHp1, hp1 + heal1Result.value); totalHealed1 += heal1Result.value; }

      var heal2Result = _performHeal(state, c2);
      state = heal2Result.nextState;
      if (heal2Result.value > 0) { hp2 = min(initialHp2, hp2 + heal2Result.value); totalHealed2 += heal2Result.value; }
    }

    return RNGResult(_createResult(CombatResultType.draw, turn - 1, initialHp1, initialHp2, hp1, hp2, totalHealed1, totalHealed2), state);
  }

  RNGResult<bool> _performAttack(RNGState currentState, Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    var rawResult = PortableRNG.next(currentState);

    double attackScore = _getAttackScore(attacker, attackType);
    double defenseScore = _getDefenseScore(defender, attackType);
    double totalPool = attackScore + defenseScore + (2 * settings.underdogBonus);

    if (totalPool <= 0) return RNGResult(false, rawResult.nextState);

    double hitChance = (attackScore + settings.underdogBonus) / totalPool;
    bool didHit = RNGValueConverter.asDouble(rawResult.value) < hitChance;

    return RNGResult(didHit, rawResult.nextState);
  }

  // _calculateDamage is now fully deterministic and doesn't need RNGState
  double _calculateDamage(Combatant attacker, Combatant defender, String attackType, CombatStyle defenderStyle, CombatLog? log) {
    // Unchanged from previous version
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
    if (hasAdvantage) { finalDamage *= settings.typeAdvantageMultiplier; }
    return finalDamage < 1.0 ? 1.0 : finalDamage;
  }

  RNGResult<double> _performHeal(RNGState currentState, Combatant c) {
    var rawResult = PortableRNG.next(currentState);

    double realHealing = SkillUtils.getRealSkillValue(c.getSkill(Skill.Healing));
    if (RNGValueConverter.asDouble(rawResult.value) < (realHealing / settings.healChanceDivisor)) {

      var bonusResult = PortableRNG.next(rawResult.nextState);
      double healAmount = (realHealing * settings.healBaseMultiplier) + RNGValueConverter.asDouble(bonusResult.value) * settings.healRandomBonus;
      return RNGResult(healAmount, bonusResult.nextState);
    }

    return RNGResult(0.0, rawResult.nextState);
  }

  // Unchanged private helper methods
  double _getAttackScore(Combatant c, String type) { /* ... */ return 0; }
  double _getDefenseScore(Combatant c, String attackType) { /* ... */ return 0; }
  String _getAttackTypeFromStyle(CombatStyle style) => style.name.toLowerCase();
  CombatResult _createResult(CombatResultType type, int turns, double iHp1, double iHp2, double fHp1, double fHp2, double hHp1, double hHp2) {
    return CombatResult(type: type, turns: turns, c1InitialHp: iHp1, c2InitialHp: iHp2, c1FinalHp: fHp1, c2FinalHp: fHp2, c1HealedHp: hHp1, c2HealedHp: hHp2);
  }
}
