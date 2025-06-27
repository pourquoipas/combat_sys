/// # Combat System Library
///
/// Questo è il file di entry-point principale per la libreria del sistema di combattimento.
/// Importa questo file per avere accesso a tutti i modelli e le logiche di base.
///
/// Esempio di utilizzo in un altro progetto:
/// `import 'package:nome_del_tuo_progetto/combat_system.dart';`

// Esporta tutti i modelli di dati necessari pubblicamente.
export 'src/models/game_settings.dart';
export 'src/models/skills.dart';
export 'src/models/combatant.dart';

// Esporta tutte le logiche di core necessarie pubblicamente.
export 'src/core/combat_system.dart';
export 'src/core/combatant_factory.dart';
