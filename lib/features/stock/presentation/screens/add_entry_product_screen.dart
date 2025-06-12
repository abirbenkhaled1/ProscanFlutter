import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_pro_scan/core/constants/app_constants.dart';
import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/domain/stock_service.dart';

class AddEntryProductScreen extends StatefulWidget {
  final StockService stockService;
  final VoidCallback onProductAdded;

  const AddEntryProductScreen({
    Key? key,
    required this.stockService,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  AddEntryProductScreenState createState() => AddEntryProductScreenState();
}

class AddEntryProductScreenState extends State<AddEntryProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _imageUrlController = TextEditingController();

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
        setState(() {
          _barcodeController.text = result.rawContent;
          _quantityController.text = (int.parse(_quantityController.text) + 1).toString();
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
        final product = Product(
          barcode: _barcodeController.text,
          name: _nameController.text,
          quantity: int.parse(_quantityController.text),
          type: 'entry',
          imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        );
        await widget.stockService.addEntryProduct(product);
        widget.onProductAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry product added successfully'),
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
        title: const Text('Add Entry Product'),
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter product name' : null,
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
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (!Uri.parse(value).isAbsolute) return 'Please enter a valid URL';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Entry Product'),
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
    _nameController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}