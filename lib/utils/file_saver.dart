import 'dart:io';
// Per usare path_provider in un progetto Flutter completo, aggiungi
// al tuo file pubspec.yaml:
// dependencies:
//   path_provider: ^2.0.0
// import 'package:path_provider/path_provider.dart';

class FileSaver {
  static Future<bool> save(String content, String fileName) async {
    // Questa implementazione funziona solo su piattaforme desktop (es. Linux).
    // Su Web e mobile, sono necessarie implementazioni diverse.
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      print("File saving is only implemented for desktop platforms in this example.");
      print("--- REPORT CONTENT ---");
      print(content);
      return false;
    }

    try {
      // Usando path_provider (modo raccomandato)
      // final directory = await getApplicationDocumentsDirectory();
      // final path = directory.path;

      // Metodo alternativo semplice per test su Linux
      final homeDir = Platform.environment['HOME'];
      if(homeDir == null) {
        print("Cannot find HOME directory.");
        return false;
      }
      final path = '$homeDir/Documents'; // Salva nella cartella Documenti
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('$path/$fileName');
      await file.writeAsString(content);
      print("File saved to ${file.path}");
      return true;
    } catch (e) {
      print("An error occurred while saving the file: $e");
      return false;
    }
  }
}
