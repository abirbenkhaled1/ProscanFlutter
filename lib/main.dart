import 'package:flutter/material.dart';
import 'package:flutter_pro_scan/features/stock/data/repository/stock_repository.dart';
import 'package:flutter_pro_scan/features/stock/domain/stock_service.dart';
import 'package:flutter_pro_scan/features/stock/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StockRepository.instance.database;
  runApp(const FlutterProScanApp());
}

class FlutterProScanApp extends StatelessWidget {
  const FlutterProScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pro Scan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(stockService: StockService(StockRepository.instance)),
    );
  }
}
