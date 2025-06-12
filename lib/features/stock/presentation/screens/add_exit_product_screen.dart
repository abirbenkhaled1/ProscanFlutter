import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_pro_scan/core/constants/app_constants.dart';
import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/domain/stock_service.dart';

class AddExitProductScreen extends StatefulWidget {
  final StockService stockService;
  final VoidCallback onProductAdded;

  const AddExitProductScreen({
    Key? key,
    required this.stockService,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  AddExitProductScreenState createState() => AddExitProductScreenState();
}

class AddExitProductScreenState extends State<AddExitProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  List<Product> _entryProducts = [];
  Product? _selectedEntryProduct;
  String? _currentBarcode;

  @override
  void initState() {
    super.initState();
    _loadEntryProducts();
  }

  Future<void> _loadEntryProducts() async {
    try {
      final entries = await widget.stockService.getEntries();
      if (mounted) {
        setState(() {
          _entryProducts = entries;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading entries: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode scanning is not supported on web'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    try {
      final result = await BarcodeScanner.scan();
      if (mounted) {
        final scannedBarcode = result.rawContent;
        final matchingEntry = _entryProducts.firstWhere(
          (p) => p.barcode == scannedBarcode,
          orElse: () => Product(id: null, barcode: '', name: '', quantity: 0, type: 'entry'),
        );

        if (matchingEntry.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No entry product found with barcode $scannedBarcode'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        setState(() {
          if (_currentBarcode == null || _currentBarcode == scannedBarcode) {
            // Same barcode: increment quantity
            _barcodeController.text = scannedBarcode;
            _selectedEntryProduct = matchingEntry;
            _currentBarcode = scannedBarcode;
            _quantityController.text = (int.parse(_quantityController.text) + 1).toString();
          } else {
            // New barcode: select new product, reset quantity
            _barcodeController.text = scannedBarcode;
            _selectedEntryProduct = matchingEntry;
            _currentBarcode = scannedBarcode;
            _quantityController.text = '1';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_selectedEntryProduct == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an entry product'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        final product = Product(
          barcode: _barcodeController.text,
          name: _selectedEntryProduct!.name,
          quantity: int.parse(_quantityController.text),
          type: 'exit',
          imageUrl: _selectedEntryProduct!.imageUrl,
        );
        await widget.stockService.addExitProduct(product);
        widget.onProductAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exit product added successfully'),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exit Product'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Product>(
                  value: _selectedEntryProduct,
                  decoration: const InputDecoration(
                    labelText: 'Select Entry Product',
                    prefixIcon: Icon(Icons.list),
                  ),
                  items: _entryProducts
                      .map((product) => DropdownMenuItem(
                            value: product,
                            child: Text('${product.name} (Barcode: ${product.barcode}, Stock: ${product.quantity})'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEntryProduct = value;
                      if (value != null) {
                        _barcodeController.text = value.barcode;
                        _currentBarcode = value.barcode;
                        _quantityController.text = '0';
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Please select a product' : null,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                    suffixIcon: kIsWeb
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppConstants.primaryColor),
                            onPressed: _scanBarcode,
                          ),
                    prefixIcon: const Icon(Icons.barcode_reader),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a barcode' : null,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter quantity';
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) return 'Please enter a valid quantity';
                    if (_selectedEntryProduct != null && qty > _selectedEntryProduct!.quantity) {
                      return 'Quantity exceeds available stock (${_selectedEntryProduct!.quantity})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Exit Product'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}