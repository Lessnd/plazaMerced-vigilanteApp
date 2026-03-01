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
      version: 4, // Incrementamos a 4
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverId TEXT UNIQUE NOT NULL,               -- Nuevo: UUID para el servidor
        placa TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        entrada TEXT NOT NULL,
        salida TEXT,
        costo REAL,
        tarifaAplicada REAL NOT NULL,                 -- Nuevo: tarifa de entrada
        generacionId TEXT,                             -- Nuevo: para tracking
        sincronizado INTEGER NOT NULL DEFAULT 0 CHECK (sincronizado IN (0, 1, 2)),
        es_tiempo_manipulado INTEGER NOT NULL DEFAULT 0 CHECK (es_tiempo_manipulado IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE Banos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifaCobrada REAL NOT NULL,
        fechaUso TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0 CHECK (sincronizado IN (0, 1, 2))
      )
    ''');

    await db.execute('''
      CREATE TABLE Configuracion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifaParqueoHora REAL NOT NULL,
        tarifaBano REAL NOT NULL,
        ultimaActualizacion TEXT NOT NULL,
        timeOffset INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_tickets_placa ON Tickets(placa);');
    await db.execute(
      'CREATE INDEX idx_tickets_sincronizado ON Tickets(sincronizado);',
    );
    await db.execute(
      'CREATE INDEX idx_banos_sincronizado ON Banos(sincronizado);',
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migración a versión 2 (anterior)
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE Tickets ADD COLUMN es_tiempo_manipulado INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE Configuracion ADD COLUMN timeOffset INTEGER NOT NULL DEFAULT 0;',
      );
    }
    // Migración a versión 3 (si hubiera, no aplica)
    // Migración a versión 4: nuevas columnas en Tickets
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE Tickets ADD COLUMN serverId TEXT;');
      await db.execute('ALTER TABLE Tickets ADD COLUMN tarifaAplicada REAL;');
      await db.execute('ALTER TABLE Tickets ADD COLUMN generacionId TEXT;');
      // Actualizar los registros existentes: asignar un UUID a serverId y tarifa por defecto
      await db.execute(
        "UPDATE Tickets SET serverId = hex(randomblob(16)) WHERE serverId IS NULL;",
      );
      await db.execute(
        "UPDATE Tickets SET tarifaAplicada = 1.0 WHERE tarifaAplicada IS NULL;", // valor por defecto
      );
      // Hacer serverId NOT NULL después de actualizar
      await db.execute(
        "CREATE TABLE Tickets_new AS SELECT id, serverId, placa, deviceId, entrada, salida, costo, tarifaAplicada, generacionId, sincronizado, es_tiempo_manipulado FROM Tickets;",
      );
      await db.execute("DROP TABLE Tickets;");
      await db.execute("ALTER TABLE Tickets_new RENAME TO Tickets;");
      // Recrear índices
      await db.execute('CREATE INDEX idx_tickets_placa ON Tickets(placa);');
      await db.execute(
        'CREATE INDEX idx_tickets_sincronizado ON Tickets(sincronizado);',
      );
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}