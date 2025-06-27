/// A class to hold all game balance and combat adjustment values.
/// This makes it easy to fine-tune the system without changing core logic.
class GameSettings {
  // Player Experience and Skill Settings
  double playerCombatExpLimit;
  double expToCombatExpFactor;
  int playerSkillCapTotal;

  // General Skill Settings (Restored)
  int skillCap;
  int skillCapBonus;

  // Combat Settings
  int maxTurns;
  double underdogBonus;
  double hpPerStrengthPoint;
  double baseDamage;
  double tacticsDamageBonusFactor;
  double anatomyDamageBonusFactor;
  double anatomyDefenseBonusFactor;
  double magicArmorPenetrationFactor;
  double typeAdvantageMultiplier;

  GameSettings({
    // Player
    this.playerCombatExpLimit = 1000.0,
    this.expToCombatExpFactor = 0.001,
    this.playerSkillCapTotal = 700,

    // Skills (Restored)
    this.skillCap = 100,
    this.skillCapBonus = 120,

    // Combat
    this.maxTurns = 100,
    this.underdogBonus = 10.0,
    this.hpPerStrengthPoint = 2.5,
    this.baseDamage = 5.0,
    this.tacticsDamageBonusFactor = 0.5,
    this.anatomyDamageBonusFactor = 0.25,
    this.anatomyDefenseBonusFactor = 0.15,
    this.magicArmorPenetrationFactor = 0.5,
    this.typeAdvantageMultiplier = 1.3,
  });

  // Method to create a copy for easy state management in Flutter
  GameSettings copyWith({
    double? playerCombatExpLimit,
    double? expToCombatExpFactor,
    int? playerSkillCapTotal,
    int? skillCap,
    int? skillCapBonus,
    int? maxTurns,
    double? underdogBonus,
    double? hpPerStrengthPoint,
    double? baseDamage,
    double? tacticsDamageBonusFactor,
    double? anatomyDamageBonusFactor,
    double? anatomyDefenseBonusFactor,
    double? magicArmorPenetrationFactor,
    double? typeAdvantageMultiplier,
  }) {
    return GameSettings(
      playerCombatExpLimit: playerCombatExpLimit ?? this.playerCombatExpLimit,
      expToCombatExpFactor: expToCombatExpFactor ?? this.expToCombatExpFactor,
      playerSkillCapTotal: playerSkillCapTotal ?? this.playerSkillCapTotal,
      skillCap: skillCap ?? this.skillCap,
      skillCapBonus: skillCapBonus ?? this.skillCapBonus,
      maxTurns: maxTurns ?? this.maxTurns,
      underdogBonus: underdogBonus ?? this.underdogBonus,
      hpPerStrengthPoint: hpPerStrengthPoint ?? this.hpPerStrengthPoint,
      baseDamage: baseDamage ?? this.baseDamage,
      tacticsDamageBonusFactor: tacticsDamageBonusFactor ?? this.tacticsDamageBonusFactor,
      anatomyDamageBonusFactor: anatomyDamageBonusFactor ?? this.anatomyDamageBonusFactor,
      anatomyDefenseBonusFactor: anatomyDefenseBonusFactor ?? this.anatomyDefenseBonusFactor,
      magicArmorPenetrationFactor: magicArmorPenetrationFactor ?? this.magicArmorPenetrationFactor,
      typeAdvantageMultiplier: typeAdvantageMultiplier ?? this.typeAdvantageMultiplier,
    );
  }
}
