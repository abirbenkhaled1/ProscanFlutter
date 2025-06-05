import 'package:flutter/material.dart';
import 'package:flutter_pro_scan/core/constants/app_constants.dart';
import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/domain/stock_service.dart';
import 'package:flutter_pro_scan/features/stock/presentation/screens/add_product_screen.dart';
import 'package:flutter_pro_scan/features/stock/presentation/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final StockService stockService;
  const HomeScreen({Key? key, required this.stockService}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Entries'),
              Tab(text: 'Exits'),
              Tab(text: 'All Stock'),
            ],
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: AppConstants.accentColor.withAlpha(77),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductList(widget.stockService.getEntries),
            _buildProductList(widget.stockService.getExits),
            _buildProductList(widget.stockService.getAllStock),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddProduct(context),
          tooltip: 'Add Product',
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildProductList(Future<List<Product>> Function() fetchProducts) {
    return FutureBuilder<List<Product>>(
      future: fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading products: ${snapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        final products = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: ProductCard(
                  product: product,
                  onDelete: () async {
                    await widget.stockService.deleteProduct(product.id!);
                    setState(() {});
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          stockService: widget.stockService,
          onProductAdded: () => setState(() {}),
        ),
      ),
    );
  }
}
