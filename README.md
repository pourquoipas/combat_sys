/// Questo file contiene il testo del README come stringa Dart multi-linea.
/// Puoi copiare il contenuto della variabile 'readmeContent' per ottenere
/// il testo sorgente Markdown non formattato.

const String readmeContent = r'''
# Combat System - Documentazione (v2.0)

Questo documento descrive l'architettura e il funzionamento del sistema di combattimento v2.0, riprogettato per un migliore bilanciamento e una maggiore rilevanza di tutte le skill.

## 1. Filosofia di Design (v2.0)

La versione precedente rischiava di creare "skill spazzatura". Questa versione si basa su un principio fondamentale: **ogni punto skill investito deve avere un'utilità, anche se minima, in ogni aspetto del gioco**. Un personaggio specializzato nel `Mining` non sarà un guerriero provetto, ma la sua robustezza e conoscenza dei metalli gli conferirà un bonus passivo alla difesa fisica, rendendo i suoi punti skill mai sprecati. Questo incoraggia build ibride e rende le scelte del giocatore più significative a lungo termine.

## 2. Struttura del Progetto

*(Invariata)*

## 3. Concetti Fondamentali (v2.0)

### Skill System Ribilanciato

Le 21 skill sono state riorganizzate per unificare le abilità primarie e dare un ruolo di supporto a quelle di utilità.

* **Skill di Combattimento Primarie**: `MeleeCombat`, `RangedCombat`, `MagicCombat`. Queste sono le fonti principali di punteggio d'attacco nel loro rispettivo campo.
* **Skill di Difesa e Tattica**: `Parrying`, `ResistingSpells`, `Tactics`, `Anatomy`. Skill fondamentali per l'attacco e la difesa, che si combinano con le skill primarie.
* **Skill di Utilità e Supporto**: Tutte le altre skill (crafting, harvesting, ecc.). Forniscono **piccoli ma significativi bonus passivi** al combattimento, oltre alla loro funzione principale nel mondo di gioco.

#### Tabella Sinergie Skill ed Effetti

| Skill | Utilizzo Primario (Fuori Combattimento) | Effetto Secondario in Combattimento |
| :--- | :--- | :--- |
| **MeleeCombat** | - | Aumenta il punteggio d'attacco in mischia |
| **RangedCombat** | - | Aumenta il punteggio d'attacco a distanza |
| **MagicCombat** | - | Aumenta il punteggio d'attacco magico |
| **Parrying** | - | Aumenta il punteggio di difesa contro attacchi fisici |
| **ResistingSpells** | - | Aumenta il punteggio di difesa contro attacchi magici |
| **Tactics** | - | Aumenta il punteggio d'attacco (tutti i tipi) |
| **Anatomy** | - | Aumenta il danno e il punteggio d'attacco/difesa |
| **Strength** | Aumenta HP e carico trasportabile | Aumenta il danno fisico |
| **Dexterity** | - | Aumenta il punteggio d'attacco (fisico) e di difesa (tutti) |
| **Eval. Intelligence** | - | Aumenta il punteggio d'attacco/difesa magico |
| **Healing** | Curare ferite | Aumenta la difesa (stamina, recupero) |
| **SpiritSpeak** | - | Aumenta la difesa magica |
| **DetectingHidden** | Trovare trappole/tesori | (Futuro) Può rivelare nemici invisibili |
| **Luck** | - | Aumenta leggermente tutti i punteggi (att/dif) |
| **Lumberjacking** | Raccogliere legna | Aumenta leggermente il punteggio d'attacco fisico |
| **Mining** | Estrarre minerali | Aumenta leggermente il punteggio di difesa fisica |
| **Herbalism** | Raccogliere erbe | Aumenta leggermente la difesa elementale/veleno |
| **Blacksmithing** | Forgiare equip. | Aumenta leggermente la difesa fisica (conoscenza armature) |
| **Fletching** | Creare archi/frecce| Aumenta leggermente il punteggio d'attacco a distanza |
| **Alchemy** | Creare pozioni | Aumenta leggermente l'efficacia delle cure |
| **Inscription** | Creare pergamene | Aumenta leggermente il punteggio d'attacco magico |

### Logica di Combattimento (v2.0)

Le formule sono state espanse per includere i nuovi contributi.

1.  **Calcolo Punteggio d'Attacco**:
    `Score = (PrimarySkill * 1.0) + (SecondarySkills * ~0.5) + (UtilitySkills * ~0.1) + WeaponBonus`
    -   *Esempio Attacco in Mischia*: Il punteggio è dato principalmente da `MeleeCombat`, potenziato da `Tactics` e `Dexterity`, e riceve bonus minori da `Lumberjacking` e `Luck`.

2.  **Calcolo Punteggio di Difesa**:
    `Score = (PrimaryDefenseSkill * 1.0) + (SecondarySkills * ~0.4) + (UtilitySkills * ~0.15) + ArmorBonus`
    -   *Esempio Difesa da Mischia*: Il punteggio è dato principalmente da `Parrying`, potenziato da `Dexterity` e `Anatomy`, e riceve bonus minori da `Mining` (robustezza) e `Blacksmithing` (conoscenza delle armature).

3.  **Danno e HP**: La logica di base per il calcolo del danno e degli HP rimane simile, ma ora è influenzata indirettamente da un numero maggiore di fattori.

## 4. Implementazioni Future e Considerazioni

### Sistema di Equipaggiamento (Armi e Armature)

Il `CombatSystem` attuale ha dei segnaposto (`weaponBonus`, `armorBonus`) pronti per questa implementazione.
1.  **Creare Classi `Weapon` e `Armor`**: Ogni oggetto dovrebbe avere attributi base (es. `baseDamage`, `baseDefense`) e potrebbe avere bonus a skill specifiche (es. una "Spada della Rapidità" potrebbe dare +5 a `Dexterity`).
2.  **Modificare `Combatant`**: Aggiungere slot per l'equipaggiamento (es. `Weapon equippedWeapon;`, `Armor equippedArmor;`).
3.  **Aggiornare `CombatSystem`**: Rimuovere i segnaposto e leggere i valori direttamente dall'equipaggiamento del combattente durante il calcolo dei punteggi.
    `double weaponBonus = c.equippedWeapon?.bonus ?? 0;`

### Ruolo delle Attività di Crafting e Harvesting

Il loro scopo primario è produrre oggetti consumabili o equipaggiabili, creando un'economia di gioco.
* **Alchemy/Herbalism**: Creazione di pozioni (cura, buff temporanei a `Strength`, antidoti). Il sistema di combattimento potrebbe essere esteso con un concetto di "buff attivi" su un `Combatant`.
* **Inscription**: Creazione di pergamene magiche che permettono a chiunque di lanciare un incantesimo (una tantum), o di potenziamenti permanenti per l'equipaggiamento.
* **DetectingHidden**: Essenziale per l'esplorazione. Potrebbe essere una skill attiva da usare in un dungeon per rivelare passaggi segreti o una skill passiva che dà una chance di notare trappole prima di attivarle, riducendo i danni subiti e quindi i tempi morti per curarsi.

### Considerazioni sul Bilanciamento

* **Specialista vs Ibrido**: Un personaggio con 100 in `MeleeCombat` sarà sempre più forte in mischia di uno con 70 in `MeleeCombat` e 30 in `Mining`. Tuttavia, il secondo potrebbe avere una difesa leggermente superiore e la capacità di raccogliere risorse preziose. La scelta diventa strategica: pura potenza ora, o versatilità e guadagno a lungo termine?
* **Importanza del "Soft Cap"**: Il sistema di valore reale crescente a scaglioni è cruciale. Spingere una skill da 99 a 100 dà un bonus enorme, premiando la specializzazione. Allo stesso modo, portare tante skill a 34 è molto efficiente in termini di punti. Questo crea decisioni interessanti per il giocatore.
  ''';
