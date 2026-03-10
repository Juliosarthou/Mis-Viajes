import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "viajes.db");
    
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabla Destinos
    await db.execute('''
      CREATE TABLE destinos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        detalle TEXT,
        fecha_desde TEXT NOT NULL,
        fecha_hasta TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla Rubros
    await db.execute('''
      CREATE TABLE rubros_viajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        icono TEXT DEFAULT 'fas fa-tag',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla Gastos
    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destino_id INTEGER NOT NULL,
        rubro_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        moneda TEXT DEFAULT 'ARS',
        detalle TEXT,
        fecha TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (destino_id) REFERENCES destinos (id) ON DELETE CASCADE,
        FOREIGN KEY (rubro_id) REFERENCES rubros_viajes (id)
      )
    ''');

    // Tabla Itinerarios
    await db.execute('''
      CREATE TABLE itinerarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destino_id INTEGER NOT NULL,
        dia_numero INTEGER NOT NULL,
        detalle TEXT,
        fecha_especifica TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (destino_id) REFERENCES destinos (id) ON DELETE CASCADE
      )
    ''');

    // Base de datos creada. Sin datos iniciales por defecto.
  }

  // Métodos de consulta
  Future<List<Map<String, dynamic>>> getProximosItinerarios() async {
    final db = await database;
    String hoy = DateTime.now().toIso8601String().split('T')[0];
    
    // 1. Encontrar el próximo destino activo
    final List<Map<String, dynamic>> nextDestino = await db.query(
      'destinos',
      where: 'fecha_hasta >= ?',
      whereArgs: [hoy],
      orderBy: 'fecha_desde ASC',
      limit: 1,
    );

    if (nextDestino.isEmpty) return [];

    int destinoId = nextDestino.first['id'];

    // 2. Traer solo los itinerarios de ESE destino específico
    return await db.rawQuery('''
      SELECT i.*, d.fecha_desde, d.nombre as destino_nombre
      FROM itinerarios i
      JOIN destinos d ON i.destino_id = d.id
      WHERE d.id = ?
      ORDER BY i.dia_numero ASC
    ''', [destinoId]);
  }

  Future<Map<String, dynamic>?> getDestinoById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'destinos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> getNextDestino() async {
    final db = await database;
    String hoy = DateTime.now().toIso8601String().split('T')[0];
    
    // Buscamos el próximo destino cuya fecha_hasta no haya pasado
    List<Map<String, dynamic>> maps = await db.query(
      'destinos',
      where: 'fecha_hasta >= ?',
      whereArgs: [hoy],
      orderBy: 'fecha_desde ASC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getHistorialViajes() async {
    final db = await database;
    String hoy = DateTime.now().toIso8601String().split('T')[0];
    
    // Obtenemos destinos cuya fecha_hasta sea estrictamente menor a hoy
    return await db.query(
      'destinos',
      where: 'fecha_hasta < ?',
      whereArgs: [hoy],
      orderBy: 'fecha_desde DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getProximosDestinos() async {
    final db = await database;
    String hoy = DateTime.now().toIso8601String().split('T')[0];
    
    // Obtenemos destinos cuya fecha_hasta sea hoy o futura
    return await db.query(
      'destinos',
      where: 'fecha_hasta >= ?',
      whereArgs: [hoy],
      orderBy: 'fecha_desde ASC',
    );
  }

  Future<int> insertDestino(Map<String, dynamic> destino) async {
    final db = await database;
    return await db.insert('destinos', destino);
  }

  Future<bool> hasRelationedData(int destinoId) async {
    final db = await database;
    
    // Si hay gastos, no se puede eliminar
    final gastos = await db.query(
      'gastos',
      where: 'destino_id = ?',
      whereArgs: [destinoId],
      limit: 1,
    );
    if (gastos.isNotEmpty) return true;
    
    // Si hay itinerarios con texto (detalle no vacío), no se puede eliminar
    final itinerarios = await db.query(
      'itinerarios',
      where: 'destino_id = ? AND detalle IS NOT NULL AND detalle != ""',
      whereArgs: [destinoId],
      limit: 1,
    );
    
    return itinerarios.isNotEmpty;
  }

  Future<int> deleteDestino(int id) async {
    final db = await database;
    return await db.delete(
      'destinos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getItinerariosByDestino(int destinoId) async {
    final db = await database;
    return await db.query(
      'itinerarios',
      where: 'destino_id = ?',
      whereArgs: [destinoId],
      orderBy: 'dia_numero ASC',
    );
  }

  Future<int> insertItinerario(Map<String, dynamic> itinerario) async {
    final db = await database;
    return await db.insert('itinerarios', itinerario);
  }

  Future<int> updateItinerario(Map<String, dynamic> itinerario) async {
    final db = await database;
    return await db.update(
      'itinerarios',
      itinerario,
      where: 'id = ?',
      whereArgs: [itinerario['id']],
    );
  }

  Future<int> deleteItinerariosByDestino(int destinoId) async {
    final db = await database;
    return await db.delete(
      'itinerarios',
      where: 'destino_id = ?',
      whereArgs: [destinoId],
    );
  }

  Future<void> syncItinerarios(int destinoId, String fechaDesde, String fechaHasta) async {
    final db = await database;
    final DateTime start = DateTime.parse(fechaDesde);
    final DateTime end = DateTime.parse(fechaHasta);
    final int totalDias = end.difference(start).inDays + 1;

    // 1. Eliminar cualquier registro con dia_numero superior al total de días permitidos
    await db.delete(
      'itinerarios',
      where: 'destino_id = ? AND dia_numero > ?',
      whereArgs: [destinoId, totalDias],
    );

    // 2. Asegurar que existe exactamente UN registro por cada día del itinerario
    for (int i = 1; i <= totalDias; i++) {
      final List<Map<String, dynamic>> existentes = await db.query(
        'itinerarios',
        where: 'destino_id = ? AND dia_numero = ?',
        whereArgs: [destinoId, i],
      );

      if (existentes.isEmpty) {
        // Si no existe el día, lo creamos vacío
        await db.insert('itinerarios', {
          'destino_id': destinoId,
          'dia_numero': i,
          'detalle': '',
        });
      } else if (existentes.length > 1) {
        // Si por error hay duplicados por día, borramos los extras y dejamos solo uno
        final idPrimero = existentes.first['id'];
        await db.delete(
          'itinerarios',
          where: 'destino_id = ? AND dia_numero = ? AND id != ?',
          whereArgs: [destinoId, i, idPrimero],
        );
      }
    }
  }

  Future<int> updateDestino(Map<String, dynamic> destino) async {
    final db = await database;
    return await db.update(
      'destinos',
      destino,
      where: 'id = ?',
      whereArgs: [destino['id']],
    );
  }

  Future<Map<String, dynamic>?> checkOverlap(String desde, String hasta, {int? excludeId}) async {
    final db = await database;
    
    // Simplificamos la consulta para ser extremadamente claros
    String query = 'SELECT id, nombre, fecha_desde, fecha_hasta FROM destinos WHERE NOT (fecha_hasta < ? OR fecha_desde > ?)';
    List<dynamic> args = [desde, hasta];
    
    if (excludeId != null) {
      query += ' AND id != ?';
      args.add(excludeId);
    }
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    if (results.isNotEmpty) {
      print("DEBUG: Superposición detectada con viaje ID: ${results.first['id']} nombre: ${results.first['nombre']}");
      return results.first;
    }
    return null;
  }

  Future<void> debugLogDestinos() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('destinos');
    print("--- DEBUG: CONTENIDO TABLA DESTINOS ---");
    for (var row in results) {
      print("ID: ${row['id']}, Nombre: ${row['nombre']}, Desde: ${row['fecha_desde']}, Hasta: ${row['fecha_hasta']}");
    }
    print("---------------------------------------");
  }

  // --- Métodos de Rubros ---
  Future<List<Map<String, dynamic>>> getRubros() async {
    final db = await database;
    return await db.query('rubros_viajes', orderBy: 'nombre ASC');
  }

  Future<int> insertRubro(Map<String, dynamic> rubro) async {
    final db = await database;
    return await db.insert('rubros_viajes', rubro);
  }

  Future<int> updateRubro(Map<String, dynamic> rubro) async {
    final db = await database;
    return await db.update(
      'rubros_viajes',
      rubro,
      where: 'id = ?',
      whereArgs: [rubro['id']],
    );
  }

  Future<bool> hasRubroExpenses(int rubroId) async {
    final db = await database;
    final results = await db.query(
      'gastos',
      where: 'rubro_id = ?',
      whereArgs: [rubroId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<int> deleteRubro(int id) async {
    final db = await database;
    return await db.delete(
      'rubros_viajes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Métodos de Gastos ---
  Future<List<Map<String, dynamic>>> getGastosByDestino(int destinoId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT g.*, r.nombre as rubro_nombre, r.icono as rubro_icono
      FROM gastos g
      JOIN rubros_viajes r ON g.rubro_id = r.id
      WHERE g.destino_id = ?
      ORDER BY g.fecha DESC, g.id DESC
    ''', [destinoId]);
  }

  Future<int> insertGasto(Map<String, dynamic> gasto) async {
    final db = await database;
    return await db.insert('gastos', gasto);
  }

  Future<int> updateGasto(Map<String, dynamic> gasto) async {
    final db = await database;
    return await db.update(
      'gastos',
      gasto,
      where: 'id = ?',
      whereArgs: [gasto['id']],
    );
  }

  Future<int> deleteGasto(int id) async {
    final db = await database;
    return await db.delete(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTodosLosGastos() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT g.fecha, g.monto, g.detalle, r.nombre as categoria, d.nombre as viaje
      FROM gastos g
      JOIN rubros_viajes r ON g.rubro_id = r.id
      JOIN destinos d ON g.destino_id = d.id
      ORDER BY g.fecha DESC
    ''');
  }

  Future<String> generateFullSqlDump() async {
    final db = await database;
    StringBuffer dump = StringBuffer();
    dump.writeln("-- Backup Completo SQL 'Mis Viajes'");
    dump.writeln("-- Generado el: ${DateTime.now().toIso8601String()}");
    dump.writeln("PRAGMA foreign_keys=OFF;");
    dump.writeln("BEGIN TRANSACTION;");

    // 1. Obtener nombres de todas las tablas de usuario
    final List<Map<String, dynamic>> tablesData = await db.rawQuery(
      "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'"
    );

    for (var tableInfo in tablesData) {
      final tableName = tableInfo['name'];
      final createSql = tableInfo['sql'];

      dump.writeln("\n-- ---------------------------------------------------------");
      dump.writeln("-- Estructura y Datos para la tabla: $tableName");
      dump.writeln("-- ---------------------------------------------------------");
      
      // Añadir sentencia de creación (siempre presente esté vacía o no la tabla)
      dump.writeln("DROP TABLE IF EXISTS $tableName;");
      dump.writeln("$createSql;");

      // Añadir datos (INSERTs)
      final data = await db.query(tableName);
      if (data.isNotEmpty) {
        for (var row in data) {
          final columns = row.keys.join(', ');
          final values = row.values.map((v) {
            if (v == null) return 'NULL';
            if (v is String) return "'${v.replaceAll("'", "''")}'";
            return v.toString();
          }).join(', ');
          dump.writeln("INSERT INTO $tableName ($columns) VALUES ($values);");
        }
      } else {
        dump.writeln("-- (Tabla sin registros)");
      }
    }

    dump.writeln("\nCOMMIT;");
    dump.writeln("PRAGMA foreign_keys=ON;");
    return dump.toString();
  }
}
