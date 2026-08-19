import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../models/sale.dart';

/// Thrown for business-rule failures (not found, insufficient stock, etc.)
/// so the UI can show the same message it would have gotten from the API.
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

/// Everything the app used to ask the ASP.NET Core API for, now backed by
/// an on-device SQLite database. Data lives entirely on the phone under the
/// app's private storage — nothing is sent over the network.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;
  static const _uuid = Uuid();

  Future<Database> get _db async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pharmacy.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines (
            id TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            notes TEXT NOT NULL,
            expiryDate TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            brand TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sales (
            id TEXT PRIMARY KEY,
            medicineId TEXT NOT NULL,
            medicineName TEXT NOT NULL,
            quantitySold INTEGER NOT NULL,
            unitPrice REAL NOT NULL,
            totalAmount REAL NOT NULL,
            saleDate TEXT NOT NULL
          )
        ''');
        await _seedMedicines(db);
      },
    );
  }

  /// Same starter inventory the web/API version shipped with, so the app
  /// isn't empty on first launch.
  Future<void> _seedMedicines(Database db) async {
    final seed = [
      Medicine(
        id: _uuid.v4(),
        fullName: 'Paracetamol 500mg',
        notes: 'Standard pain and fever relief tablet.',
        expiryDate: DateTime(2027, 6, 30),
        quantity: 120,
        price: 25.50,
        brand: 'Calpol',
      ),
      Medicine(
        id: _uuid.v4(),
        fullName: 'Amoxicillin 250mg',
        notes: 'Antibiotic capsule, complete full course.',
        expiryDate: DateTime(2026, 8, 30),
        quantity: 45,
        price: 88.00,
        brand: 'Mox',
      ),
      Medicine(
        id: _uuid.v4(),
        fullName: 'Cetirizine 10mg',
        notes: 'Antihistamine for allergy relief, may cause drowsiness.',
        expiryDate: DateTime(2027, 1, 15),
        quantity: 8,
        price: 15.75,
        brand: 'Zyrtec',
      ),
      Medicine(
        id: _uuid.v4(),
        fullName: 'Ibuprofen 400mg',
        notes: 'NSAID, take with food.',
        expiryDate: DateTime(2026, 8, 25),
        quantity: 5,
        price: 32.00,
        brand: 'Brufen',
      ),
      Medicine(
        id: _uuid.v4(),
        fullName: 'Vitamin C 1000mg',
        notes: 'Effervescent tablets, immune support.',
        expiryDate: DateTime(2028, 3, 1),
        quantity: 60,
        price: 45.00,
        brand: 'Limcee',
      ),
      Medicine(
        id: _uuid.v4(),
        fullName: 'Omeprazole 20mg',
        notes: 'Reduces stomach acid, take before breakfast.',
        expiryDate: DateTime(2026, 9, 10),
        quantity: 30,
        price: 60.20,
        brand: 'Omez',
      ),
    ];

    for (final medicine in seed) {
      await db.insert('medicines', medicine.toMap());
    }
  }

  // ---------- Medicines ----------

  Future<List<Medicine>> getMedicines({String? search}) async {
    final db = await _db;
    List<Map<String, dynamic>> rows;

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      rows = await db.query(
        'medicines',
        where: 'fullName LIKE ? OR brand LIKE ?',
        whereArgs: [term, term],
        orderBy: 'fullName COLLATE NOCASE',
      );
    } else {
      rows = await db.query('medicines', orderBy: 'fullName COLLATE NOCASE');
    }

    return rows.map(Medicine.fromMap).toList();
  }

  Future<Medicine> addMedicine(Medicine draft) async {
    final db = await _db;
    final medicine = Medicine(
      id: _uuid.v4(),
      fullName: draft.fullName,
      notes: draft.notes,
      expiryDate: draft.expiryDate,
      quantity: draft.quantity,
      price: draft.price,
      brand: draft.brand,
    );
    await db.insert('medicines', medicine.toMap());
    return medicine;
  }

  Future<Medicine> updateMedicine(String id, Medicine draft) async {
    final db = await _db;
    final updated = Medicine(
      id: id,
      fullName: draft.fullName,
      notes: draft.notes,
      expiryDate: draft.expiryDate,
      quantity: draft.quantity,
      price: draft.price,
      brand: draft.brand,
    );
    final rows = await db.update('medicines', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    if (rows == 0) {
      throw AppException('Medicine not found.');
    }
    return updated;
  }

  Future<void> deleteMedicine(String id) async {
    final db = await _db;
    final rows = await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    if (rows == 0) {
      throw AppException('Medicine not found.');
    }
  }

  // ---------- Sales ----------

  Future<List<Sale>> getSales() async {
    final db = await _db;
    final rows = await db.query('sales', orderBy: 'saleDate DESC');
    return rows.map(Sale.fromMap).toList();
  }

  /// Deducts stock and records the sale in a single transaction, mirroring
  /// the same rules the API enforced (medicine must exist, stock must be
  /// sufficient) so behaviour matches the web/API version exactly.
  Future<Sale> recordSale({required String medicineId, required int quantitySold}) async {
    final db = await _db;

    return db.transaction<Sale>((txn) async {
      final rows = await txn.query('medicines', where: 'id = ?', whereArgs: [medicineId]);
      if (rows.isEmpty) {
        throw AppException('Medicine not found.');
      }

      final medicine = Medicine.fromMap(rows.first);
      if (medicine.quantity < quantitySold) {
        throw AppException('Only ${medicine.quantity} unit(s) of "${medicine.fullName}" are in stock.');
      }

      await txn.update(
        'medicines',
        {'quantity': medicine.quantity - quantitySold},
        where: 'id = ?',
        whereArgs: [medicineId],
      );

      final sale = Sale(
        id: _uuid.v4(),
        medicineId: medicineId,
        medicineName: medicine.fullName,
        quantitySold: quantitySold,
        unitPrice: medicine.price,
        totalAmount: medicine.price * quantitySold,
        saleDate: DateTime.now(),
      );
      await txn.insert('sales', sale.toMap());

      return sale;
    });
  }
}
