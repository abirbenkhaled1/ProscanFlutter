import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_pro_scan/core/constants/app_constants.dart';
import 'package:flutter_pro_scan/features/stock/data/models/product.dart';
import 'package:flutter_pro_scan/features/stock/domain/stock_service.dart';
import 'package:flutter_pro_scan/features/stock/presentation/screens/home_screen.dart';
import 'package:flutter_pro_scan/main.dart';
import 'mocks.mocks.dart';

void main() {
  late MockStockRepository mockStockRepository;
  late StockService stockService;

  setUp(() {
    mockStockRepository = MockStockRepository();
    stockService = StockService(mockStockRepository);
  });

  testWidgets('Flutter Pro Scan app renders correctly', (WidgetTester tester) async {
    when(mockStockRepository.getProductsByType('entry')).thenAnswer((_) async => []);
    when(mockStockRepository.getProductsByType('exit')).thenAnswer((_) async => []);
    when(mockStockRepository.getAllProducts()).thenAnswer((_) async => []);

    await tester.pumpWidget(const FlutterProScanApp());

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('Exits'), findsOneWidget);
    expect(find.text('All Stock'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('No products found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HomeScreen shows loading indicator while fetching products', (WidgetTester tester) async {
    when(mockStockRepository.getProductsByType('entry')).thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => []));

    await tester.pumpWidget(
       MaterialApp(
        theme: ThemeData.light(),
        home: HomeScreen(stockService: stockService),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No products found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HomeScreen displays products when available', (WidgetTester tester) async {
    final sampleProduct = Product(
      id: 1,
      barcode: '123456',
      name: 'Test Product',
      quantity: 10,
      type: 'entry',
      imageUrl: null,
    );
    when(mockStockRepository.getProductsByType('entry')).thenAnswer((_) async => [sampleProduct]);
    when(mockStockRepository.getProductsByType('exit')).thenAnswer((_) async => []);
    when(mockStockRepository.getAllProducts()).thenAnswer((_) async => [sampleProduct]);

    await tester.pumpWidget(
       MaterialApp(
        theme: ThemeData.light(),
        home: HomeScreen(stockService: stockService),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('Barcode: 123456'), findsOneWidget);
    expect(find.text('Quantity: 10'), findsOneWidget);
    expect(find.text('Type: Entry'), findsOneWidget);
  });

  testWidgets('FAB navigates to AddProductScreen', (WidgetTester tester) async {
    when(mockStockRepository.getProductsByType('entry')).thenAnswer((_) async => []);
    when(mockStockRepository.getProductsByType('exit')).thenAnswer((_) async => []);
    when(mockStockRepository.getAllProducts()).thenAnswer((_) async => []);

    await tester.pumpWidget(const FlutterProScanApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byType(DropdownButtonFormField), findsOneWidget);
  });
}