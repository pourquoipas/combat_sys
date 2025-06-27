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

  // Combat Settings
  int maxTurns;
  double underdogBonus;
  double hpPerStrengthPoint;
  double baseDamage;
  double typeAdvantageMultiplier;

  // --- NEW: Fine-Tuning Parameters for Combat Formulas ---

  // Attack Score Multipliers
  double scoreTacticsMultiplier;
  double scoreAnatomyMultiplier;
  double scoreDexterityMultiplier;
  double scoreEvalIntMultiplier;

  // Damage Formula Multipliers
  double damageBonusNormalizer;
  double damageReductionNormalizer;
  double damageReductionCap;

  // Defense Score Multipliers
  double defenseParryingVsMeleeMultiplier;
  double defenseSpiritSpeakMultiplier;
  double defenseDexterityMultiplier;

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

    // Combat
    this.maxTurns = 100,
    this.underdogBonus = 10.0,
    this.hpPerStrengthPoint = 2.5,
    this.baseDamage = 5.0,
    this.typeAdvantageMultiplier = 1.3,

    // Attack Score
    this.scoreTacticsMultiplier = 0.5,
    this.scoreAnatomyMultiplier = 0.3,
    this.scoreDexterityMultiplier = 0.3,
    this.scoreEvalIntMultiplier = 0.4,

    // Damage Formula
    this.damageBonusNormalizer = 150.0,
    this.damageReductionNormalizer = 400.0,
    this.damageReductionCap = 0.9,

    // Defense Score
    this.defenseParryingVsMeleeMultiplier = 0.8,
    this.defenseSpiritSpeakMultiplier = 0.2,
    this.defenseDexterityMultiplier = 0.4,

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
    int? maxTurns,
    double? underdogBonus,
    double? hpPerStrengthPoint,
    double? baseDamage,
    double? typeAdvantageMultiplier,
    double? scoreTacticsMultiplier,
    double? scoreAnatomyMultiplier,
    double? scoreDexterityMultiplier,
    double? scoreEvalIntMultiplier,
    double? damageBonusNormalizer,
    double? damageReductionNormalizer,
    double? damageReductionCap,
    double? defenseParryingVsMeleeMultiplier,
    double? defenseSpiritSpeakMultiplier,
    double? defenseDexterityMultiplier,
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
      maxTurns: maxTurns ?? this.maxTurns,
      underdogBonus: underdogBonus ?? this.underdogBonus,
      hpPerStrengthPoint: hpPerStrengthPoint ?? this.hpPerStrengthPoint,
      baseDamage: baseDamage ?? this.baseDamage,
      typeAdvantageMultiplier: typeAdvantageMultiplier ?? this.typeAdvantageMultiplier,
      scoreTacticsMultiplier: scoreTacticsMultiplier ?? this.scoreTacticsMultiplier,
      scoreAnatomyMultiplier: scoreAnatomyMultiplier ?? this.scoreAnatomyMultiplier,
      scoreDexterityMultiplier: scoreDexterityMultiplier ?? this.scoreDexterityMultiplier,
      scoreEvalIntMultiplier: scoreEvalIntMultiplier ?? this.scoreEvalIntMultiplier,
      damageBonusNormalizer: damageBonusNormalizer ?? this.damageBonusNormalizer,
      damageReductionNormalizer: damageReductionNormalizer ?? this.damageReductionNormalizer,
      damageReductionCap: damageReductionCap ?? this.damageReductionCap,
      defenseParryingVsMeleeMultiplier: defenseParryingVsMeleeMultiplier ?? this.defenseParryingVsMeleeMultiplier,
      defenseSpiritSpeakMultiplier: defenseSpiritSpeakMultiplier ?? this.defenseSpiritSpeakMultiplier,
      defenseDexterityMultiplier: defenseDexterityMultiplier ?? this.defenseDexterityMultiplier,
      healChanceDivisor: healChanceDivisor ?? this.healChanceDivisor,
      healBaseMultiplier: healBaseMultiplier ?? this.healBaseMultiplier,
      healRandomBonus: healRandomBonus ?? this.healRandomBonus,
    );
  }
}
