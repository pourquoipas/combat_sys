/// Enum for the monster's preferred combat style, used by the factory.
enum CombatStyle { None, Melee, Ranged, Magic }

/// Enum representing all 21 available skills in the game, rebalanced for better utility.
enum Skill {
  // --- PRIMARY COMBAT SKILLS ---
  MeleeCombat,      // Governs all melee attacks (swords, maces, axes).
  RangedCombat,     // Governs all ranged attacks (bows, throwing).
  MagicCombat,      // Governs spellcasting effectiveness and damage.

  // --- PRIMARY DEFENSE & TACTICS SKILLS ---
  Parrying,         // Skill in using weapons or shields to block attacks.
  ResistingSpells,  // Ability to reduce magical damage and effects.
  Tactics,          // Posizionamento e strategia, aumenta il danno e la precisione.
  Anatomy,          // Conoscenza dei punti deboli, aumenta il danno critico e la difesa.

  // --- PRIMARY STATS (Treated as skills) ---
  Strength,         // Influences HP, carrying capacity, and physical damage.
  Dexterity,        // Influences speed, evasion, and ranged/melee accuracy.

  // --- MAGIC & SUPPORT SKILLS ---
  EvaluatingIntelligence, // Valutare il mana e la potenza magica, migliora la difesa/attacco magico.
  Healing,          // Ability to heal self and others. Provides a small regeneration bonus.
  SpiritSpeak,      // Communion with the dead. Boosts healing and magical resistance.

  // --- UTILITY & AWARENESS SKILLS ---
  DetectingHidden,  // Ability to find traps, hidden objects, and stealthed creatures.
  Luck,             // Influences everything in small amounts (loot, critical hits, evasion).

  // --- HARVESTING SKILLS ---
  Lumberjacking,    // Gathering wood. Provides a small bonus to physical damage.
  Mining,           // Mining ore. Provides a small bonus to physical defense/toughness.
  Herbalism,        // Gathering reagents for alchemy. Provides a small bonus to poison/elemental resistance.

  // --- CRAFTING SKILLS ---
  Blacksmithing,    // Crafting metal weapons and armor. Provides a small damage soak bonus.
  Fletching,        // Crafting bows and arrows. Provides a small bonus to ranged accuracy.
  Alchemy,          // Crafting potions. Provides a small bonus to healing effectiveness.
  Inscription,      // Crafting scrolls and magic tools. Provides a small bonus to magic accuracy.
}

/// A list of skills that are considered "non-combat" or utility skills.
const List<Skill> nonCombatSkills = [
  Skill.Lumberjacking,
  Skill.Mining,
  Skill.Herbalism,
  Skill.Blacksmithing,
  Skill.Fletching,
  Skill.Alchemy,
  Skill.Inscription,
  Skill.DetectingHidden,
  Skill.Healing,
];

/// A list of skills that monsters typically WON'T have. Used by the factory.
const List<Skill> utilitySkillsForPlayerOnly = [
  Skill.Lumberjacking,
  Skill.Mining,
  Skill.Herbalism,
  Skill.Blacksmithing,
  Skill.Fletching,
  Skill.Alchemy,
  Skill.Inscription,
];


/// A utility class for skill-related calculations.
class SkillUtils {
  /// Calculates the "real" value of a skill based on its base value.
  /// The value gains bonus points at specific thresholds.
  static double getRealSkillValue(int baseValue) {
    if (baseValue <= 0) return 0;
    double realValue = baseValue.toDouble();
    if (baseValue >= 34) realValue += 1;
    if (baseValue >= 67) realValue += 2;
    if (baseValue >= 100) realValue += 5;
    if (baseValue >= 105) realValue += 1;
    if (baseValue >= 110) realValue += 2;
    if (baseValue >= 115) realValue += 3;
    if (baseValue >= 120) realValue += 5;
    return realValue;
  }
}
