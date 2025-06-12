import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/data/repository/stock_repository.dart';

class StockService {
  final StockRepository _repository;

  StockService(this._repository);

  Future<void> addEntryProduct(Product product) async {
    if (product.barcode.isEmpty) throw Exception('Barcode cannot be empty');
    if (product.name.isEmpty) throw Exception('Product name cannot be empty');
    if (product.quantity <= 0) throw Exception('Quantity must be positive');
    if (product.type != 'entry') throw Exception('Invalid product type for entry');
    await _repository.insertProduct(product);
  }

  Future<void> addExitProduct(Product product) async {
    if (product.barcode.isEmpty) throw Exception('Barcode cannot be empty');
    if (product.name.isEmpty) throw Exception('Product name cannot be empty');
    if (product.quantity <= 0) throw Exception('Quantity must be positive');
    if (product.type != 'exit') throw Exception('Invalid product type for exit');

    // Find matching entry product
    final entryProducts = await _repository.getProductsByType('entry');
    final matchingEntry = entryProducts.firstWhere(
      (p) => p.barcode == product.barcode,
      orElse: () => Product(id: null, barcode: '', name: '', quantity: 0, type: 'entry'),
    );

    if (matchingEntry.id == null) {
      throw Exception('No entry product found with barcode ${product.barcode}');
    }

    if (matchingEntry.quantity < product.quantity) {
      throw Exception('Exit quantity (${product.quantity}) exceeds available stock (${matchingEntry.quantity})');
    }

    // Update entry product quantity
    final updatedEntry = Product(
      id: matchingEntry.id,
      barcode: matchingEntry.barcode,
      name: matchingEntry.name,
      quantity: matchingEntry.quantity - product.quantity,
      type: matchingEntry.type,
      imageUrl: matchingEntry.imageUrl,
    );

    if (updatedEntry.quantity == 0) {
      await _repository.deleteProduct(matchingEntry.id!);
    } else {
      await _repository.updateProduct(updatedEntry);
    }

    // Insert or update exit product
    await _repository.insertProduct(product);
  }

  Future<List<Product>> getEntries() => _repository.getProductsByType('entry');
  Future<List<Product>> getExits() => _repository.getProductsByType('exit');
  Future<List<Product>> getAllStock() => _repository.getAllProducts();
  Future<void> deleteProduct(int id) => _repository.deleteProduct(id);
}