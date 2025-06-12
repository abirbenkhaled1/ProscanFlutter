import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class StockRepository {
  static final StockRepository instance = StockRepository._init();
  static Database? _database;
  final List<Product> _webProducts = []; // In-memory storage for web

  StockRepository._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database operations are not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('stock.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT NOT NULL,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      type TEXT NOT NULL,
      imageUrl TEXT
    )
    ''');
  }

  Future<void> insertProduct(Product product) async {
    if (kIsWeb) {
      // Simulate auto-increment ID
      final newId = _webProducts.isEmpty ? 1 : _webProducts.last.id! + 1;
      final existing = _webProducts.firstWhere(
        (p) => p.barcode == product.barcode && p.type == product.type,
        orElse: () => Product(id: -1, barcode: '', name: '', quantity: 0, type: ''),
      );

      if (existing.id != -1) {
        final newQuantity = existing.quantity + product.quantity;
        final updatedProduct = Product(
          id: existing.id,
          barcode: existing.barcode,
          name: existing.name,
          quantity: newQuantity,
          type: existing.type,
          imageUrl: product.imageUrl ?? existing.imageUrl,
        );
        _webProducts[_webProducts.indexOf(existing)] = updatedProduct;
      } else {
        _webProducts.add(Product(
          id: newId,
          barcode: product.barcode,
          name: product.name,
          quantity: product.quantity,
          type: product.type,
          imageUrl: product.imageUrl,
        ));
      }
      return;
    }
    final db = await database;
    final existing = await db.query(
      'products',
      where: 'barcode = ? AND type = ?',
      whereArgs: [product.barcode, product.type],
    );

    if (existing.isNotEmpty) {
      final existingProduct = Product.fromMap(existing.first);
      final newQuantity = existingProduct.quantity + product.quantity;
      await db.update(
        'products',
        {'quantity': newQuantity, 'imageUrl': product.imageUrl ?? existingProduct.imageUrl},
        where: 'id = ?',
        whereArgs: [existingProduct.id],
      );
    } else {
      await db.insert('products', product.toMap());
    }
  }

  Future<void> updateProduct(Product product) async {
    if (kIsWeb) {
      final index = _webProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _webProducts[index] = product;
      }
      return;
    }
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> getProductsByType(String type) async {
    if (kIsWeb) {
      return _webProducts.where((p) => p.type == type).toList();
    }
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'type = ?',
      whereArgs: [type],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode, String type) async {
    if (kIsWeb) {
      try {
        return _webProducts.firstWhere((p) => p.barcode == barcode && p.type == type);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND type = ?',
      whereArgs: [barcode, type],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    if (kIsWeb) {
      return _webProducts;
    }
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> deleteProduct(int id) async {
    if (kIsWeb) {
      _webProducts.removeWhere((p) => p.id == id);
      return;
    }
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
  }
}