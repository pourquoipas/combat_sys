/// A class to hold all game balance and combat adjustment values.
/// This makes it easy to fine-tune the system without changing core logic.
class GameSettings {
  // Player Experience and Skill Settings
  double playerCombatExpLimit;
  double expToCombatExpFactor;
  int playerSkillCapTotal;

  // General Skill Settings
  int skillCap;
  int skillCapBonus;

  // --- HP Calculation ---
  double baseHp;
  double expToHpFactor; // e.g., a value of 50 means 1 HP per 50 experience points.

  // Combat Settings
  int maxTurns;
  double underdogBonus;
  double baseDamage;
  double typeAdvantageMultiplier;

  // Damage Formula Multipliers
  double damageBonusNormalizer;
  double damageReductionNormalizer;
  double damageReductionCap;

  // Defense Score Multipliers
  double defenseParryingVsRangedMultiplier; // Buff to parry against ranged attacks
  double defenseDexEvadeVsMagicMultiplier; // Nerf to dexterity-based evasion against magic

  // Healing Formula
  double healChanceDivisor;
  double healBaseMultiplier;
  double healRandomBonus;


  GameSettings({
    // Player
    this.playerCombatExpLimit = 1000.0,
    this.expToCombatExpFactor = 0.001,
    this.playerSkillCapTotal = 700,

    // Skills
    this.skillCap = 100,
    this.skillCapBonus = 120,

    // HP
    this.baseHp = 100.0,
    this.expToHpFactor = 40.0,

    // Combat
    this.maxTurns = 100,
    this.underdogBonus = 10.0,
    this.baseDamage = 5.0,
    this.typeAdvantageMultiplier = 1.3,

    // Damage Formula
    this.damageBonusNormalizer = 150.0,
    this.damageReductionNormalizer = 400.0,
    this.damageReductionCap = 0.9,

    // Defense Score
    this.defenseParryingVsRangedMultiplier = 1.25,
    this.defenseDexEvadeVsMagicMultiplier = 0.5,

    // Healing
    this.healChanceDivisor = 500.0,
    this.healBaseMultiplier = 0.1,
    this.healRandomBonus = 5.0,
  });

  /// Creates a copy of this GameSettings instance but with the given fields replaced with the new values.
  GameSettings copyWith({
    double? playerCombatExpLimit,
    double? expToCombatExpFactor,
    int? playerSkillCapTotal,
    int? skillCap,
    int? skillCapBonus,
    double? baseHp,
    double? expToHpFactor,
    int? maxTurns,
    double? underdogBonus,
    double? baseDamage,
    double? typeAdvantageMultiplier,
    double? damageBonusNormalizer,
    double? damageReductionNormalizer,
    double? damageReductionCap,
    double? defenseParryingVsRangedMultiplier,
    double? defenseDexEvadeVsMagicMultiplier,
    double? healChanceDivisor,
    double? healBaseMultiplier,
    double? healRandomBonus,
  }) {
    return GameSettings(
      playerCombatExpLimit: playerCombatExpLimit ?? this.playerCombatExpLimit,
      expToCombatExpFactor: expToCombatExpFactor ?? this.expToCombatExpFactor,
      playerSkillCapTotal: playerSkillCapTotal ?? this.playerSkillCapTotal,
      skillCap: skillCap ?? this.skillCap,
      skillCapBonus: skillCapBonus ?? this.skillCapBonus,
      baseHp: baseHp ?? this.baseHp,
      expToHpFactor: expToHpFactor ?? this.expToHpFactor,
      maxTurns: maxTurns ?? this.maxTurns,
      underdogBonus: underdogBonus ?? this.underdogBonus,
      baseDamage: baseDamage ?? this.baseDamage,
      typeAdvantageMultiplier: typeAdvantageMultiplier ?? this.typeAdvantageMultiplier,
      damageBonusNormalizer: damageBonusNormalizer ?? this.damageBonusNormalizer,
      damageReductionNormalizer: damageReductionNormalizer ?? this.damageReductionNormalizer,
      damageReductionCap: damageReductionCap ?? this.damageReductionCap,
      defenseParryingVsRangedMultiplier: defenseParryingVsRangedMultiplier ?? this.defenseParryingVsRangedMultiplier,
      defenseDexEvadeVsMagicMultiplier: defenseDexEvadeVsMagicMultiplier ?? this.defenseDexEvadeVsMagicMultiplier,
      healChanceDivisor: healChanceDivisor ?? this.healChanceDivisor,
      healBaseMultiplier: healBaseMultiplier ?? this.healBaseMultiplier,
      healRandomBonus: healRandomBonus ?? this.healRandomBonus,
    );
  }
}
