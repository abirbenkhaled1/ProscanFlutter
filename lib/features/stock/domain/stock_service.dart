import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/data/repository/stock_repository.dart';

class StockService {
  final StockRepository _repository;

  StockService(this._repository);

  Future<void> addProduct(Product product) async {
    if (product.barcode.isEmpty) throw Exception('Barcode cannot be empty');
    if (product.name.isEmpty) throw Exception('Product name cannot be empty');
    if (product.quantity <= 0) throw Exception('Quantity must be positive');
    if (!['entry', 'exit'].contains(product.type)) throw Exception('Invalid product type');
    await _repository.insertProduct(product);
  }

  Future<List<Product>> getEntries() => _repository.getProductsByType('entry');
  Future<List<Product>> getExits() => _repository.getProductsByType('exit');
  Future<List<Product>> getAllStock() => _repository.getAllProducts();
  Future<void> deleteProduct(int id) => _repository.deleteProduct(id);
}