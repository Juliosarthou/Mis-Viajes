import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';

class BackupService {
  static final List<String> _diasSemana = [
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'
  ];

  static Future<void> checkAndCreateDailyBackup() async {
    try {
      final now = DateTime.now();
      final diaNombre = _diasSemana[now.weekday - 1];
      final diaCapitalizado = diaNombre[0].toUpperCase() + diaNombre.substring(1);
      
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docDir.path, 'viajes.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return;

      // El backup automático diario se guarda en INTERNAL STORAGE para seguridad, 
      // invisible para el usuario (No requiere permisos especiales)
      final backupDir = Directory(join(docDir.path, 'backups_internos'));
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final sqlFileName = 'Mis Viajes $diaCapitalizado.sql';
      final sqlPath = join(backupDir.path, sqlFileName);
      final sqlFile = File(sqlPath);

      // Verificar si ya se hizo el backup de HOY
      if (await sqlFile.exists()) {
        final lastModified = await sqlFile.lastModified();
        final hoyStr = "${now.year}-${now.month}-${now.day}";
        final backupStr = "${lastModified.year}-${lastModified.month}-${lastModified.day}";
        
        if (hoyStr == backupStr) {
          print("DEBUG BACKUP: El backup automático diario ya existe.");
          return;
        }
      }

      await _exportToSqlInternal(backupDir.path, diaCapitalizado);
      print("DEBUG BACKUP: Backup diario guardado internamente en: ${backupDir.path}");
    } catch (e) {
      print("ERROR BACKUP AUTOMÁTICO: $e");
    }
  }

  static Future<String> createManualBackup() async {
    try {
      final now = DateTime.now();
      final fechaHora = DateFormat('yyyyMMdd_HHmmss').format(now);
      
      // Obtenemos el dump SQL
      final sqlDump = await DatabaseService().generateFullSqlDump();
      
      // Guardamos en un archivo TEMPORAL para poder compartirlo
      final tempDir = await getTemporaryDirectory();
      final sqlFileName = 'Backup_Mis_Viajes_$fechaHora.sql';
      final sqlPath = join(tempDir.path, sqlFileName);
      final file = File(sqlPath);
      await file.writeAsString(sqlDump);

      // Compartir el archivo (esto abre el menú nativo de Compartir)
      // El usuario puede Guardar en Archivos, mandar por WhatsApp, Email, etc.
      await Share.shareXFiles(
        [XFile(sqlPath)],
        subject: 'Backup Mis Viajes $fechaHora',
        text: 'Backup de mi base de datos de viajes generada desde la app Mis Viajes.',
      );

      return "Exportación preparada. Utiliza el menú para guardar el archivo.";
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<String> importSqlFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return "El archivo no existe";

      final sql = await file.readAsString();
      final db = await DatabaseService().database;
      
      final lines = sql.split('\n');
      String currentStatement = "";
      
      await db.transaction((txn) async {
        for (var line in lines) {
          String cleanLine = line.trim();
          if (cleanLine.isEmpty || cleanLine.startsWith('--')) continue;
          
          currentStatement += " $cleanLine";
          if (cleanLine.endsWith(';')) {
            await txn.execute(currentStatement);
            currentStatement = "";
          }
        }
      });

      return "Importación completada con éxito. Los datos han sido actualizados.";
    } catch (e) {
      return "Error al importar: $e";
    }
  }

  static Future<void> _exportToSqlInternal(String targetPath, String dia) async {
    final sqlDump = await DatabaseService().generateFullSqlDump();
    final sqlPath = join(targetPath, 'Mis Viajes $dia.sql');
    final file = File(sqlPath);
    await file.writeAsString(sqlDump);
  }
}
