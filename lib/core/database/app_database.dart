import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vigilante_sunmi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final path = join(dbFolder.path, filePath);

    return await openDatabase(
      path,
      version: 2, // <-- IMPORTANTE: Subimos la versión a 2
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // <-- Agregamos el manejador de migraciones
    );
  }

  // Se ejecuta SOLO la primera vez que se instala la app
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placa TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        entrada TEXT NOT NULL,
        salida TEXT,
        costo REAL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        es_tiempo_manipulado INTEGER NOT NULL DEFAULT 0 -- 0 es falso, 1 es verdadero
      )
    ''');

    await db.execute('''
      CREATE TABLE Banos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifaCobrada REAL NOT NULL,
        fechaUso TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE Configuracion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifaParqueoHora REAL NOT NULL,
        tarifaBano REAL NOT NULL,
        ultimaActualizacion TEXT NOT NULL,
        timeOffset INTEGER NOT NULL DEFAULT 0 -- Guardamos la diferencia en milisegundos
      )
    ''');
  }

  // Se ejecuta SI el usuario actualiza la app de version 1 a version 2
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Modificamos las tablas existentes sin perder los datos
      await db.execute('ALTER TABLE Tickets ADD COLUMN es_tiempo_manipulado INTEGER NOT NULL DEFAULT 0;');
      await db.execute('ALTER TABLE Configuracion ADD COLUMN timeOffset INTEGER NOT NULL DEFAULT 0;');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}