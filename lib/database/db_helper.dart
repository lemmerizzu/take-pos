import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('take_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // bumped for new columns
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        sku TEXT NOT NULL,
        barcode TEXT,
        image TEXT,
        weight REAL,
        weightUnit TEXT,
        isBundle INTEGER NOT NULL DEFAULT 0,
        bundleItems TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        customerId TEXT,
        customerName TEXT,
        items TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_logs (
        id TEXT PRIMARY KEY,
        documentNumber TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        reason TEXT NOT NULL,
        reference TEXT,
        supplierId TEXT,
        supplierName TEXT,
        performedBy TEXT,
        notes TEXT,
        items TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new product spec and bundle columns
      try {
        await db.execute('ALTER TABLE products ADD COLUMN weight REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE products ADD COLUMN weightUnit TEXT');
      } catch (_) {}
      try {
        await db
            .execute('ALTER TABLE products ADD COLUMN isBundle INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE products ADD COLUMN bundleItems TEXT');
      } catch (_) {}
    }
  }
}
